# Local MCP

This is the canonical repo-local MCP path.

Use this directory when another IDE, CLI agent, or human needs to inspect the workspace-local MCP manifest:
- `{{WORKSPACE_ROOT}}\mcp`

Files:
- `cursor.mcp.json`: canonical repo-local MCP manifest
- `sync-cursor-mcp.ps1`: recreates the local `.cursor/mcp.json` compatibility hard link from the canonical manifest

Compatibility entry point:
- `.cursor/mcp.json` -> hard link to `mcp/cursor.mcp.json`

Edit rule:
- edit `mcp/cursor.mcp.json` only
- if `.cursor/mcp.json` is missing, stale, or no longer a hard link, regenerate it from `mcp/sync-cursor-mcp.ps1`

Setup command:

```powershell
powershell -ExecutionPolicy Bypass -File .\mcp\sync-cursor-mcp.ps1
```

Separation rule:
- Repo-local manifest lives here.
- Live Codex user config stays in `{{CODEX_HOME}}\config.toml`.
- Global human-readable MCP catalog will live under `{{CODEX_HOME}}\mcp`.
