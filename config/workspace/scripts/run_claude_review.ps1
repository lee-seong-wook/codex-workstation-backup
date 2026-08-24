[CmdletBinding()]
param(
    [string]$Prompt,
    [string]$PromptFile,
    [string]$Tools = "Read,Glob,Grep",
    [string[]]$AddDir = @((Get-Location).Path)
)

$claude = "{{USER_PROFILE}}\.local\bin\claude.exe"
if (-not (Test-Path -LiteralPath $claude)) {
    throw "Claude CLI not found at $claude"
}

if ($PromptFile) {
    $payload = Get-Content -LiteralPath $PromptFile -Raw -Encoding UTF8
} elseif ($Prompt) {
    $payload = $Prompt
} else {
    $pipelineText = @($input) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($pipelineText)) {
        $payload = [Console]::In.ReadToEnd()
    } else {
        $payload = $pipelineText
    }
}

if ([string]::IsNullOrWhiteSpace($payload)) {
    throw "No prompt content provided. Use -Prompt, -PromptFile, or pipe text on stdin."
}

function Get-ClaudeAuthFailureMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ClaudePath,

        [string]$ClaudeOutput
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Claude CLI authentication failed before the review could run.")
    $lines.Add("")
    $lines.Add("Observed error:")
    $lines.Add(($ClaudeOutput.Trim()))
    $lines.Add("")

    $statusText = & $ClaudePath auth status 2>$null
    $status = $null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($statusText)) {
        try {
            $status = $statusText | ConvertFrom-Json
        } catch {
            $status = $null
        }
    }

    if ($status) {
        $lines.Add(("auth status: loggedIn={0}, authMethod={1}, apiProvider={2}, subscriptionType={3}" -f `
            $status.loggedIn, $status.authMethod, $status.apiProvider, $status.subscriptionType))
    }

    $credentialsPath = Join-Path $HOME ".claude\.credentials.json"
    if (Test-Path -LiteralPath $credentialsPath) {
        try {
            $credentials = Get-Content -Raw -LiteralPath $credentialsPath | ConvertFrom-Json
            $expiresAt = $credentials.claudeAiOauth.expiresAt
            if ($expiresAt) {
                $expiresAtLocal = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$expiresAt).ToLocalTime()
                $lines.Add(("stored OAuth access token expiresAt: {0}" -f $expiresAtLocal.ToString("yyyy-MM-dd HH:mm:ss zzz")))
            }
        } catch {
            $lines.Add("stored OAuth credentials file exists but could not be parsed.")
        }
    }

    $lines.Add("")
    $lines.Add("Likely cause: the saved claude.ai OAuth access token is expired and the refresh token is no longer accepted.")
    $lines.Add("Fix with an interactive account-owner login:")
    $lines.Add(("  & '{0}' auth logout" -f $ClaudePath))
    $lines.Add(("  & '{0}' auth login --claudeai" -f $ClaudePath))
    $lines.Add("Then verify:")
    $lines.Add("  & '{{WORKSPACE_ROOT}}\scripts\Test-ClaudeAuth.ps1'")

    return ($lines -join [Environment]::NewLine)
}

$ReviewModel = "opus5"
$ReviewEffort = "xhigh"

$args = @(
    "-p",
    "--model", $ReviewModel,
    "--effort", $ReviewEffort,
    "--tools", $Tools,
    "--permission-mode", "bypassPermissions",
    "--output-format", "text",
    "--verbose"
)

foreach ($dir in $AddDir) {
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        $args += @("--add-dir", $dir)
    }
}

$claudeOutput = $payload | & $claude @args 2>&1
$claudeExitCode = $LASTEXITCODE

if ($claudeExitCode -ne 0) {
    $claudeOutputText = ($claudeOutput | Out-String)
    if ($claudeOutputText -match "401 Invalid authentication credentials|Failed to authenticate") {
        Write-Error (Get-ClaudeAuthFailureMessage -ClaudePath $claude -ClaudeOutput $claudeOutputText)
    } else {
        Write-Error $claudeOutputText
    }
    exit $claudeExitCode
}

$claudeOutput
