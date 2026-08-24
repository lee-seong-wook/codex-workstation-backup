---
name: deploy-platforms
description: Deploy and configure apps on Vercel, Netlify, Render, and Cloudflare. Use when the user asks to deploy, publish, host, configure build settings, set environment variables, debug deploy failures, prepare preview/production releases, or mentions "vercel", "netlify", "render", "cloudflare", "배포", or "호스팅".
---

# Deploy Platforms

## Workflow

1. Identify the platform from user wording or project files.
2. Inspect the project before changing deploy config: package manager, build command, output directory, runtime, env vars, and existing platform files.
3. Prefer preview/staging deploys before production. Do not run a production deploy unless the user clearly asks for it.
4. Never commit secrets. Use platform environment-variable settings or documented secret stores.
5. Verify locally first: install deps, run tests when available, and run the build command.
6. After deploy, verify the URL, logs, and health checks. Report exact commands and failures.

## Platform Notes

- Vercel: use `vercel` / `vercel deploy`, `vercel.json` or project settings, and preview before `--prod`.
- Netlify: use Netlify CLI, `netlify.toml`, `netlify deploy`, and `netlify deploy --prod` only for production.
- Render: prefer dashboard/Git auto-deploys or `render.yaml` Blueprints; inspect service logs on failures.
- Cloudflare: use Wrangler for Workers/Pages workflows; distinguish Workers deploys from Pages static asset deploys.

Use official docs when exact flags or config schema matter because deployment CLIs change.
