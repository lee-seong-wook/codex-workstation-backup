[CmdletBinding()]
param(
    [string]$Prompt,
    [string]$PromptFile
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

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

$ClaudeReviewModel = "opus5"

$GeminiReviewModel = "gemini-3.5-flash"

Write-Host "===== Gemini skeptical review ====="
& (Join-Path $scriptRoot "run_gemini_review.ps1") -Prompt $payload

Write-Host ""
Write-Host "===== Claude lead review ====="
& (Join-Path $scriptRoot "run_claude_review.ps1") -Prompt $payload
