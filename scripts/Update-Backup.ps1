[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$WorkspaceRoot = (Join-Path $env:USERPROFILE 'Desktop\code'),
    [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex'),
    [string]$CursorHome = (Join-Path $env:USERPROFILE '.cursor'),
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:GstackCommit = 'db9447c3339950bb0506c547e5b3225f5def3854'
$script:GstackRepository = 'https://github.com/garrytan/gstack.git'
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Get-NormalizedFullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Assert-WithinBuildRoot {
    param([Parameter(Mandatory)][string]$Path)
    $repo = Get-NormalizedFullPath $script:BuildRoot
    $candidate = Get-NormalizedFullPath $Path
    if ($candidate -eq $repo -or -not $candidate.StartsWith($repo + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Generated path is outside the repository: $candidate"
    }
}

function Reset-GeneratedDirectory {
    param([Parameter(Mandatory)][string]$Path)
    Assert-WithinBuildRoot $Path
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function ConvertTo-PortableText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $result = $Text
    $workspaceFull = Get-NormalizedFullPath $WorkspaceRoot
    $profileFull = Get-NormalizedFullPath $env:USERPROFILE
    $workspaceMsys = '/' + $workspaceFull.Substring(0, 1).ToLowerInvariant() + $workspaceFull.Substring(2).Replace('\', '/')
    $profileMsys = '/' + $profileFull.Substring(0, 1).ToLowerInvariant() + $profileFull.Substring(2).Replace('\', '/')
    $replacements = @(
        @{ Value = (Get-NormalizedFullPath $WorkspaceRoot); Token = '{{WORKSPACE_ROOT}}' },
        @{ Value = ((Get-NormalizedFullPath $WorkspaceRoot) -replace '\\', '/'); Token = '{{WORKSPACE_ROOT}}' },
        @{ Value = ((Get-NormalizedFullPath $WorkspaceRoot) -replace '\\', '\\\\'); Token = '{{WORKSPACE_ROOT}}' },
        @{ Value = $workspaceMsys; Token = '{{WORKSPACE_ROOT}}' },
        @{ Value = ('/' + $workspaceMsys); Token = '{{WORKSPACE_ROOT}}' },
        @{ Value = (Get-NormalizedFullPath $env:USERPROFILE); Token = '{{USER_PROFILE}}' },
        @{ Value = ((Get-NormalizedFullPath $env:USERPROFILE) -replace '\\', '/'); Token = '{{USER_PROFILE}}' },
        @{ Value = ((Get-NormalizedFullPath $env:USERPROFILE) -replace '\\', '\\\\'); Token = '{{USER_PROFILE}}' },
        @{ Value = $profileMsys; Token = '{{USER_PROFILE}}' },
        @{ Value = ('/' + $profileMsys); Token = '{{USER_PROFILE}}' },
        @{ Value = (Get-NormalizedFullPath $CodexHome); Token = '{{CODEX_HOME}}' },
        @{ Value = ((Get-NormalizedFullPath $CodexHome) -replace '\\', '/'); Token = '{{CODEX_HOME}}' }
    ) | Sort-Object { $_.Value.Length } -Descending

    foreach ($entry in $replacements) {
        if (-not [string]::IsNullOrWhiteSpace($entry.Value)) {
            $result = [regex]::Replace(
                $result,
                [regex]::Escape([string]$entry.Value),
                [System.Text.RegularExpressions.MatchEvaluator]{ param($match) [string]$entry.Token },
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }
    }
    return $result
}

function Copy-PortableTextFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    $text = Get-Content -LiteralPath $Source -Raw
    Write-Utf8File -Path $Destination -Content (ConvertTo-PortableText $text)
}

function Test-SecretLikeValue {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $patterns = @(
        '(?i)github_pat_[A-Za-z0-9_]{20,}',
        '(?i)gh[pousr]_[A-Za-z0-9]{30,}',
        '(?i)sk-(?:proj-)?[A-Za-z0-9_-]{24,}',
        '\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
        '(?i)xox[baprs]-[A-Za-z0-9-]{10,}',
        '(?i)(?:sk|rk)_live_[A-Za-z0-9]{16,}',
        '(?i)glpat-[A-Za-z0-9_-]{20,}',
        '(?i)hf_[A-Za-z0-9]{20,}',
        '(?i)npm_[A-Za-z0-9]{20,}',
        '(?i)pypi-AgEIcHlwaS5vcmc[A-Za-z0-9_-]{20,}',
        'AIza[A-Za-z0-9_-]{35}',
        '(?i)Bearer\s+[A-Za-z0-9._~-]{20,}',
        'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
        '(?i)https://[^/\s:@]+:[^@\s/]+@'
    )
    return [bool]($patterns | Where-Object { $Text -match $_ } | Select-Object -First 1)
}

function Test-ExcludedRelativePath {
    param([Parameter(Mandatory)][string]$RelativePath)

    $segments = $RelativePath -split '[\\/]'
    $excludedDirectories = @('.git', '__pycache__', 'node_modules', '.cache', 'cache', 'sessions', 'cookies')
    if ($segments | Where-Object { $_ -in $excludedDirectories }) {
        return $true
    }

    $name = [System.IO.Path]::GetFileName($RelativePath)
    if ($name -in @('auth.json', 'install_log.txt', '.npmrc', '.pypirc', '.netrc')) {
        return $true
    }
    if ($name -match '(?i)(credential|secret|\.log$|\.pyc$|\.sqlite(?:-.+)?$|\.db(?:-.+)?$|\.wal$|^\.env(?:\..+)?$|\.(pem|key|pfx|p12)$)') {
        return $true
    }
    return $false
}

function Copy-FilteredTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [switch]$PortableText
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Source directory not found: $Source"
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    $textExtensions = @('.md', '.txt', '.json', '.toml', '.yaml', '.yml', '.ps1', '.psm1', '.cmd', '.py', '.js', '.ts', '.mjs', '.cjs', '.sh', '.tex', '.sty', '.mplstyle')
    foreach ($file in Get-ChildItem -LiteralPath $Source -Recurse -File -Force) {
        if ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            continue
        }
        $relative = [System.IO.Path]::GetRelativePath($Source, $file.FullName)
        if (Test-ExcludedRelativePath $relative) {
            continue
        }
        $target = Join-Path $Destination $relative
        $parent = Split-Path -Parent $target
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        if ($PortableText -and $file.Extension.ToLowerInvariant() -in $textExtensions) {
            Copy-PortableTextFile -Source $file.FullName -Destination $target
        } else {
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        }
    }
}

function New-SanitizedCodexConfig {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    $output = [System.Collections.Generic.List[string]]::new()
    $section = ''
    $skipSection = $false

    foreach ($rawLine in Get-Content -LiteralPath $Source) {
        $line = [string]$rawLine
        if ($line.Trim() -match '^\[(.+)\]$') {
            $section = $Matches[1]
            $skipSection = (
                $section -like 'projects.*' -or
                $section -eq 'mcp_servers.github.env' -or
                $section -like 'mcp_servers.node_repl*' -or
                $section -like 'hooks.state*' -or
                $section -eq 'shell_environment_policy.set'
            )
            if ($skipSection) {
                continue
            }
            $output.Add((ConvertTo-PortableText $line))
            if ($section -eq 'mcp_servers.github') {
                $output.Add('env_vars = ["GITHUB_PERSONAL_ACCESS_TOKEN"]')
            }
            continue
        }

        if ($skipSection) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($section) -and $line.TrimStart() -match '^notify\s*=') {
            continue
        }
        if ($section -eq 'mcp_servers.github' -and $line.TrimStart() -match '^env_vars\s*=') {
            continue
        }
        if ($line -match '^\s*([A-Za-z0-9_.-]+)\s*=') {
            $keyName = $Matches[1]
            if ($keyName -match '(?i)(^|[_-])(password|secret|api[_-]?key|access[_-]?token|authorization|cookie|session)([_-]|$)') {
                throw "Unexpected sensitive configuration key outside a sanitized section: $keyName"
            }
        }
        if (Test-SecretLikeValue $line) {
            throw "Secret-like value detected while sanitizing Codex config section [$section]."
        }
        $output.Add((ConvertTo-PortableText $line))
    }

    $output.Add('')
    $output.Add("[projects.'{{WORKSPACE_ROOT}}']")
    $output.Add('trust_level = "trusted"')
    $output.Add('')
    Write-Utf8File -Path $Destination -Content (($output -join [Environment]::NewLine).Trim() + [Environment]::NewLine)
}

function New-SafeCodexConfig {
    param(
        [Parameter(Mandatory)][string]$PrivilegedTemplate,
        [Parameter(Mandatory)][string]$Destination
    )
    $content = Get-Content -LiteralPath $PrivilegedTemplate -Raw
    $content = [regex]::Replace($content, '(?m)^approval_policy\s*=\s*"[^"]+"', 'approval_policy = "on-request"')
    $content = [regex]::Replace($content, '(?m)^sandbox_mode\s*=\s*"[^"]+"', 'sandbox_mode = "workspace-write"')
    $content = [regex]::Replace($content, '(?m)^trust_level\s*=\s*"trusted"', 'trust_level = "untrusted"')
    Write-Utf8File -Path $Destination -Content $content
}

function Protect-JsonObject {
    param([Parameter(Mandatory)]$Value)

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $keyText = [string]$key
            if ($keyText -match '(?i)(password|token|secret|api[_-]?key|private[_-]?key|authorization|cookie|session)') {
                $envName = ($keyText -replace '[^A-Za-z0-9_]', '_').ToUpperInvariant()
                $result[$keyText] = '${env:' + $envName + '}'
            } else {
                $result[$keyText] = Protect-JsonObject $Value[$key]
            }
        }
        return $result
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @($Value | ForEach-Object { Protect-JsonObject $_ })
        return ,$items
    }
    if ($Value -is [string]) {
        if (Test-SecretLikeValue $Value) {
            return '${env:REDACTED_SECRET}'
        }
        return ConvertTo-PortableText $Value
    }
    return $Value
}

