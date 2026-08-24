# Codex Workstation Backup

Windows에서 사용하는 Codex, Cursor, Claude 호환 스킬과 작업공간 설정을 다른 PC에 재현하기 위한 비공개 백업입니다.

## 포함 내용

- 직접 관리하는 작업공간·Codex 전역·Cursor 전역 스킬 원본
- 설치형/시스템 스킬의 이름, 버전, 출처, SHA-256 인벤토리
- 비밀정보와 PC 고유 경로를 제거한 Codex/Cursor/MCP 설정 템플릿
- 작업공간 정책 파일과 멀티모델 검토 스크립트
- HWP MCP 소스 코드
- 업데이트, 복원, 무결성 검증 PowerShell 스크립트

인증 토큰, OAuth 세션, 대화 기록, 메모리 DB, 로그, 쿠키, 플러그인 캐시는 포함하지 않습니다.

## 노트북 복원

필수 도구는 Windows PowerShell 7+, Git, Codex 앱 또는 CLI입니다. HWP MCP에는 Python과 한컴오피스가 필요하고, gstack 설치에는 Git Bash가 필요합니다.

```powershell
git clone https://github.com/lee-seong-wook/codex-workstation-backup.git
cd codex-workstation-backup

# 실제 변경 없이 확인
pwsh -File .\scripts\Restore-Setup.ps1 -WhatIf

# 깨끗한 노트북에 복원
pwsh -File .\scripts\Restore-Setup.ps1

# 현재 PC의 full-access 승인 정책까지 그대로 복원할 때만 명시적으로 사용
pwsh -File .\scripts\Restore-Setup.ps1 -RestorePrivilegedPolicy

# 기존 설정을 백업한 뒤 교체해야 할 때만 사용
pwsh -File .\scripts\Restore-Setup.ps1 -Force
```

GitHub MCP를 사용하려면 복원 전에 사용자 환경 변수 `GITHUB_PERSONAL_ACCESS_TOKEN`을 설정합니다. GitHub, Notion, Linear, Zotero 등 외부 연결의 OAuth 로그인은 새 PC에서 다시 수행해야 합니다.

## 현재 PC에서 백업 갱신

```powershell
pwsh -File .\scripts\Update-Backup.ps1
pwsh -File .\scripts\Test-Backup.ps1
```

경로가 다르면 명시적으로 전달합니다.

```powershell
pwsh -File .\scripts\Update-Backup.ps1 `
  -WorkspaceRoot 'D:\code' `
  -CodexHome "$env:USERPROFILE\.codex" `
  -CursorHome "$env:USERPROFILE\.cursor"
```

## 안전 원칙

- 현재 인벤토리는 243개 스킬 인스턴스, 214개 고유 이름, 22개 중복 이름을 기록하며 직접 복원되는 스킬은 96개입니다.
- 복원 스크립트는 기존 파일을 기본적으로 건너뜁니다.
- `-Force`를 사용하면 기존 대상은 같은 위치의 `*.backup-<timestamp>`로 이동한 뒤 교체합니다.
- 기본 복원은 `on-request`/`workspace-write` 정책을 사용합니다. 기존 `never`/`danger-full-access`와 광범위한 Claude 권한은 `-RestorePrivilegedPolicy`를 지정한 경우에만 복원합니다.
- 플러그인 캐시는 복사하지 않고 `manifests/plugins.lock.json`을 기준으로 재설치합니다.
- gstack는 `manifests/plugins.lock.json`에 고정된 Git 커밋에서 다시 설치합니다.
- 커밋이나 업로드 전에는 `Test-Backup.ps1`이 파일 해시, 비밀정보, 제외 파일, 설정 문법을 검사해야 합니다.
