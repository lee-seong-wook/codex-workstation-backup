[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$ExpectedSkillInstances = 243,
    [int]$ExpectedUniqueSkillNames = 214,
    [int]$ExpectedDuplicateSkillNames = 22,
    [int]$ExpectedActivePlugins = 21,
    [switch]$SkipRestoreTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) {
        $script:Failures.Add($Message)
        Write-Host "FAIL: $Message" -ForegroundColor Red
    } else {
        Write-Host "PASS: $Message" -ForegroundColor Green
    }
}

function Get-RepositoryFiles {
    Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Force | Where-Object {
        [System.IO.Path]::GetRelativePath($RepositoryRoot, $_.FullName) -notlike '.git\*'
    }
}

$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
$skillLockPath = Join-Path $RepositoryRoot 'manifests\skills.lock.json'
$pluginLockPath = Join-Path $RepositoryRoot 'manifests\plugins.lock.json'
$hashLockPath = Join-Path $RepositoryRoot 'manifests\files.sha256.json'

foreach ($required in @($skillLockPath, $pluginLockPath, $hashLockPath)) {
    Assert-True (Test-Path -LiteralPath $required -PathType Leaf) "Required manifest exists: $required"
}
if ($script:Failures.Count -gt 0) {
    throw ($script:Failures -join [Environment]::NewLine)
}

$skills = Get-Content -LiteralPath $skillLockPath -Raw | ConvertFrom-Json
$plugins = Get-Content -LiteralPath $pluginLockPath -Raw | ConvertFrom-Json
$hashes = Get-Content -LiteralPath $hashLockPath -Raw | ConvertFrom-Json

Assert-True ($skills.summary.totalInstances -eq $ExpectedSkillInstances) "Skill instance count is $ExpectedSkillInstances"
Assert-True ($skills.summary.uniqueNames -eq $ExpectedUniqueSkillNames) "Unique skill name count is $ExpectedUniqueSkillNames"
Assert-True ($skills.summary.duplicateNames -eq $ExpectedDuplicateSkillNames) "Duplicate skill name count is $ExpectedDuplicateSkillNames"
$computedUnique = @($skills.skills.name | Sort-Object -Unique).Count
$computedDuplicates = @($skills.skills | Group-Object name | Where-Object Count -gt 1).Count
Assert-True (@($skills.skills).Count -eq $skills.summary.totalInstances) 'Skill summary total is recomputed from skills[]'
Assert-True ($computedUnique -eq $skills.summary.uniqueNames) 'Skill summary unique count is recomputed from skills[]'
Assert-True ($computedDuplicates -eq $skills.summary.duplicateNames) 'Skill summary duplicate count is recomputed from skills[]'
Assert-True (@($skills.skills | Where-Object restoreAction -eq 'copy').Count -eq 96) 'Directly restorable skill count is 96'
Assert-True ($skills.summary.brokenCursorLinks -eq 10) 'Ten broken Cursor skill junctions are recorded but not restored'
$activePluginSkills = @($skills.skills | Where-Object { $_.sourceKind -eq 'plugin-cache' -and $_.active })
Assert-True ($activePluginSkills.Count -eq $skills.summary.activePluginSkillInstances) 'Active plugin skill count matches the skill summary'
Assert-True ($activePluginSkills.Count -gt 0) 'Enabled plugin packages mark their cached skill instances active'
Assert-True ($plugins.activePluginCount -eq $ExpectedActivePlugins) "Active plugin count is $ExpectedActivePlugins"
$gstack = $plugins.externalSources | Where-Object name -eq 'gstack' | Select-Object -First 1
Assert-True ($null -ne $gstack) 'gstack lock entry exists'
if ($gstack) {
    Assert-True ($gstack.commit -eq 'db9447c3339950bb0506c547e5b3225f5def3854') 'gstack commit matches the pinned source revision'
}

