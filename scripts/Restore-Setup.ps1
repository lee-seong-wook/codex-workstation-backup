[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$WorkspaceRoot = (Join-Path $env:USERPROFILE 'Desktop\code'),
    [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex'),
    [string]$CursorHome = (Join-Path $env:USERPROFILE '.cursor'),
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Force,
    [switch]$RestorePrivilegedPolicy,
    [switch]$SkipPlugins,
    [switch]$SkipGstack
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:BackupStamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Get-FullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Assert-NoReparseInExistingPath {
    param([Parameter(Mandatory)][string]$Path)
    $full = Get-FullPath $Path
    $root = [System.IO.Path]::GetPathRoot($full)
    $current = $root.TrimEnd('\', '/')
    $relative = $full.Substring($root.Length)
    foreach ($segment in $relative -split '[\\/]' | Where-Object { $_ }) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) {
            break
        }
        $item = Get-Item -LiteralPath $current -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Restore root or ancestor is a junction or symbolic link: $current"
        }
    }
}

function Test-PathInsideAllowedRoot {
    param([Parameter(Mandatory)][string]$Path)
    $candidate = Get-FullPath $Path
    foreach ($root in @($WorkspaceRoot, $CodexHome, $CursorHome, (Join-Path $env:USERPROFILE '.gstack'))) {
        $allowed = Get-FullPath $root
        if ($candidate -eq $allowed -or $candidate.StartsWith($allowed + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function ConvertFrom-PortableText {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [switch]$WindowsLiteralPaths
    )
    $workspace = Get-FullPath $WorkspaceRoot
    $profile = Get-FullPath $env:USERPROFILE
    $codex = Get-FullPath $CodexHome
    if (-not $WindowsLiteralPaths) {
        $workspace = $workspace -replace '\\', '/'
        $profile = $profile -replace '\\', '/'
        $codex = $codex -replace '\\', '/'
    }
    return $Text.Replace('{{WORKSPACE_ROOT}}', $workspace).Replace('{{USER_PROFILE}}', $profile).Replace('{{CODEX_HOME}}', $codex)
}

function Backup-ExistingTarget {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-PathInsideAllowedRoot $Path)) {
        throw "Refusing to move a path outside the allowed restore roots: $Path"
    }
    $backupPath = $Path + '.backup-' + $script:BackupStamp
    if (Test-Path -LiteralPath $backupPath) {
        $backupPath += '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    }
    Move-Item -LiteralPath $Path -Destination $backupPath
    Write-Host "Backed up: $Path -> $backupPath"
    return $backupPath
}

function Test-DestinationReady {
    param([Parameter(Mandatory)][string]$Destination)
    if (Test-Path -LiteralPath $Destination) {
        $item = Get-Item -LiteralPath $Destination -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to replace a junction or symbolic link: $Destination"
        }
        if (-not $Force) {
            Write-Warning "Skipped existing target (use -Force to back up and replace): $Destination"
            return $false
        }
    }
    return $true
}

function Install-Directory {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [switch]$RenderText
    )
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        return
    }
    if (-not (Test-DestinationReady $Destination)) {
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Destination, "Stage, back up if needed, and atomically restore directory from $Source")) {
        return
    }

    $stage = $Destination + '.restore-stage-' + [guid]::NewGuid().ToString('N')
    if (-not (Test-PathInsideAllowedRoot $stage)) {
        throw "Unsafe restore staging path: $stage"
    }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $textExtensions = @('.md', '.txt', '.json', '.toml', '.yaml', '.yml', '.ps1', '.psm1', '.cmd', '.py', '.js', '.ts', '.mjs', '.cjs', '.sh', '.tex', '.sty', '.mplstyle')
    $backup = $null
    try {
        foreach ($file in Get-ChildItem -LiteralPath $Source -Recurse -File -Force) {
            $relative = [System.IO.Path]::GetRelativePath($Source, $file.FullName)
            $target = Join-Path $stage $relative
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            if ($RenderText -and $file.Extension.ToLowerInvariant() -in $textExtensions) {
                $content = ConvertFrom-PortableText (Get-Content -LiteralPath $file.FullName -Raw)
                [System.IO.File]::WriteAllText($target, $content, $script:Utf8NoBom)
            } else {
                Copy-Item -LiteralPath $file.FullName -Destination $target -Force
            }
        }
        if (Test-Path -LiteralPath $Destination) {
            $backup = Backup-ExistingTarget $Destination
        }
        Move-Item -LiteralPath $stage -Destination $Destination
    } catch {
        if (-not (Test-Path -LiteralPath $Destination) -and $backup -and (Test-Path -LiteralPath $backup)) {
            Move-Item -LiteralPath $backup -Destination $Destination
        }
        if (Test-Path -LiteralPath $stage) {
            Remove-Item -LiteralPath $stage -Recurse -Force
        }
        throw
    }
    Write-Host "Restored directory: $Destination"
}