function New-SanitizedJsonTemplate {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    $json = Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json -AsHashtable
    $safe = Protect-JsonObject $json
    Write-Utf8File -Path $Destination -Content (($safe | ConvertTo-Json -Depth 100) + [Environment]::NewLine)
}

function New-ClaudeSettingsTemplates {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$SafeDestination,
        [Parameter(Mandatory)][string]$PrivilegedDestination
    )
    $json = Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json -AsHashtable
    $allow = @($json.permissions.allow)
    $ephemeralPattern = '(?i)(taskkill|timeout\s+\d+\s+tail|npm-cache|C--Users-|/tasks/[^/]+\.output|//PID\s+\d+|/PID\s+\d+)'
    $privilegedAllow = @($allow | Where-Object { [string]$_ -notmatch $ephemeralPattern } | ForEach-Object { ConvertTo-PortableText ([string]$_) })
    $safeAllow = @($privilegedAllow | Where-Object { $_ -match '^(WebSearch|WebFetch\(|Skill\()' })
    $safe = [ordered]@{ permissions = [ordered]@{ allow = $safeAllow; deny = @() } }
    $privileged = [ordered]@{ permissions = [ordered]@{ allow = $privilegedAllow; deny = @() } }
    Write-Utf8File -Path $SafeDestination -Content (($safe | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
    Write-Utf8File -Path $PrivilegedDestination -Content (($privileged | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
}

function Get-SkillName {
    param([Parameter(Mandatory)][string]$SkillFile)
    $line = Get-Content -LiteralPath $SkillFile -TotalCount 30 | Where-Object { $_ -match '^name:\s*(.+?)\s*$' } | Select-Object -First 1
    if ($line -and $line -match '^name:\s*(.+?)\s*$') {
        return $Matches[1].Trim('"', "'")
    }
    return Split-Path (Split-Path $SkillFile -Parent) -Leaf
}

function ConvertTo-SourceTokenPath {
    param([Parameter(Mandatory)][string]$Path)
    return (ConvertTo-PortableText (Get-NormalizedFullPath $Path)) -replace '\\', '/'
}

function Get-EnabledPlugins {
    param([Parameter(Mandatory)][string]$ConfigPath)
    $plugins = [ordered]@{}
    $current = $null
    foreach ($line in Get-Content -LiteralPath $ConfigPath) {
        if ($line.Trim() -match '^\[plugins\."([^"]+)"\]$') {
            $current = $Matches[1]
            if (-not $plugins.Contains($current)) {
                $plugins[$current] = $false
            }
            continue
        }
        if ($current -and $line.Trim() -match '^enabled\s*=\s*(true|false)\s*$') {
            $plugins[$current] = ($Matches[1] -eq 'true')
            $current = $null
        }
    }
    return $plugins
}

function Get-PluginCacheIdentity {
    param(
        [Parameter(Mandatory)][string]$SkillFile,
        [Parameter(Mandatory)][string]$PluginCacheRoot
    )
    $relative = [System.IO.Path]::GetRelativePath($PluginCacheRoot, $SkillFile)
    $parts = $relative -split '[\\/]'
    $marketplace = if ($parts.Count -gt 0) { $parts[0] } else { 'unknown' }
    $plugin = if ($parts.Count -gt 1) { $parts[1] } else { 'unknown' }
    $version = if ($parts.Count -gt 2) { $parts[2] } else { 'unknown' }
    if ($plugin -like 'plugin-install-*' -and $parts.Count -gt 3) {
        $plugin = $parts[2]
        $version = $parts[3]
    } elseif ($plugin -like 'plugin-backup-*' -and $parts.Count -gt 2) {
        $plugin = $parts[2]
        $version = 'backup'
    }
    return [pscustomobject]@{ Marketplace = $marketplace; Plugin = $plugin; Version = $version }
}

function Test-CustomCodexGlobalSkill {
    param([Parameter(Mandatory)][string]$TopLevelName)
    if ($TopLevelName -eq '.system' -or $TopLevelName -like 'gstack*' -or $TopLevelName -like 'notion-*' -or $TopLevelName -eq 'codex-primary-runtime') {
        return $false
    }
    return $true
}

function New-SkillInventory {
    param(
        [Parameter(Mandatory)][hashtable]$EnabledPlugins,
        [Parameter(Mandatory)][string]$Destination
    )

    $pluginCache = Join-Path $CodexHome 'plugins\cache'
    $sources = @(
        [pscustomobject]@{ Kind = 'workspace'; Root = (Join-Path $WorkspaceRoot 'skills'); Scope = 'workspace'; Action = 'copy'; Vendor = 'skills/workspace'; Active = $true },
        [pscustomobject]@{ Kind = 'codex-global'; Root = (Join-Path $CodexHome 'skills'); Scope = 'codex-global'; Action = 'classify'; Vendor = $null; Active = $true },
        [pscustomobject]@{ Kind = 'plugin-cache'; Root = $pluginCache; Scope = 'plugin'; Action = 'reinstall'; Vendor = $null; Active = $false },
        [pscustomobject]@{ Kind = 'cursor-global'; Root = (Join-Path $CursorHome 'skills'); Scope = 'cursor-global'; Action = 'copy'; Vendor = 'skills/cursor-global'; Active = $true },
        [pscustomobject]@{ Kind = 'archived'; Root = (Join-Path $WorkspaceRoot '.agents\archived-skills'); Scope = 'archived'; Action = 'copy'; Vendor = 'skills/archived'; Active = $false }
    )

    $items = [System.Collections.Generic.List[object]]::new()
    foreach ($source in $sources) {
        if (-not (Test-Path -LiteralPath $source.Root)) {
            continue
        }
        foreach ($skillFile in @(Get-ChildItem -LiteralPath $source.Root -Recurse -Filter 'SKILL.md' -File -Force)) {
            $relative = [System.IO.Path]::GetRelativePath($source.Root, $skillFile.FullName) -replace '\\', '/'
            $action = $source.Action
            $vendorPath = if ($source.Vendor) { ($source.Vendor + '/' + $relative) } else { $null }
            $packageId = $null
            $packageVersion = $null
            $active = [bool]$source.Active

            if ($source.Kind -eq 'codex-global') {
                $top = ($relative -split '/')[0]
                if (Test-CustomCodexGlobalSkill $top) {
                    $action = 'copy'
                    $vendorPath = 'skills/codex-global/' + $relative
                } elseif ($top -eq '.system') {
                    $action = 'system-managed'
                    $active = $true
                } elseif ($top -like 'gstack*') {
                    $action = 'install-gstack'
                    $packageId = $script:GstackRepository
                    $packageVersion = $script:GstackCommit
                } else {
                    $action = 'reinstall-plugin'
                }
            } elseif ($source.Kind -eq 'plugin-cache') {
                $identity = Get-PluginCacheIdentity -SkillFile $skillFile.FullName -PluginCacheRoot $pluginCache
                $packageId = $identity.Plugin + '@' + $identity.Marketplace
                $packageVersion = $identity.Version
                $candidateIds = [System.Collections.Generic.List[string]]::new()
                $candidateIds.Add($identity.Plugin + '@' + $identity.Marketplace)
                $candidateIds.Add($identity.Plugin + '@' + ($identity.Marketplace -replace '-remote$', ''))
                $active = [bool]($candidateIds | Where-Object { $EnabledPlugins.Contains($_) -and $EnabledPlugins[$_] })
            }

            $items.Add([pscustomobject][ordered]@{
                name = Get-SkillName $skillFile.FullName
                sourceKind = $source.Kind
                sourcePath = ConvertTo-SourceTokenPath $skillFile.FullName
                targetScope = $source.Scope
                packageId = $packageId
                versionOrCommit = $packageVersion
                sha256 = (Get-FileHash -LiteralPath $skillFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                restoreAction = $action
                active = $active
                vendoredPath = $vendorPath
            })
        }
    }

    $uniqueNames = @($items.name | Sort-Object -Unique)
    $duplicates = @($items | Group-Object name | Where-Object Count -gt 1 | Sort-Object Name | ForEach-Object {
        [pscustomobject][ordered]@{ name = $_.Name; count = $_.Count; sources = @($_.Group.sourcePath) }
    })
    $brokenCursorLinks = @()
    $cursorSkillRoot = Join-Path $CursorHome 'skills'
    if (Test-Path -LiteralPath $cursorSkillRoot) {
        $brokenCursorLinks = @(Get-ChildItem -LiteralPath $cursorSkillRoot -Force | Where-Object {
            $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint -and -not (Test-Path -LiteralPath ([string]$_.Target))
        } | Sort-Object Name | ForEach-Object {
            [pscustomobject][ordered]@{
                name = $_.Name
                linkPath = ConvertTo-SourceTokenPath $_.FullName
                targetPath = ConvertTo-SourceTokenPath ([string]$_.Target)
                restored = $false
            }
        })
    }
    $document = [ordered]@{
        schemaVersion = 1
        generatedAtUtc = [DateTime]::UtcNow.ToString('o')
        precedence = @('workspace', 'codex-global', 'plugin', 'cursor-global', 'archived')
        summary = [ordered]@{
            totalInstances = $items.Count
            uniqueNames = $uniqueNames.Count
            duplicateNames = $duplicates.Count
            activePluginSkillInstances = @($items | Where-Object { $_.sourceKind -eq 'plugin-cache' -and $_.active }).Count
            brokenCursorLinks = $brokenCursorLinks.Count
        }
        duplicates = $duplicates
        brokenLinks = $brokenCursorLinks
        skills = @($items | Sort-Object name, sourceKind, sourcePath)
    }
    Write-Utf8File -Path $Destination -Content (($document | ConvertTo-Json -Depth 100) + [Environment]::NewLine)
}

function New-PluginInventory {
    param(
        [Parameter(Mandatory)][hashtable]$EnabledPlugins,
        [Parameter(Mandatory)][string]$Destination
    )

    $cacheRoot = Join-Path $CodexHome 'plugins\cache'
    $authPlugins = @('github@openai-curated', 'linear@openai-curated', 'notion@openai-curated', 'zotero@openai-curated', 'binance@openai-curated')
    $plugins = foreach ($id in $EnabledPlugins.Keys | Sort-Object) {
        $parts = $id -split '@', 2
        $plugin = $parts[0]
        $marketplace = if ($parts.Count -gt 1) { $parts[1] } else { 'unknown' }
        $versionRoots = @(
            (Join-Path $cacheRoot (Join-Path $marketplace $plugin)),
            (Join-Path $cacheRoot (Join-Path ($marketplace + '-remote') $plugin))
        )
        $versions = @($versionRoots | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object {
            Get-ChildItem -LiteralPath $_ -Directory -Force | Select-Object -ExpandProperty Name
        } | Sort-Object -Unique)
        [ordered]@{
            id = $id
            marketplace = $marketplace
            enabled = [bool]$EnabledPlugins[$id]
            observedVersions = $versions
            installCommand = "codex plugin add $id"
            requiresAuthentication = ($id -in $authPlugins)
        }
    }

    $document = [ordered]@{
        schemaVersion = 1
        generatedAtUtc = [DateTime]::UtcNow.ToString('o')
        activePluginCount = @($plugins | Where-Object enabled).Count
        plugins = @($plugins)
        externalSources = @(
            [ordered]@{
                name = 'gstack'
                repository = $script:GstackRepository
                commit = $script:GstackCommit
                installTarget = '{{USER_PROFILE}}/.gstack/repos/gstack'
                setup = 'Git Bash: bash ./setup'
            }
        )
        reauthentication = @('GitHub', 'Notion', 'Linear', 'Zotero', 'Binance')
    }
    Write-Utf8File -Path $Destination -Content (($document | ConvertTo-Json -Depth 100) + [Environment]::NewLine)
}

function New-FileHashManifest {
    param([Parameter(Mandatory)][string]$Destination)
    $files = foreach ($file in Get-ChildItem -LiteralPath $script:BuildRoot -Recurse -File -Force) {
        $relative = [System.IO.Path]::GetRelativePath($script:BuildRoot, $file.FullName) -replace '\\', '/'
        if ($relative -eq 'manifests/files.sha256.json' -or $relative -like '.git/*') {
            continue
        }
        [ordered]@{
            path = $relative
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            size = $file.Length
        }
    }
    $document = [ordered]@{
        schemaVersion = 1
        generatedAtUtc = [DateTime]::UtcNow.ToString('o')
        fileCount = @($files).Count
        files = @($files | Sort-Object path)
    }
    Write-Utf8File -Path $Destination -Content (($document | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
}

$WorkspaceRoot = Get-NormalizedFullPath $WorkspaceRoot
$CodexHome = Get-NormalizedFullPath $CodexHome
$CursorHome = Get-NormalizedFullPath $CursorHome
$RepositoryRoot = Get-NormalizedFullPath $RepositoryRoot

foreach ($required in @(
    $WorkspaceRoot,
    (Join-Path $WorkspaceRoot 'skills'),
    $CodexHome,
    (Join-Path $CodexHome 'skills'),
    (Join-Path $CodexHome 'plugins\cache'),
    (Join-Path $CodexHome 'config.toml'),
    (Join-Path $RepositoryRoot 'README.md'),
    (Join-Path $RepositoryRoot 'scripts\Update-Backup.ps1'),
    (Join-Path $RepositoryRoot 'scripts\Test-Backup.ps1')
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required source or repository sentinel not found: $required"
    }
}

$repoItem = Get-Item -LiteralPath $RepositoryRoot -Force
if ($repoItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw "Repository root must not be a junction or symbolic link: $RepositoryRoot"
}
$dangerousRoots = @(
    [System.IO.Path]::GetPathRoot($RepositoryRoot),
    (Get-NormalizedFullPath $env:USERPROFILE),
    $WorkspaceRoot,
    $CodexHome,
    $CursorHome
) | Sort-Object -Unique
if ($RepositoryRoot -in $dangerousRoots -or (Split-Path $RepositoryRoot -Leaf) -ne 'codex-workstation-backup') {
    throw "Unsafe or unexpected repository root: $RepositoryRoot"
}

foreach ($jsonSource in @(
    (Join-Path $WorkspaceRoot '.cursor\settings.json'),
    (Join-Path $WorkspaceRoot '.cursor\mcp.json'),
    (Join-Path $WorkspaceRoot '.claude\settings.local.json'),
    (Join-Path $WorkspaceRoot 'mcp\cursor.mcp.json')
) | Where-Object { Test-Path -LiteralPath $_ }) {
    $null = Get-Content -LiteralPath $jsonSource -Raw | ConvertFrom-Json -AsHashtable
}
$enabledPlugins = Get-EnabledPlugins (Join-Path $CodexHome 'config.toml')

$plannedRestoreTargets = @(
    (Join-Path $WorkspaceRoot 'skills'),
    (Join-Path $WorkspaceRoot 'mcp'),
    (Join-Path $CodexHome 'skills'),
    (Join-Path $CursorHome 'skills')
)
foreach ($target in $plannedRestoreTargets) {
    $targetFull = Get-NormalizedFullPath $target
    if ($RepositoryRoot -eq $targetFull -or
        $RepositoryRoot.StartsWith($targetFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $targetFull.StartsWith($RepositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Repository and restore target must be disjoint: $targetFull"
    }
}

if (-not $PSCmdlet.ShouldProcess($RepositoryRoot, 'Build, validate, and atomically replace the generated backup snapshot')) {
    return
}

$repositoryParent = Split-Path -Parent $RepositoryRoot
$operationId = [guid]::NewGuid().ToString('N')
$script:BuildRoot = Join-Path $repositoryParent ('.codex-workstation-backup-stage-' + $operationId)
$previousRoot = Join-Path $repositoryParent ('.codex-workstation-backup-previous-' + $operationId)
$swapNames = @('skills', 'config', 'mcp', 'manifests')
$swapComplete = $false

function Remove-SafeOperationTree {
    param([Parameter(Mandatory)][string]$Path)
    $full = Get-NormalizedFullPath $Path
    $parent = Get-NormalizedFullPath (Split-Path -Parent $full)
    $leaf = Split-Path $full -Leaf
    if ($parent -ne (Get-NormalizedFullPath $repositoryParent) -or $leaf -notmatch '^\.codex-workstation-backup-(stage|previous)-[a-f0-9]{32}$') {
        throw "Refusing to remove an unexpected operation path: $full"
    }
    if (Test-Path -LiteralPath $full) {
        Remove-Item -LiteralPath $full -Recurse -Force
    }
}

try {
    New-Item -ItemType Directory -Path $script:BuildRoot -Force | Out-Null
    foreach ($staticFile in @('.gitignore', '.gitattributes', 'README.md')) {
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot $staticFile) -Destination (Join-Path $script:BuildRoot $staticFile) -Force
    }
    Copy-FilteredTree -Source (Join-Path $RepositoryRoot '.github') -Destination (Join-Path $script:BuildRoot '.github')
    Copy-FilteredTree -Source (Join-Path $RepositoryRoot 'scripts') -Destination (Join-Path $script:BuildRoot 'scripts')

    foreach ($root in $swapNames | ForEach-Object { Join-Path $script:BuildRoot $_ }) {
        Reset-GeneratedDirectory $root
    }

    Copy-FilteredTree -Source (Join-Path $WorkspaceRoot 'skills') -Destination (Join-Path $script:BuildRoot 'skills\workspace') -PortableText
    foreach ($skillDirectory in Get-ChildItem -LiteralPath (Join-Path $CodexHome 'skills') -Directory -Force) {
        if ((Test-CustomCodexGlobalSkill $skillDirectory.Name) -and @(Get-ChildItem -LiteralPath $skillDirectory.FullName -Recurse -Filter 'SKILL.md' -File -Force).Count -gt 0) {
            Copy-FilteredTree -Source $skillDirectory.FullName -Destination (Join-Path $script:BuildRoot ('skills\codex-global\' + $skillDirectory.Name)) -PortableText
        }
    }
    if (Test-Path -LiteralPath (Join-Path $CursorHome 'skills')) {
        Copy-FilteredTree -Source (Join-Path $CursorHome 'skills') -Destination (Join-Path $script:BuildRoot 'skills\cursor-global') -PortableText
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.agents\archived-skills')) {
        Copy-FilteredTree -Source (Join-Path $WorkspaceRoot '.agents\archived-skills') -Destination (Join-Path $script:BuildRoot 'skills\archived') -PortableText
    }

    $workspaceConfigRoot = Join-Path $script:BuildRoot 'config\workspace'
    foreach ($name in @('AGENTS.md', 'CLAUDE.md', 'GEMINI.md')) {
        $source = Join-Path $WorkspaceRoot $name
        if (Test-Path -LiteralPath $source) {
            Copy-PortableTextFile -Source $source -Destination (Join-Path $workspaceConfigRoot $name)
        }
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot 'scripts')) {
        Copy-FilteredTree -Source (Join-Path $WorkspaceRoot 'scripts') -Destination (Join-Path $workspaceConfigRoot 'scripts') -PortableText
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.agents\scripts')) {
        Copy-FilteredTree -Source (Join-Path $WorkspaceRoot '.agents\scripts') -Destination (Join-Path $workspaceConfigRoot '.agents\scripts') -PortableText
    }
    foreach ($relative in @('.agents\README.md', '.agents\skill-check.ps1', '.agents\skill-check.cmd')) {
        $source = Join-Path $WorkspaceRoot $relative
        if (Test-Path -LiteralPath $source) {
            Copy-PortableTextFile -Source $source -Destination (Join-Path $workspaceConfigRoot $relative)
        }
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.cursor\rules')) {
        Copy-FilteredTree -Source (Join-Path $WorkspaceRoot '.cursor\rules') -Destination (Join-Path $workspaceConfigRoot '.cursor\rules') -PortableText
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.cursor\settings.json')) {
        New-SanitizedJsonTemplate -Source (Join-Path $WorkspaceRoot '.cursor\settings.json') -Destination (Join-Path $workspaceConfigRoot '.cursor\settings.template.json')
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.cursor\mcp.json')) {
        New-SanitizedJsonTemplate -Source (Join-Path $WorkspaceRoot '.cursor\mcp.json') -Destination (Join-Path $workspaceConfigRoot '.cursor\mcp.template.json')
    }
    if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.claude\settings.local.json')) {
        New-ClaudeSettingsTemplates -Source (Join-Path $WorkspaceRoot '.claude\settings.local.json') `
            -SafeDestination (Join-Path $workspaceConfigRoot '.claude\settings.local.template.json') `
            -PrivilegedDestination (Join-Path $workspaceConfigRoot '.claude\settings.local.privileged.template.json')
    }

    $privilegedCodexTemplate = Join-Path $script:BuildRoot 'config\codex\config.privileged.template.toml'
    New-SanitizedCodexConfig -Source (Join-Path $CodexHome 'config.toml') -Destination $privilegedCodexTemplate
    New-SafeCodexConfig -PrivilegedTemplate $privilegedCodexTemplate -Destination (Join-Path $script:BuildRoot 'config\codex\config.template.toml')

    $sourceMcp = Join-Path $WorkspaceRoot 'mcp'
    if (Test-Path -LiteralPath (Join-Path $sourceMcp 'hwp-mcp')) {
        Copy-FilteredTree -Source (Join-Path $sourceMcp 'hwp-mcp') -Destination (Join-Path $script:BuildRoot 'mcp\hwp-mcp') -PortableText
    }
    foreach ($name in @('README.md', 'sync-cursor-mcp.ps1')) {
        $source = Join-Path $sourceMcp $name
        if (Test-Path -LiteralPath $source) {
            Copy-PortableTextFile -Source $source -Destination (Join-Path $script:BuildRoot ('mcp\' + $name))
        }
    }
    if (Test-Path -LiteralPath (Join-Path $sourceMcp 'cursor.mcp.json')) {
        New-SanitizedJsonTemplate -Source (Join-Path $sourceMcp 'cursor.mcp.json') -Destination (Join-Path $script:BuildRoot 'mcp\cursor.mcp.template.json')
    }

    New-SkillInventory -EnabledPlugins $enabledPlugins -Destination (Join-Path $script:BuildRoot 'manifests\skills.lock.json')
    New-PluginInventory -EnabledPlugins $enabledPlugins -Destination (Join-Path $script:BuildRoot 'manifests\plugins.lock.json')
    New-FileHashManifest -Destination (Join-Path $script:BuildRoot 'manifests\files.sha256.json')

    & (Join-Path $script:BuildRoot 'scripts\Test-Backup.ps1') -RepositoryRoot $script:BuildRoot -SkipRestoreTest

    New-Item -ItemType Directory -Path $previousRoot -Force | Out-Null
    $movedOld = [System.Collections.Generic.List[string]]::new()
    $movedNew = [System.Collections.Generic.List[string]]::new()
    try {
        foreach ($name in $swapNames) {
            $current = Join-Path $RepositoryRoot $name
            $previous = Join-Path $previousRoot $name
            if (Test-Path -LiteralPath $current) {
                $item = Get-Item -LiteralPath $current -Force
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    throw "Refusing to replace a reparse-point snapshot directory: $current"
                }
                Move-Item -LiteralPath $current -Destination $previous
                $movedOld.Add($name)
            }
            Move-Item -LiteralPath (Join-Path $script:BuildRoot $name) -Destination $current
            $movedNew.Add($name)
        }
        & (Join-Path $RepositoryRoot 'scripts\Test-Backup.ps1') -RepositoryRoot $RepositoryRoot -SkipRestoreTest
        $swapComplete = $true
    } catch {
        for ($index = $movedNew.Count - 1; $index -ge 0; $index--) {
            $name = $movedNew[$index]
            $current = Join-Path $RepositoryRoot $name
            if (Test-Path -LiteralPath $current) {
                Remove-Item -LiteralPath $current -Recurse -Force
            }
        }
        for ($index = $movedOld.Count - 1; $index -ge 0; $index--) {
            $name = $movedOld[$index]
            $current = Join-Path $RepositoryRoot $name
            $previous = Join-Path $previousRoot $name
            if (Test-Path -LiteralPath $previous) {
                Move-Item -LiteralPath $previous -Destination $current
            }
        }
        throw
    }
} finally {
    if ($swapComplete -and (Test-Path -LiteralPath $previousRoot)) {
        Remove-SafeOperationTree $previousRoot
    }
    if (Test-Path -LiteralPath $script:BuildRoot) {
        Remove-SafeOperationTree $script:BuildRoot
    }
}

$skillManifest = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'manifests\skills.lock.json') -Raw | ConvertFrom-Json
$pluginManifest = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'manifests\plugins.lock.json') -Raw | ConvertFrom-Json
Write-Host "Backup snapshot updated."
Write-Host ("  Skill instances : {0}" -f $skillManifest.summary.totalInstances)
Write-Host ("  Unique names    : {0}" -f $skillManifest.summary.uniqueNames)
Write-Host ("  Duplicate names : {0}" -f $skillManifest.summary.duplicateNames)
Write-Host ("  Active plugins  : {0}" -f $pluginManifest.activePluginCount)