$hashFailures = [System.Collections.Generic.List[string]]::new()
$manifestPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $hashes.files) {
    $relative = ([string]$entry.path).Replace('\', '/')
    if ([System.IO.Path]::IsPathRooted($relative) -or @($relative -split '/' | Where-Object { $_ -eq '..' }).Count -gt 0) {
        $hashFailures.Add("Unsafe path: $relative")
        continue
    }
    if (-not $manifestPaths.Add($relative)) {
        $hashFailures.Add("Duplicate path: $relative")
        continue
    }
    $path = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    if (-not $path.StartsWith($RepositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        $hashFailures.Add("Escaping path: $relative")
        continue
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $hashFailures.Add("Missing: $relative")
        continue
    }
    $file = Get-Item -LiteralPath $path -Force
    if ($file.Length -ne [int64]$entry.size) {
        $hashFailures.Add("Size mismatch: $relative")
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $entry.sha256) {
        $hashFailures.Add("Hash mismatch: $relative")
    }
}
$actualPaths = @(Get-RepositoryFiles | ForEach-Object {
    $relative = [System.IO.Path]::GetRelativePath($RepositoryRoot, $_.FullName).Replace('\', '/')
    if ($relative -ne 'manifests/files.sha256.json') { $relative }
})
$unmanifested = @($actualPaths | Where-Object { -not $manifestPaths.Contains($_) })
Assert-True ($hashes.fileCount -eq $manifestPaths.Count) 'Hash manifest fileCount matches its unique path count'
Assert-True ($actualPaths.Count -eq $manifestPaths.Count) 'Disk and hash manifest contain the same number of files'
Assert-True ($unmanifested.Count -eq 0) 'No unmanifested files are present in the repository'
if ($unmanifested.Count -gt 0) { $unmanifested | ForEach-Object { $hashFailures.Add("Unmanifested: $_") } }
Assert-True ($hashFailures.Count -eq 0) 'All vendored file sizes and hashes match the exact lock manifest'
if ($hashFailures.Count -gt 0) {
    $hashFailures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

$forbidden = [System.Collections.Generic.List[string]]::new()
$secretHits = [System.Collections.Generic.List[string]]::new()
$binaryExtensions = @('.pdf', '.dll', '.png', '.jpg', '.jpeg', '.gif', '.exe')
$secretPatterns = @(
    '(?i)github_pat_[A-Za-z0-9_]{20,}',
    '(?i)gh[pousr]_[A-Za-z0-9]{30,}',
    '(?i)sk-(?:proj-)?[A-Za-z0-9_-]{24,}',
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
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
foreach ($file in Get-RepositoryFiles) {
    $relative = [System.IO.Path]::GetRelativePath($RepositoryRoot, $file.FullName) -replace '\\', '/'
    $name = $file.Name
    if ($relative -ne '.gitignore' -and (
        $name -in @('auth.json', '.npmrc', '.pypirc', '.netrc') -or
        $name -match '(?i)(credential|secret|^\.env(?:\..+)?$|\.log$|\.pyc$|\.sqlite(?:-.+)?$|\.db(?:-.+)?$|\.wal$|\.(pem|key|pfx|p12)$)' -or
        $relative -match '(?i)(^|/)(__pycache__|node_modules|cache|sessions|cookies|\.ssh)/'
    )) {
        $forbidden.Add($relative)
    }
    if ($file.Extension.ToLowerInvariant() -in $binaryExtensions) {
        continue
    }
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($text -match $pattern) {
            $secretHits.Add("$relative :: $pattern")
        }
    }
}
Assert-True ($forbidden.Count -eq 0) 'No forbidden runtime, credential, cache, or log files are present'
Assert-True ($secretHits.Count -eq 0) 'No high-confidence credentials or private keys are present'
if ($forbidden.Count -gt 0) { $forbidden | ForEach-Object { Write-Host "  $_" -ForegroundColor Red } }
if ($secretHits.Count -gt 0) { $secretHits | ForEach-Object { Write-Host "  $_" -ForegroundColor Red } }

$portableTextFiles = @(Get-RepositoryFiles | Where-Object { $_.Extension.ToLowerInvariant() -notin $binaryExtensions })
$absolutePathHits = @($portableTextFiles | Select-String -Pattern '(?i)(C:[\\/]+Users[\\/]+user(?:[\\/]|$)|/{1,2}c/Users/user(?:/|$)|C--Users-user(?:-|$))' -List)
Assert-True ($absolutePathHits.Count -eq 0) 'Portable repository files contain no original Windows, MSYS, or encoded user path'

$jsonFiles = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -Filter '*.json' -File -Force)
$jsonErrors = [System.Collections.Generic.List[string]]::new()
foreach ($jsonFile in $jsonFiles) {
    try {
        $null = Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json
    } catch {
        $jsonErrors.Add($jsonFile.FullName)
    }
}
Assert-True ($jsonErrors.Count -eq 0) 'All JSON files parse successfully'
$cursorTemplate = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config\workspace\.cursor\mcp.template.json') -Raw | ConvertFrom-Json
Assert-True ($cursorTemplate.mcpServers.playwright.args -is [System.Array]) 'Cursor Playwright args remains an array after sanitization'
Assert-True ($cursorTemplate.mcpServers.filesystem.args -is [System.Array]) 'Cursor filesystem args remains an array after sanitization'

$safeCodexText = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config\codex\config.template.toml') -Raw
$privilegedCodexText = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'config\codex\config.privileged.template.toml') -Raw
Assert-True ($safeCodexText -match '(?m)^approval_policy = "on-request"\r?$' -and $safeCodexText -match '(?m)^sandbox_mode = "workspace-write"\r?$' -and $safeCodexText -match '(?m)^trust_level = "untrusted"\r?$') 'Default Codex template uses restricted approval, sandbox, and trust settings'
Assert-True ($privilegedCodexText -match '(?m)^approval_policy = "never"\r?$' -and $privilegedCodexText -match '(?m)^sandbox_mode = "danger-full-access"\r?$') 'Original privileged Codex policy is retained only in the opt-in template'

$python = Get-Command python -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue | Select-Object -First 1
}
Assert-True ($null -ne $python) 'Python is available for TOML syntax validation'
if ($python) {
    foreach ($tomlPath in @(
        (Join-Path $RepositoryRoot 'config\codex\config.template.toml'),
        (Join-Path $RepositoryRoot 'config\codex\config.privileged.template.toml')
    )) {
        if ($python.Name -eq 'py.exe' -or $python.Name -eq 'py') {
            & $python.Source -3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' $tomlPath
        } else {
            & $python.Source -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' $tomlPath
        }
        Assert-True ($LASTEXITCODE -eq 0) "Codex TOML template parses successfully: $([System.IO.Path]::GetFileName($tomlPath))"
    }
}

if (-not $SkipRestoreTest) {
    $tempBase = [System.IO.Path]::GetTempPath()
    $testRoot = Join-Path $tempBase ('codex-workstation-backup-test-' + [guid]::NewGuid().ToString('N'))
    $testWorkspace = Join-Path $testRoot 'workspace'
    $testCodex = Join-Path $testRoot 'codex-home'
    $testCursor = Join-Path $testRoot 'cursor-home'
    try {
        $restore = Join-Path $RepositoryRoot 'scripts\Restore-Setup.ps1'
        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -WhatIf -Confirm:$false
        Assert-True (-not (Test-Path -LiteralPath $testRoot)) 'Restore -WhatIf performs no writes to any restore root'

        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -Confirm:$false
        Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $testWorkspace 'skills') -Recurse -Filter 'SKILL.md' -File).Count -eq 81) 'Temporary restore contains 81 workspace skills'
        Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $testCodex 'skills') -Recurse -Filter 'SKILL.md' -File).Count -eq 2) 'Temporary restore contains 2 custom Codex-global skills'
        Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $testCursor 'skills') -Recurse -Filter 'SKILL.md' -File).Count -eq 12) 'Temporary restore contains 12 Cursor-global skills'
        Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $testWorkspace '.agents\archived-skills') -Recurse -Filter 'SKILL.md' -File).Count -eq 1) 'Temporary restore contains 1 archived skill'
        Assert-True (Test-Path -LiteralPath (Join-Path $testCodex 'config.toml')) 'Temporary restore renders Codex config.toml'
        $renderedSafeConfig = Get-Content -LiteralPath (Join-Path $testCodex 'config.toml') -Raw
        Assert-True ($renderedSafeConfig -match '(?m)^approval_policy = "on-request"\r?$' -and $renderedSafeConfig -match '(?m)^sandbox_mode = "workspace-write"\r?$' -and $renderedSafeConfig -match '(?m)^trust_level = "untrusted"\r?$') 'Default restore applies restricted Codex approval, sandbox, and trust policy'
        if ($python.Name -eq 'py.exe' -or $python.Name -eq 'py') {
            & $python.Source -3 -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' (Join-Path $testCodex 'config.toml')
        } else {
            & $python.Source -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' (Join-Path $testCodex 'config.toml')
        }
        Assert-True ($LASTEXITCODE -eq 0) 'Rendered Codex config.toml parses successfully'

        $beforeSnapshot = @(Get-ChildItem -LiteralPath $testRoot -Recurse -File -Force | ForEach-Object {
            $relative = [System.IO.Path]::GetRelativePath($testRoot, $_.FullName).Replace('\', '/')
            "$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
        } | Sort-Object)
        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -Confirm:$false
        $afterSnapshot = @(Get-ChildItem -LiteralPath $testRoot -Recurse -File -Force | ForEach-Object {
            $relative = [System.IO.Path]::GetRelativePath($testRoot, $_.FullName).Replace('\', '/')
            "$relative|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
        } | Sort-Object)
        Assert-True (($beforeSnapshot -join "`n") -eq ($afterSnapshot -join "`n")) 'Repeated restore without -Force preserves the complete restored file set'

        Add-Content -LiteralPath (Join-Path $testCodex 'config.toml') -Value '# restore-force-marker'
        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -Force -WhatIf -Confirm:$false
        Assert-True ((Get-Content -LiteralPath (Join-Path $testCodex 'config.toml') -Raw) -match 'restore-force-marker') 'Restore -Force -WhatIf leaves existing content untouched'
        Assert-True (@(Get-ChildItem -LiteralPath $testRoot -Recurse -Filter '*.backup-*' -Force).Count -eq 0) 'Restore -Force -WhatIf creates no backup artifacts'
        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -Force -Confirm:$false
        $configBackups = @(Get-ChildItem -LiteralPath $testCodex -Filter 'config.toml.backup-*' -File)
        Assert-True ($configBackups.Count -eq 1) 'Restore -Force creates a timestamped backup of existing config'
        if ($configBackups.Count -eq 1) {
            Assert-True ((Get-Content -LiteralPath $configBackups[0].FullName -Raw) -match 'restore-force-marker') 'The timestamped backup preserves the previous config content'
        }
        Assert-True ((Get-Content -LiteralPath (Join-Path $testCodex 'config.toml') -Raw) -notmatch 'restore-force-marker') 'Restore -Force installs a clean rendered config after backup'

        & $restore -WorkspaceRoot $testWorkspace -CodexHome $testCodex -CursorHome $testCursor -RepositoryRoot $RepositoryRoot -SkipPlugins -SkipGstack -Force -RestorePrivilegedPolicy -Confirm:$false
        $renderedPrivilegedConfig = Get-Content -LiteralPath (Join-Path $testCodex 'config.toml') -Raw
        Assert-True ($renderedPrivilegedConfig -match '(?m)^approval_policy = "never"\r?$' -and $renderedPrivilegedConfig -match '(?m)^sandbox_mode = "danger-full-access"\r?$') 'Opt-in restore reproduces the original privileged Codex policy'
        $renderedPrivilegedClaude = Get-Content -LiteralPath (Join-Path $testWorkspace '.claude\settings.local.json') -Raw | ConvertFrom-Json
        Assert-True (@($renderedPrivilegedClaude.permissions.allow | Where-Object { $_ -eq 'Bash(rm:*)' }).Count -eq 1) 'Opt-in restore reproduces sanitized privileged Claude permissions'
    } finally {
        $resolvedTemp = [System.IO.Path]::GetFullPath($tempBase).TrimEnd('\', '/')
        $resolvedTest = [System.IO.Path]::GetFullPath($testRoot).TrimEnd('\', '/')
        if ($resolvedTest.StartsWith($resolvedTemp + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path $resolvedTest -Leaf) -like 'codex-workstation-backup-test-*' -and
            (Test-Path -LiteralPath $resolvedTest)) {
            Remove-Item -LiteralPath $resolvedTest -Recurse -Force
        }
    }
}

if ($script:Failures.Count -gt 0) {
    Write-Host ''
    Write-Host ("Backup verification failed with {0} issue(s)." -f $script:Failures.Count) -ForegroundColor Red
    $script:Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw "Backup verification failed with $($script:Failures.Count) issue(s)."
}

Write-Host ''
Write-Host 'Backup verification passed.' -ForegroundColor Green
Write-Host ("  Skill instances : {0}" -f $skills.summary.totalInstances)
Write-Host ("  Unique names    : {0}" -f $skills.summary.uniqueNames)
Write-Host ("  Duplicate names : {0}" -f $skills.summary.duplicateNames)
Write-Host ("  Active plugins  : {0}" -f $plugins.activePluginCount)