function Install-File {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [switch]$RenderText,
        [switch]$WindowsLiteralPaths
    )
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        return
    }
    if (-not (Test-DestinationReady $Destination)) {
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Destination, "Stage, back up if needed, and atomically restore file from $Source")) {
        return
    }

    $stage = $Destination + '.restore-stage-' + [guid]::NewGuid().ToString('N')
    if (-not (Test-PathInsideAllowedRoot $stage)) {
        throw "Unsafe restore staging path: $stage"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    $backup = $null
    try {
        if ($RenderText) {
            $content = ConvertFrom-PortableText (Get-Content -LiteralPath $Source -Raw) -WindowsLiteralPaths:$WindowsLiteralPaths
            [System.IO.File]::WriteAllText($stage, $content, $script:Utf8NoBom)
        } else {
            Copy-Item -LiteralPath $Source -Destination $stage -Force
        }
        if (Test-Path -LiteralPath $Destination) {
            $backup = Backup-ExistingTarget $Destination
        }
        Move-Item -LiteralPath $stage -Destination $Destination
    } catch {
        if (-not (Test-Path -LiteralPath $Destination) -and $backup -and (Test-Path -LiteralPath $backup)) {
            Move-Item -LiteralPath $backup -Destination $Destination
        }
        if (Test-Path -LiteralPath $stage) {
            Remove-Item -LiteralPath $stage -Force
        }
        throw
    }
    Write-Host "Restored file: $Destination"
}

function Assert-RepositoryIntegrity {
    $manifestPath = Join-Path $RepositoryRoot 'manifests\files.sha256.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Integrity manifest not found: $manifestPath"
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $manifest.files) {
        $relative = ([string]$entry.path).Replace('\', '/')
        if ([System.IO.Path]::IsPathRooted($relative) -or @($relative -split '/' | Where-Object { $_ -eq '..' }).Count -gt 0) {
            throw "Unsafe manifest path: $relative"
        }
        if (-not $seen.Add($relative)) {
            throw "Duplicate manifest path: $relative"
        }
        $full = Get-FullPath (Join-Path $RepositoryRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar))
        if (-not $full.StartsWith($RepositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest path escapes the repository: $relative"
        }
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            throw "Manifest file is missing: $relative"
        }
        $file = Get-Item -LiteralPath $full -Force
        if ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Repository contains a linked file: $relative"
        }
        if ($file.Length -ne [int64]$entry.size) {
            throw "Manifest size mismatch: $relative"
        }
        $hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne [string]$entry.sha256) {
            throw "Manifest hash mismatch: $relative"
        }
    }
    $actual = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Force | ForEach-Object {
        $relative = [System.IO.Path]::GetRelativePath($RepositoryRoot, $_.FullName).Replace('\', '/')
        if ($relative -ne 'manifests/files.sha256.json' -and $relative -notlike '.git/*') { $relative }
    })
    if ($manifest.fileCount -ne $seen.Count -or $actual.Count -ne $seen.Count) {
        throw "Manifest file set mismatch: manifest=$($seen.Count), actual=$($actual.Count)"
    }
    foreach ($relative in $actual) {
        if (-not $seen.Contains($relative)) {
            throw "Unmanifested repository file: $relative"
        }
    }
}

function Install-PluginsFromLock {
    $lockPath = Join-Path $RepositoryRoot 'manifests\plugins.lock.json'
    $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    $enabled = @($lock.plugins | Where-Object enabled)
    $codex = Get-Command codex -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $codex) {
        Write-Warning 'Codex CLI was not found. Install these plugins from the Codex Plugins screen:'
        $enabled.id | ForEach-Object { Write-Host "  - $_" }
        return
    }

    foreach ($plugin in $enabled) {
        if ($PSCmdlet.ShouldProcess($plugin.id, 'Install or refresh Codex plugin')) {
            Write-Host "Installing plugin: $($plugin.id)"
            & $codex.Source plugin add $plugin.id
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Plugin installation failed; install it manually in the Plugins screen: $($plugin.id)"
            }
        }
    }
}

