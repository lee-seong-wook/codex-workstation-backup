param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Get-MetricValue {
    param(
        [string[]]$Lines,
        [string]$Key
    )
    $line = $Lines | Where-Object { $_ -match "^${Key}=" } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split "=", 2)[1]
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = $scriptDir
while ($true) {
    if (Test-Path -LiteralPath (Join-Path $workspaceRoot "AGENTS.md")) {
        break
    }
    $parent = Split-Path -Parent $workspaceRoot
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $workspaceRoot) {
        throw "Could not locate workspace root containing AGENTS.md from script path: $scriptDir"
    }
    $workspaceRoot = $parent
}
$scriptsDir = Join-Path $workspaceRoot ".agents\scripts"
$skillsRoot = Join-Path $workspaceRoot "skills"
$agentsPath = Join-Path $workspaceRoot "AGENTS.md"
$validateScript = Join-Path $scriptsDir "validate-skills.ps1"
$routingScript = Join-Path $scriptsDir "routing_regression.py"
$casesPath = Join-Path $scriptsDir "routing_cases.json"

if (-not (Test-Path -LiteralPath $validateScript)) {
    throw "Missing validation script: $validateScript"
}
if (-not (Test-Path -LiteralPath $routingScript)) {
    throw "Missing routing script: $routingScript"
}
if (-not (Test-Path -LiteralPath $casesPath)) {
    throw "Missing routing cases: $casesPath"
}
if (-not (Test-Path -LiteralPath $agentsPath)) {
    throw "Missing AGENTS.md: $agentsPath"
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    throw "Python is required but not found in PATH."
}

Write-Output "== Skill Structural Validation =="
$validationOutput = & $validateScript -Root $skillsRoot
$validationOutput | Write-Output

$issues = Get-MetricValue -Lines $validationOutput -Key "SKILLS_WITH_ISSUES"
if ($null -eq $issues) {
    throw "Could not parse SKILLS_WITH_ISSUES from validate-skills output."
}

$hasFailure = $false
if ([int]$issues -gt 0) {
    $hasFailure = $true
    Write-Output "VALIDATION_FAILED=1"
}

Write-Output ""
Write-Output "== Routing Regression =="
$routingArgs = @(
    $routingScript,
    "--agents", $agentsPath,
    "--cases", $casesPath,
    "--workspace-root", $workspaceRoot
)
if ($Verbose) {
    $routingArgs += "--verbose"
}

& python @routingArgs
if ($LASTEXITCODE -ne 0) {
    $hasFailure = $true
    Write-Output "ROUTING_REGRESSION_FAILED=1"
}

Write-Output ""
if ($hasFailure) {
    Write-Output "SKILL_CHECK_OVERALL=FAIL"
    exit 1
}

Write-Output "SKILL_CHECK_OVERALL=PASS"
