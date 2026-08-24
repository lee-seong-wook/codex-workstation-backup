[CmdletBinding()]
param(
    [ValidateSet("auto", "routine", "review", "deep", "critical")]
    [string]$Mode = "auto",

    [string]$Prompt,
    [string]$PromptFile,
    [string[]]$ChangedFiles = @(),
    [ValidateRange(0, 100)]
    [int]$FailureCount = 0,
    [switch]$IncludeFinalTieBreaker,
    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

function Get-Payload {
    if ($PromptFile) {
        return Get-Content -LiteralPath $PromptFile -Raw -Encoding UTF8
    }

    if ($Prompt) {
        return $Prompt
    }

    $pipelineText = @($input) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($pipelineText)) {
        return [Console]::In.ReadToEnd()
    }

    return $pipelineText
}

function Add-RiskSignal {
    param(
        [System.Collections.Generic.List[object]]$Signals,

        [Parameter(Mandatory = $true)]
        [ref]$Score,

        [Parameter(Mandatory = $true)]
        [int]$Weight,

        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    $Score.Value += $Weight
    $Signals.Add([pscustomobject]@{
        Weight = $Weight
        Reason = $Reason
    })
}

function Get-AutoRoute {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [string[]]$Files,
        [int]$Failures
    )

    $score = 0
    $signals = New-Object System.Collections.Generic.List[object]
    $scoreRef = [ref]$score

    $highRiskPattern = "(?i)(\barchitecture\b|\barchitectural\b|\bsecurity\b|\bauth\b|\bauthentication\b|\bauthorization\b|\bmigration\b|\bschema\b|\bdeploy\b|\brelease\b|\bdata loss\b|\bcritical debugging\b|\bexperiment design\b|\bmajor refactor\b|\brefactoring\b|\bthreat model\b|\uC544\uD0A4\uD14D\uCC98|\uBCF4\uC548|\uC778\uC99D|\uB9C8\uC774\uADF8\uB808\uC774\uC158|\uC2A4\uD0A4\uB9C8|\uBC30\uD3EC|\uC2E4\uD5D8\s*\uC124\uACC4|\uC6D0\uC778\s*\uBD84\uC11D|\uB9AC\uD329\uD130\uB9C1|\uB300\uADDC\uBAA8)"
    $mediumRiskPattern = "(?i)(\bbug\b|\berror\b|\bfailing test\b|\bunexpected behavior\b|\bapi\b|\bconfig\b|\bperformance\b|\bregression\b|\uD14C\uC2A4\uD2B8\s*\uC2E4\uD328|\uBC84\uADF8|\uC624\uB958|\uC5D0\uB7EC|\uC131\uB2A5|\uD68C\uADC0|\uC124\uC815)"

    if ($Text -match $highRiskPattern) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 3 -Reason "high-risk prompt signal"
    }

    if ($Text -match $mediumRiskPattern) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 1 -Reason "medium-risk prompt signal"
    }

    $fileCount = @($Files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    if ($fileCount -ge 5) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 3 -Reason "five or more changed files"
    } elseif ($fileCount -ge 2) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 1 -Reason "multiple changed files"
    }

    $sensitiveFilePattern = "(?i)(^|[\\/])(\.github|workflows|migrations?|schema|auth|security|deploy|vercel|netlify|render|cloudflare)([\\/]|$)|(^|[\\/])(Dockerfile|docker-compose\.ya?ml|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|requirements\.txt|pyproject\.toml|go\.mod|Cargo\.lock|\.env)|\.sql$"
    if ($Files | Where-Object { $_ -match $sensitiveFilePattern }) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 2 -Reason "sensitive changed file path"
    }

    if ($Failures -ge 3) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 4 -Reason "three or more repeated failures"
    } elseif ($Failures -ge 2) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 3 -Reason "two repeated failures"
    } elseif ($Failures -eq 1) {
        Add-RiskSignal -Signals $signals -Score $scoreRef -Weight 1 -Reason "one observed failure"
    }

    $route = "routine"
    if ($score -ge 6) {
        $route = "critical"
    } elseif ($score -ge 3) {
        $route = "deep"
    } elseif ($score -ge 1) {
        $route = "review"
    }

    return [pscustomobject]@{
        Route = $route
        Score = $score
        Signals = $signals
    }
}

function Get-PowerShellExecutable {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pwsh) {
        return $pwsh.Source
    }

    $powershell = Get-Command powershell -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($powershell) {
        return $powershell.Source
    }

    throw "No PowerShell executable found for invoking review helpers."
}

