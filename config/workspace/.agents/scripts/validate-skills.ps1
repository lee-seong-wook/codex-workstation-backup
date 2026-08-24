param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\skills")).Path,
    [string]$ReportPath = "",
    [switch]$FailOnIssue
)

$ErrorActionPreference = "Stop"

function Get-FrontmatterValue {
    param(
        [string]$Frontmatter,
        [string]$Key
    )
    $escapedKey = [regex]::Escape($Key)
    $m = [regex]::Match($Frontmatter, "(?m)^${escapedKey}:\s*(.+?)\s*$")
    if (-not $m.Success) { return "" }
    return $m.Groups[1].Value.Trim("`"", "'", " ")
}

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Skills root does not exist: $Root"
}

$ignoredOutputBasenames = @(
    "analysis-report.md",
    "figure-catalog.md",
    "render.yaml",
    "prompt.txt",
    "remix_job.json",
    "security_best_practices_report.md",
    "stats-appendix.md",
    "requirements.txt"
)

$skillFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter SKILL.md |
    Where-Object { $_.FullName -notmatch "\\scripts\\" } |
    Sort-Object FullName

$rows = foreach ($file in $skillFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $dir = Split-Path $file.FullName -Parent

    $frontmatter = ""
    $hasFrontmatter = $false
    $fmMatch = [regex]::Match($text, "(?s)^---\s*(.*?)\s*---")
    if ($fmMatch.Success) {
        $hasFrontmatter = $true
        $frontmatter = $fmMatch.Groups[1].Value
    }

    $name = if ($hasFrontmatter) { Get-FrontmatterValue -Frontmatter $frontmatter -Key "name" } else { "" }
    $description = if ($hasFrontmatter) { Get-FrontmatterValue -Frontmatter $frontmatter -Key "description" } else { "" }

    $tokens = [regex]::Matches($text, '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value }
    $pathCandidates = $tokens | Where-Object {
        $_ -match "^(scripts|references|assets|templates|agents)/" -or
        $_ -match "^[A-Za-z0-9._-]+\.(md|txt|py|sh|ps1|json|yaml|yml)$"
    } | Sort-Object -Unique

    $missingRefs = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in $pathCandidates) {
        if ($candidate -match "^(https?|file)://") { continue }
        if ($candidate -match "^[A-Za-z]:[/\\]") { continue }
        if ($candidate -match "[<>|?*]") { continue }
        if ($candidate -match "\s") { continue }
        $baseName = [System.IO.Path]::GetFileName($candidate)
        if ($ignoredOutputBasenames -contains $baseName) { continue }

        $exists = $false
        $targetPath = Join-Path $dir $candidate
        if (Test-Path -LiteralPath $targetPath) {
            $exists = $true
        } elseif (-not ($candidate -match "[/\\]")) {
            # Many skills reference file basenames while files live under references/ or examples/.
            $hit = Get-ChildItem -LiteralPath $dir -Recurse -File -Filter $candidate -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($null -ne $hit) {
                $exists = $true
            }
        }

        if (-not $exists) {
            $missingRefs.Add($candidate)
        }
    }

    $deprecatedRefs = [regex]::Matches($text, "superpowers:[a-z0-9-]+") |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique

    $issueCount = 0
    if (-not $hasFrontmatter) { $issueCount++ }
    if ([string]::IsNullOrWhiteSpace($name)) { $issueCount++ }
    if ([string]::IsNullOrWhiteSpace($description)) { $issueCount++ }
    $issueCount += $missingRefs.Count
    $issueCount += $deprecatedRefs.Count

    [pscustomobject]@{
        Skill = if ([string]::IsNullOrWhiteSpace($name)) { Split-Path $dir -Leaf } else { $name }
        File = $file.FullName
        HasFrontmatter = $hasFrontmatter
        HasName = -not [string]::IsNullOrWhiteSpace($name)
        HasDescription = -not [string]::IsNullOrWhiteSpace($description)
        MissingRefCount = $missingRefs.Count
        MissingRefs = ($missingRefs -join ", ")
        DeprecatedRefCount = $deprecatedRefs.Count
        DeprecatedRefs = ($deprecatedRefs -join ", ")
        IssueCount = $issueCount
    }
}

