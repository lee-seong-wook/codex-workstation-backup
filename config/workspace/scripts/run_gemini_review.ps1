[CmdletBinding()]
param(
    [string]$Prompt,
    [string]$PromptFile
)

$gemini = "{{USER_PROFILE}}\AppData\Roaming\npm\gemini.ps1"
if (-not (Test-Path -LiteralPath $gemini)) {
    throw "Gemini CLI wrapper not found at $gemini"
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

$ReviewModel = "gemini-3.5-flash"

& $gemini --prompt $payload --model $ReviewModel --approval-mode yolo --output-format text
