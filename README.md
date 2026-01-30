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
- `batch-classify-historical.json` — Classifies archived emails from the last 2 years (labels only, no archiving)
- `cleanup-old-emails.json` — Trashes unread emails older than 2 years + empties spam
- `setup-gmail-labels.json` — Creates the 43 Gmail labels (run once)

**Docs:** [Quick Start](docs/quick-start.md) | [Gmail OAuth Setup](docs/gmail-oauth-setup.md)

### Invoice Forwarding

Automatically collects monthly invoices from Husky and Deel, then sends them to the accountant with both PDFs attached.

- Husky path: detects payment email, downloads PDF attachment, uploads to Google Drive staging folder
- Deel path: detects payment email, sends a reminder to manually download and upload the Deel invoice
- Convergence: watches the staging folder — when both PDFs are present, composes and sends the email
- Email sent to accountant with subject `Notas Fiscais [Month] [Year]` and both invoices attached
- Processed emails labeled `_System/InvoiceProcessed`, files moved to `Invoices/Processed`

**Workflows:**
- `forward-invoices.json` — Three-trigger workflow (Husky email, Deel email, Google Drive watcher)

**Docs:** [Invoice Forwarding Setup](docs/invoice-forwarding-setup.md)

### Daily Digest

Sends a daily Discord embed summarizing all emails processed by the Email Classifier, with full per-email detail.

- Runs at midnight (or manually triggered)
- Fetches each email's subject, sender, and labels via Gmail API
- Category breakdown with emoji tags (`Finance`, `Work`, `Shopping`, etc.)
- Urgent and action-needed emails listed individually
- Full email listing across multiple Discord embeds when volume is high
- Color-coded embed: green (no urgent), yellow (1–2 urgent), red (3+ urgent)
- Quiet day message when no emails were processed

**Workflows:**
- `daily-digest.json` — Nightly Discord digest via webhook

**Docs:** [Daily Digest Setup](docs/daily-digest-setup.md)

### Error Notifications

Global error handler that sends a Discord alert when any workflow fails.

- Red embed with workflow name, failed node, error message, and execution ID
- Set as the instance-level error workflow in Settings → Error Workflow

**Workflows:**
- `error-notification.json` — Error trigger → Discord webhook

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
```

## License

MIT
