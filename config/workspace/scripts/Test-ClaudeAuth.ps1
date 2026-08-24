[CmdletBinding()]
param(
    [switch]$SkipSmokeTest
)

$claude = "{{USER_PROFILE}}\.local\bin\claude.exe"
if (-not (Test-Path -LiteralPath $claude)) {
    $command = Get-Command claude -ErrorAction SilentlyContinue
    if ($command) {
        $claude = $command.Source
    } else {
        throw "Claude CLI not found at {{USER_PROFILE}}\.local\bin\claude.exe or on PATH."
    }
}

Write-Host "Claude CLI: $claude"

$version = & $claude --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Version: $version"
} else {
    Write-Warning "Could not read Claude CLI version: $version"
}

$statusText = & $claude auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Claude auth status failed: $($statusText | Out-String)"
    exit 1
}

$status = $null
try {
    $status = $statusText | ConvertFrom-Json
} catch {
    Write-Error "Claude auth status returned non-JSON output: $($statusText | Out-String)"
    exit 1
}

Write-Host ("Auth status: loggedIn={0}, authMethod={1}, apiProvider={2}, subscriptionType={3}" -f `
    $status.loggedIn, $status.authMethod, $status.apiProvider, $status.subscriptionType)

$credentialsPath = Join-Path $HOME ".claude\.credentials.json"
if (Test-Path -LiteralPath $credentialsPath) {
    try {
        $credentials = Get-Content -Raw -LiteralPath $credentialsPath | ConvertFrom-Json
        $expiresAt = $credentials.claudeAiOauth.expiresAt
        if ($expiresAt) {
            $expiresAtLocal = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$expiresAt).ToLocalTime()
            Write-Host ("Stored OAuth access token expiresAt: {0}" -f $expiresAtLocal.ToString("yyyy-MM-dd HH:mm:ss zzz"))
        } else {
            Write-Host "Stored OAuth credentials found; no expiresAt field detected."
        }
    } catch {
        Write-Warning "Stored OAuth credentials file exists but could not be parsed."
    }
} else {
    Write-Host "Stored OAuth credentials file: missing"
}

if ($SkipSmokeTest) {
    exit 0
}

$smokePrompt = "Reply with OK only."
$smokeOutput = $smokePrompt | & $claude -p --output-format text --no-session-persistence 2>&1
$smokeExitCode = $LASTEXITCODE
$smokeText = ($smokeOutput | Out-String).Trim()

if ($smokeExitCode -eq 0) {
    Write-Host "Non-interactive Claude smoke test: passed"
    Write-Output $smokeOutput
    exit 0
}

if ($smokeText -match "401 Invalid authentication credentials|Failed to authenticate") {
    Write-Error @"
Non-interactive Claude smoke test failed with 401.

Likely cause: auth status can still show loggedIn while the saved claude.ai OAuth access token is expired and the refresh token is no longer accepted.

Fix with an interactive account-owner login:
  & '$claude' auth logout
  & '$claude' auth login --claudeai

Then rerun:
  & '{{WORKSPACE_ROOT}}\scripts\Test-ClaudeAuth.ps1'
"@
} else {
    Write-Error "Non-interactive Claude smoke test failed: $smokeText"
}

exit $smokeExitCode
