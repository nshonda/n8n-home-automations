# n8n Home Automations

A collection of home automation workflows for self-hosted [n8n](https://n8n.io/), running on Docker behind a Cloudflare Tunnel.

## Automations

### Email Classifier (Inbox Zero)

AI-powered email classification using Claude 3.5 Haiku. Automatically labels and archives all incoming Gmail messages for true inbox zero.

- Classifies emails in English and Brazilian Portuguese
- Applies hierarchical labels (`#Finance`, `@Action/Reply`, `!Priority/Urgent`, etc.)
- Archives all processed emails out of the inbox
- Detects promotional/transactional emails (noreply, unsubscribe)
- Batch processor for existing inbox backlog

**Workflows:**
- `email-classifier.json` — Continuous classifier triggered on new emails
- `batch-classify-existing.json` — One-time batch processor (loops until inbox is empty)
- `setup-gmail-labels.json` — Creates the 43 Gmail labels (run once)

**Docs:** [Quick Start](docs/quick-start.md) | [Gmail OAuth Setup](docs/gmail-oauth-setup.md)

## Infrastructure

### Deployment

```bash
git clone https://github.com/nshonda/n8n-home-automations.git
cd n8n-home-automations/deploy
cp .env.example .env   # edit with your values
docker compose up -d
```

n8n runs as a standalone Docker container alongside other services (e.g. media stacks, Portainer). Exposed via Cloudflare Tunnel on a custom subdomain.

### Requirements

- Linux server with Docker
- Domain with Cloudflare DNS
- Service-specific credentials (Gmail OAuth2, Anthropic API key, etc.)

## Project Structure

```
workflows/          n8n workflow JSON files
deploy/             Docker Compose config and setup script
docs/               Setup and deployment guides
scripts/            Helper scripts
_context/           Research notes and architecture docs
```

## License

MIT
