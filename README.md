# n8n Home Automations

AI-powered email classification and inbox zero automation using self-hosted [n8n](https://n8n.io/), Gmail API, and Claude AI.

## What It Does

Automatically classifies incoming Gmail messages using Claude 3.5 Haiku, applies hierarchical labels, and archives everything out of your inbox. Emails are organized into label-based views (Multiple Inbox sections in Gmail) so you see what matters without manual sorting.

```
Gmail ──> n8n (self-hosted) ──> Claude Haiku ──> Labels + Archive
               ↑
        Cloudflare Tunnel
```

- Classifies emails in English and Brazilian Portuguese
- Applies category labels (`#Finance`, `#Shopping`, `#Travel`, etc.)
- Flags priority and action-needed items (`@Action/Reply`, `!Priority/Urgent`)
- Archives all processed emails for true inbox zero
- Handles promotional/transactional email detection (noreply, unsubscribe links)

## Label System

| Prefix | Purpose | Examples |
|--------|---------|---------|
| `@` | Action required | `@Action/Reply`, `@Action/Review`, `@Action/Pay` |
| `#` | Category | `#Finance`, `#Shopping`, `#Travel`, `#Work` |
| `!` | Priority | `!Priority/Urgent`, `!Priority/Important` |
| `~` | Reference | `~Reference/Docs`, `~Reference/Receipts` |
| `_` | System | `_System/Processed`, `_System/Review` |

## Workflows

### `email-classifier.json` — Main Classifier
Triggered on new Gmail messages. Fetches label IDs, classifies via Claude Haiku, applies labels, and archives. Runs continuously.

### `batch-classify-existing.json` — Batch Processor
Processes existing inbox emails in batches of 50 with a loop until the inbox is empty. Run once to reach inbox zero on your backlog.

### `setup-gmail-labels.json` — Label Setup
Creates all 43 Gmail labels. Import and run once before activating the classifier.

## Prerequisites

- Linux server with Docker
- Domain with Cloudflare DNS (for tunnel)
- Gmail account with OAuth2 credentials
- [Anthropic API key](https://console.anthropic.com/) (~$1-2/month for typical usage)

## Quick Start

1. **Deploy n8n**
   ```bash
   git clone https://github.com/nshonda/n8n-home-automations.git
   cd n8n-home-automations/deploy
   cp .env.example .env   # edit with your values
   docker compose up -d
   ```

2. **Set up Cloudflare Tunnel** — point your subdomain to `localhost:5678`

3. **Configure Gmail OAuth2** — see [docs/gmail-oauth-setup.md](docs/gmail-oauth-setup.md)

4. **Create labels** — import `workflows/setup-gmail-labels.json` in n8n and run it

5. **Import & activate** — import `workflows/email-classifier.json`, connect your Gmail and Anthropic credentials, and activate

See [docs/quick-start.md](docs/quick-start.md) for detailed steps.

## Project Structure

```
workflows/          n8n workflow JSON files
deploy/             Docker Compose config and setup script
docs/               OAuth setup and deployment guides
scripts/            Helper scripts (label creation)
_context/           Research notes and architecture docs
```

## Cost

| Emails/Month | Estimated Cost |
|-------------|---------------|
| 500 | ~$0.50 |
| 2,000 | ~$1.80 |
| 10,000 | ~$8.80 |

Sender caching reduces costs by 40-60% for repeat senders.

## License

MIT
