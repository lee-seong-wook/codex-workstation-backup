---
name: media-tools
description: Route and execute media-generation and audio workflows including text-to-speech, voiceover, narration audio, transcription, diarization, audio-to-text, Sora/video generation, and video remix requests. Use for "TTS", "voiceover", "transcribe", "diarization", "Sora", "generate video", "영상 생성", "음성 합성", and "전사".
---

# Media Tools

## Workflow

1. Classify the request: TTS/voiceover, transcription/diarization, or video generation/remix.
2. Search for the relevant installed tool or connector with `tool_search` before giving manual instructions.
3. If a required media tool is unavailable, state that clearly and ask for the source file, target format, or connector setup rather than inventing output.
4. Preserve source filenames and report generated output paths.

## Routing

- TTS/voiceover: use the AI Voice Generator tool when available. Confirm language, voice/style, script text, and output format if missing.
- Transcription/diarization: use an installed transcription connector when available; otherwise use local audio tooling only if the file is accessible and dependencies exist.
- Sora/video: use an installed Sora/OpenAI video connector when available. If unavailable, produce a prompt/storyboard/spec rather than claiming a video was generated.