function Install-GstackFromLock {
    $lockPath = Join-Path $RepositoryRoot 'manifests\plugins.lock.json'
    $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    $gstack = $lock.externalSources | Where-Object name -eq 'gstack' | Select-Object -First 1
    if (-not $gstack) {
        throw 'gstack lock entry not found.'
    }

    $git = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $git) {
        Write-Warning 'Git was not found; gstack was not restored.'
        return
    }
    $pathBash = Get-Command bash -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    $bashCandidates = @(
        'C:\Program Files\Git\bin\bash.exe',
        $pathBash
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) -and $_ -match '(?i)[\\/]Git[\\/]bin[\\/]bash\.exe$' } | Select-Object -Unique
    $bash = $bashCandidates | Select-Object -First 1
    if (-not $bash) {
        Write-Warning 'Git Bash was not found; gstack source can be cloned but setup cannot run.'
    }

    $target = Join-Path $env:USERPROFILE '.gstack\repos\gstack'
    if (Test-Path -LiteralPath $target) {
        $current = (& $git.Source -C $target rev-parse HEAD 2>$null)
        if ($current -eq $gstack.commit) {
            Write-Host "gstack already matches pinned commit: $current"
            if ($bash -and $PSCmdlet.ShouldProcess($target, 'Run the pinned gstack setup idempotently')) {
                Push-Location -LiteralPath $target
                try {
                    & $bash './setup'
                    if ($LASTEXITCODE -ne 0) { throw 'gstack setup failed.' }
                } finally {
                    Pop-Location
                }
            }
            return
        }
        if (-not $Force) {
            Write-Warning "Existing gstack checkout differs; skipped. Use -Force to back it up and replace it: $target"
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($target, "Stage, back up if needed, and install gstack at $($gstack.commit)")) {
        $stage = $target + '.restore-stage-' + [guid]::NewGuid().ToString('N')
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        $backup = $null
        try {
            & $git.Source clone $gstack.repository $stage
            if ($LASTEXITCODE -ne 0) { throw 'gstack clone failed.' }
            & $git.Source -C $stage checkout --detach $gstack.commit
            if ($LASTEXITCODE -ne 0) { throw 'gstack checkout failed.' }
            if (Test-Path -LiteralPath $target) {
                $backup = Backup-ExistingTarget $target
            }
            Move-Item -LiteralPath $stage -Destination $target
            if ($bash) {
                Push-Location -LiteralPath $target
                try {
                    & $bash './setup'
                    if ($LASTEXITCODE -ne 0) { throw 'gstack setup failed.' }
                } finally {
                    Pop-Location
                }
            }
        } catch {
            if ($backup -and (Test-Path -LiteralPath $backup)) {
                if (Test-Path -LiteralPath $target) {
                    Remove-Item -LiteralPath $target -Recurse -Force
                }
                Move-Item -LiteralPath $backup -Destination $target
            }
            if (Test-Path -LiteralPath $stage) {
                Remove-Item -LiteralPath $stage -Recurse -Force
            }
            throw
        }
    }
}

$WorkspaceRoot = Get-FullPath $WorkspaceRoot
$CodexHome = Get-FullPath $CodexHome
$CursorHome = Get-FullPath $CursorHome
$RepositoryRoot = Get-FullPath $RepositoryRoot

