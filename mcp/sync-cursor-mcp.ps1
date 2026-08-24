param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$canonicalManifest = Join-Path $PSScriptRoot "cursor.mcp.json"
$cursorDir = Join-Path $repoRoot ".cursor"
$compatManifest = Join-Path $cursorDir "mcp.json"

if (-not (Test-Path $canonicalManifest -PathType Leaf)) {
    throw "Canonical MCP manifest not found: $canonicalManifest"
}

if (-not (Test-Path $cursorDir -PathType Container)) {
    New-Item -ItemType Directory -Path $cursorDir | Out-Null
}

if (Test-Path $compatManifest) {
    $compatItem = Get-Item $compatManifest -Force
    $isExpectedHardLink = $compatItem.LinkType -eq "HardLink" -and @($compatItem.Target) -contains $canonicalManifest

    if ($isExpectedHardLink -and -not $Force) {
        Write-Output "Compatibility manifest already linked: $compatManifest -> $canonicalManifest"
        exit 0
    }

    Remove-Item $compatManifest -Force
}

New-Item -ItemType HardLink -Path $compatManifest -Target $canonicalManifest | Out-Null
Write-Output "Created hard link: $compatManifest -> $canonicalManifest"