function Invoke-ReviewHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$ReviewPrompt,

        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath
    )

    Write-Host ""
    Write-Host ("===== {0} =====" -f $Name)

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        $message = "Review helper not found: $ScriptPath"
        Write-Warning $message
        return [pscustomobject]@{
            Name = $Name
            ExitCode = 1
            Output = $message
        }
    }

    $tempPrompt = New-TemporaryFile
    try {
        Set-Content -LiteralPath $tempPrompt.FullName -Value $ReviewPrompt -Encoding UTF8
        $helperOutput = & $PowerShellPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -PromptFile $tempPrompt.FullName 2>&1
        $helperExitCode = $LASTEXITCODE

        if ($helperOutput) {
            $helperOutput | ForEach-Object { Write-Output $_ }
        }

        if ($helperExitCode -ne 0) {
            Write-Warning ("{0} failed with exit code {1}; continuing with remaining evidence." -f $Name, $helperExitCode)
        }

        return [pscustomobject]@{
            Name = $Name
            ExitCode = $helperExitCode
            Output = ($helperOutput | Out-String)
        }
    } finally {
        Remove-Item -LiteralPath $tempPrompt.FullName -Force -ErrorAction SilentlyContinue
    }
}

$payload = Get-Payload
if ([string]::IsNullOrWhiteSpace($payload)) {
    throw "No prompt content provided. Use -Prompt, -PromptFile, or pipe text on stdin."
}

$routeInfo = Get-AutoRoute -Text $payload -Files $ChangedFiles -Failures $FailureCount
$route = if ($Mode -eq "auto") { $routeInfo.Route } else { $Mode }

Write-Host ("Smart review route: {0}" -f $route)
Write-Host ("Requested mode: {0}" -f $Mode)
Write-Host ("Risk score: {0}" -f $routeInfo.Score)
Write-Host ("Failure count: {0}" -f $FailureCount)
if ($ChangedFiles.Count -gt 0) {
    Write-Host ("Changed files: {0}" -f ($ChangedFiles -join ", "))
}
if ($routeInfo.Signals.Count -gt 0) {
    Write-Host "Risk signals:"
    foreach ($signal in $routeInfo.Signals) {
        Write-Host ("  +{0}: {1}" -f $signal.Weight, $signal.Reason)
    }
} else {
    Write-Host "Risk signals: none"
}

if ($DryRun) {
    Write-Host "Dry run: no review helpers invoked."
    exit 0
}

if ($route -eq "routine") {
    Write-Host "Routine route: no external review helper invoked."
    exit 0
}

$geminiScript = Join-Path $scriptRoot "run_gemini_review.ps1"
$claudeScript = Join-Path $scriptRoot "run_claude_review.ps1"
$powerShellPath = Get-PowerShellExecutable
$results = New-Object System.Collections.Generic.List[object]

if ($route -eq "deep" -or $route -eq "critical") {
    $results.Add((Invoke-ReviewHelper -Name "Gemini skeptical review" -ScriptPath $geminiScript -ReviewPrompt $payload -PowerShellPath $powerShellPath))
}

if ($route -eq "review" -or $route -eq "deep" -or $route -eq "critical") {
    $results.Add((Invoke-ReviewHelper -Name "Claude lead review" -ScriptPath $claudeScript -ReviewPrompt $payload -PowerShellPath $powerShellPath))
}

if ($route -eq "critical" -and $IncludeFinalTieBreaker) {
    $geminiOutput = ($results | Where-Object { $_.Name -eq "Gemini skeptical review" } | Select-Object -First 1).Output
    $claudeOutput = ($results | Where-Object { $_.Name -eq "Claude lead review" } | Select-Object -First 1).Output
    $tieBreakerPrompt = @"
You are the final tie-breaker for a critical review.

Original request:
$payload

Gemini skeptical review:
$geminiOutput

Claude lead review:
$claudeOutput

Resolve conflicts, identify remaining risks, and give the final recommendation.
"@

    $results.Add((Invoke-ReviewHelper -Name "Claude final tie-breaker" -ScriptPath $claudeScript -ReviewPrompt $tieBreakerPrompt -PowerShellPath $powerShellPath))
}

$successful = @($results | Where-Object { $_.ExitCode -eq 0 }).Count
if ($successful -eq 0) {
    Write-Error "All invoked review helpers failed."
    exit 1
}

exit 0