foreach ($root in @($WorkspaceRoot, $CodexHome, $CursorHome)) {
    if ($root -eq [System.IO.Path]::GetPathRoot($root) -or $root -eq (Get-FullPath $env:USERPROFILE)) {
        throw "Unsafe restore root: $root"
    }
    Assert-NoReparseInExistingPath $root
}
Assert-NoReparseInExistingPath (Join-Path $env:USERPROFILE '.gstack')
Assert-NoReparseInExistingPath $RepositoryRoot
foreach ($sentinel in @(
    (Join-Path $RepositoryRoot 'README.md'),
    (Join-Path $RepositoryRoot 'scripts\Restore-Setup.ps1'),
    (Join-Path $RepositoryRoot 'manifests\files.sha256.json')
)) {
    if (-not (Test-Path -LiteralPath $sentinel -PathType Leaf)) {
        throw "Repository sentinel not found: $sentinel"
    }
}
$repoItem = Get-Item -LiteralPath $RepositoryRoot -Force
if ($repoItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw "Repository root must not be a junction or symbolic link: $RepositoryRoot"
}
$linkedEntries = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue)
if ($linkedEntries.Count -gt 0) {
    throw "Repository contains junctions or symbolic links; restore is blocked: $($linkedEntries[0].FullName)"
}
foreach ($target in @(
    (Join-Path $WorkspaceRoot 'skills'),
    (Join-Path $WorkspaceRoot 'mcp'),
    (Join-Path $WorkspaceRoot 'scripts'),
    (Join-Path $WorkspaceRoot '.agents\scripts'),
    (Join-Path $WorkspaceRoot '.agents\archived-skills'),
    (Join-Path $WorkspaceRoot '.cursor\rules'),
    (Join-Path $CodexHome 'skills'),
    (Join-Path $CursorHome 'skills')
)) {
    $targetFull = Get-FullPath $target
    if ($RepositoryRoot -eq $targetFull -or
        $RepositoryRoot.StartsWith($targetFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $targetFull.StartsWith($RepositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Repository and restore target must be disjoint: $targetFull"
    }
}
Assert-RepositoryIntegrity

Install-Directory -Source (Join-Path $RepositoryRoot 'skills\workspace') -Destination (Join-Path $WorkspaceRoot 'skills') -RenderText
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'skills\codex-global') -Directory -ErrorAction SilentlyContinue) {
    Install-Directory -Source $skill.FullName -Destination (Join-Path $CodexHome ('skills\' + $skill.Name)) -RenderText
}
Install-Directory -Source (Join-Path $RepositoryRoot 'skills\cursor-global') -Destination (Join-Path $CursorHome 'skills') -RenderText
Install-Directory -Source (Join-Path $RepositoryRoot 'skills\archived') -Destination (Join-Path $WorkspaceRoot '.agents\archived-skills') -RenderText

$workspaceConfig = Join-Path $RepositoryRoot 'config\workspace'
foreach ($name in @('AGENTS.md', 'CLAUDE.md', 'GEMINI.md')) {
    Install-File -Source (Join-Path $workspaceConfig $name) -Destination (Join-Path $WorkspaceRoot $name) -RenderText
}
Install-Directory -Source (Join-Path $workspaceConfig 'scripts') -Destination (Join-Path $WorkspaceRoot 'scripts') -RenderText
Install-Directory -Source (Join-Path $workspaceConfig '.agents\scripts') -Destination (Join-Path $WorkspaceRoot '.agents\scripts') -RenderText
foreach ($relative in @('.agents\README.md', '.agents\skill-check.ps1', '.agents\skill-check.cmd')) {
    Install-File -Source (Join-Path $workspaceConfig $relative) -Destination (Join-Path $WorkspaceRoot $relative) -RenderText
}
Install-Directory -Source (Join-Path $workspaceConfig '.cursor\rules') -Destination (Join-Path $WorkspaceRoot '.cursor\rules') -RenderText
Install-File -Source (Join-Path $workspaceConfig '.cursor\settings.template.json') -Destination (Join-Path $WorkspaceRoot '.cursor\settings.json') -RenderText
Install-File -Source (Join-Path $workspaceConfig '.cursor\mcp.template.json') -Destination (Join-Path $WorkspaceRoot '.cursor\mcp.json') -RenderText
$claudeTemplate = if ($RestorePrivilegedPolicy) { '.claude\settings.local.privileged.template.json' } else { '.claude\settings.local.template.json' }
$codexTemplate = if ($RestorePrivilegedPolicy) { 'config\codex\config.privileged.template.toml' } else { 'config\codex\config.template.toml' }
Install-File -Source (Join-Path $workspaceConfig $claudeTemplate) -Destination (Join-Path $WorkspaceRoot '.claude\settings.local.json') -RenderText
Install-File -Source (Join-Path $RepositoryRoot $codexTemplate) -Destination (Join-Path $CodexHome 'config.toml') -RenderText -WindowsLiteralPaths
Install-Directory -Source (Join-Path $RepositoryRoot 'mcp') -Destination (Join-Path $WorkspaceRoot 'mcp') -RenderText

if (-not $SkipGstack) {
    Install-GstackFromLock
}
if (-not $SkipPlugins) {
    Install-PluginsFromLock
}

Write-Host ''
Write-Host 'Restore finished. Start a new Codex session after plugin installation.'
Write-Host 'Reconnect external services on this laptop: GitHub, Notion, Linear, Zotero, Binance.'
if (-not $RestorePrivilegedPolicy) {
    Write-Host 'Safe approval and sandbox defaults were restored. Use -RestorePrivilegedPolicy only to reproduce the original full-access policies.'
}
if (-not $env:GITHUB_PERSONAL_ACCESS_TOKEN) {
    Write-Warning 'GITHUB_PERSONAL_ACCESS_TOKEN is not set. The GitHub MCP entry is restored but will not authenticate until the environment variable is configured.'
}