$summary = [pscustomobject]@{
    TotalSkills = $rows.Count
    MissingFrontmatter = ($rows | Where-Object { -not $_.HasFrontmatter }).Count
    MissingName = ($rows | Where-Object { -not $_.HasName }).Count
    MissingDescription = ($rows | Where-Object { -not $_.HasDescription }).Count
    SkillsWithMissingRefs = ($rows | Where-Object { $_.MissingRefCount -gt 0 }).Count
    SkillsWithDeprecatedRefs = ($rows | Where-Object { $_.DeprecatedRefCount -gt 0 }).Count
    SkillsWithIssues = ($rows | Where-Object { $_.IssueCount -gt 0 }).Count
}

Write-Output "TOTAL_SKILLS=$($summary.TotalSkills)"
Write-Output "MISSING_FRONTMATTER=$($summary.MissingFrontmatter)"
Write-Output "MISSING_NAME=$($summary.MissingName)"
Write-Output "MISSING_DESCRIPTION=$($summary.MissingDescription)"
Write-Output "SKILLS_WITH_MISSING_REFS=$($summary.SkillsWithMissingRefs)"
Write-Output "SKILLS_WITH_DEPRECATED_REFS=$($summary.SkillsWithDeprecatedRefs)"
Write-Output "SKILLS_WITH_ISSUES=$($summary.SkillsWithIssues)"

$issueRows = $rows |
    Where-Object { $_.IssueCount -gt 0 } |
    Sort-Object @{Expression = "IssueCount"; Descending = $true}, Skill
foreach ($r in $issueRows) {
    Write-Output ("ISSUE|{0}|missingRefs={1}|deprecatedRefs={2}|file={3}" -f `
        $r.Skill, $r.MissingRefCount, $r.DeprecatedRefCount, $r.File)
}

if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportLines = @()
    $reportLines += "# Skill Validation Report"
    $reportLines += ""
    $reportLines += ('- Root: `' + $Root + '`')
    $reportLines += "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $reportLines += ""
    $reportLines += "## Summary"
    $reportLines += ""
    $reportLines += "| Metric | Value |"
    $reportLines += "|---|---:|"
    $reportLines += "| Total skills | $($summary.TotalSkills) |"
    $reportLines += "| Missing frontmatter | $($summary.MissingFrontmatter) |"
    $reportLines += "| Missing name | $($summary.MissingName) |"
    $reportLines += "| Missing description | $($summary.MissingDescription) |"
    $reportLines += "| Skills with missing refs | $($summary.SkillsWithMissingRefs) |"
    $reportLines += "| Skills with deprecated refs | $($summary.SkillsWithDeprecatedRefs) |"
    $reportLines += "| Skills with any issue | $($summary.SkillsWithIssues) |"
    $reportLines += ""

    if ($issueRows.Count -gt 0) {
        $reportLines += "## Issues"
        $reportLines += ""
        $reportLines += "| Skill | Missing Refs | Deprecated Refs | File |"
        $reportLines += "|---|---:|---:|---|"
        foreach ($r in $issueRows) {
            $reportLines += "| $($r.Skill) | $($r.MissingRefCount) | $($r.DeprecatedRefCount) | `$($r.File)` |"
        }
    } else {
        $reportLines += "## Issues"
        $reportLines += ""
        $reportLines += "No issues found."
    }

    $reportDir = Split-Path -Parent $ReportPath
    if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    Set-Content -LiteralPath $ReportPath -Value ($reportLines -join "`r`n")
    Write-Output "REPORT_WRITTEN=$ReportPath"
}

if ($FailOnIssue -and $summary.SkillsWithIssues -gt 0) {
    exit 1
}
