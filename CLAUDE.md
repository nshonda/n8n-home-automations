# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-hosted n8n automation platform running on Docker behind Cloudflare Tunnel. Workflows handle AI-powered email classification (Claude Haiku), invoice forwarding, daily digests, Toggl→Jira/Tempo time sync, job search matching (Ollama embeddings), and error notifications — all posting to Discord.

## Architecture

- **`workflows/`** — n8n workflow JSON files, imported via API (not UI export format)
- **`deploy/`** — Docker Compose (n8n + Ollama with GPU), `.env.example`, and `setup.sh` for server provisioning
- **`docs/`** — Per-workflow setup guides and roadmap (`docs/roadmap.md`)
- **`scripts/`** — Helper scripts: `import-workflows.sh` (SSH + n8n API bulk import), `create-gmail-labels.sh` (OAuth-based label creation)

## Deployment

```bash
# Initial server setup (installs Docker, starts services, waits for Ollama models)
cd deploy && cp .env.example .env && ./setup.sh

# Import/update all workflows via API
./scripts/import-workflows.sh
```

The import script requires SSH alias `nshonda` and an n8n API key at `~/.n8n-api-key`. It detects existing workflows by name and uses PUT (update) or POST (create) accordingly, stripping payloads to only `name`, `nodes`, `connections`, `settings`.

## Docker Services

Three containers in `deploy/docker-compose.yml`:
- **ollama** — GPU-accelerated, models: `nomic-embed-text`, `qwen2.5:3b`
- **ollama-init** — One-shot model puller
- **n8n** — Port 5678 (local only, exposed via Cloudflare Tunnel), 4GB heap limit

## Key Integrations & Credentials

| Integration | Auth Type | n8n Credential Type |
|---|---|---|
| Gmail | OAuth2 (scopes: `gmail.modify`, `gmail.labels`) | Gmail OAuth2 |
| Google Drive/Sheets | OAuth2 (scopes: `drive.readonly`, `spreadsheets`) | Google Drive/Sheets OAuth2 |
| Anthropic (Claude Haiku) | Header Auth (`x-api-key`) | Header Auth |
| Toggl | Basic Auth (API token as username) | HTTP Basic Auth |
| Jira | Basic Auth (email + API token) | HTTP Basic Auth |
| Tempo | Bearer Token | HTTP Bearer Token |
| Discord | Webhook URL (env var) | None (direct HTTP) |
| Adzuna | App ID + API Key (env vars) | None (query params) |
| Ollama | None (internal Docker network) | None |

OAuth redirect URI pattern: `https://<N8N_HOST>/rest/oauth2-credential/callback`

## Workflow Conventions

- Workflows use n8n environment variables (set in `docker-compose.yml` `environment` section) for configuration like `JIRA_BASE_URL`, `DISCORD_WEBHOOK_URL`, `TOGGL_PROJECT_ID`, etc.
- Rate limiting is implemented inline within workflows (Gmail API, Claude API) to prevent throttling.
- Recovery workflows exist (`recovery-remove-processed-label.json`, `recovery-untrash-all.json`) to reverse bulk operations.
- The error notification workflow (`error-notification.json`) is set as the instance-level error handler.
- Gmail `batchModify` returns 204 No Content — this is expected, not an error.

## Workflow Editing

Workflow JSON files are the source of truth. The development flow is:
1. Edit workflows in the n8n UI
2. Export via n8n API or UI
3. Save to `workflows/` directory
4. Deploy via `scripts/import-workflows.sh`

When editing workflow JSON directly, preserve credential ID placeholders — actual credential IDs are environment-specific and get set after import via the n8n UI.

## Gmail Label Taxonomy

43 hierarchical labels organized by prefix: `@Action/*`, `#Finance/*`, `#Work/*`, `#Shopping/*`, `#Travel/*`, `!Priority/*`, `~Reference/*`, `_System/*`, `_Snooze/*`. The email classifier assigns these labels. Changes to the label taxonomy must be reflected in both the label creation script/workflow and the classifier workflow prompt.
