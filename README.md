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

### Toggl → Jira/Tempo Sync

Syncs Toggl time entries to Jira/Tempo worklogs. Runs on the last weekday of each month, or on-demand via Manual Trigger.

- Fetches Toggl entries from the last 33 days
- Filters out entries already tagged `in-jira`, running timers, and non-ticket descriptions
- Extracts Jira ticket number from description (e.g., `CR-123 Fix login bug`)
- Resolves Jira issue ID, logs worklog to Tempo, tags Toggl entry as `in-jira`
- Error handling with per-entry error reporting in summary
- Schedule auto-checks if today is the last weekday; manual trigger always runs

**Workflows:**
- `toggl-jira-sync.json` — Schedule + Manual trigger → Toggl → Jira/Tempo → Tag

**Docs:** [Toggl/Jira Sync Setup](docs/toggl-jira-sync-setup.md)

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for planned workflows across 4 waves: email snooze, morning briefings, expense tracking, newsletter summarization, server monitoring, and more.

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

## Deploying Workflows via API

Workflow JSON files use placeholder credential IDs (`GMAIL_CREDENTIAL_ID`, `ANTHROPIC_CREDENTIAL_ID`). When deploying to n8n via the API, you need to replace these with real credential IDs.

### Finding Real Credential IDs

Check a working workflow on your n8n instance:

```bash
API_KEY=$(cat ~/.n8n-api-key)
curl -s "http://localhost:5678/api/v1/workflows/<WORKFLOW_ID>" \
  -H "X-N8N-API-KEY: $API_KEY" | python3 -c "
import sys, json
wf = json.load(sys.stdin)
for node in wf.get('nodes', []):
    creds = node.get('credentials', {})
    if creds:
        for ctype, cval in creds.items():
            print(node['name'] + ': ' + ctype + ' = ' + cval.get('id', 'NONE'))
"
```

### Importing a New Workflow

```bash
API_KEY=$(cat ~/.n8n-api-key)
curl -s -X POST "http://localhost:5678/api/v1/workflows" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/my-workflow.json
```

### Updating an Existing Workflow

```bash
API_KEY=$(cat ~/.n8n-api-key)
# Get current workflow to preserve credentials
curl -s "http://localhost:5678/api/v1/workflows/<WORKFLOW_ID>" \
  -H "X-N8N-API-KEY: $API_KEY" > /tmp/current.json

# Update with new JSON (must include name, nodes, connections, settings)
python3 -c "
import json
with open('workflows/my-workflow.json') as f:
    wf = json.load(f)
payload = json.dumps({
    'name': wf['name'],
    'nodes': wf['nodes'],
    'connections': wf['connections'],
    'settings': wf.get('settings', {})
})
print(payload)
" | curl -s -X PUT "http://localhost:5678/api/v1/workflows/<WORKFLOW_ID>" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d @-
```

### Fixing Credentials After Import

After importing via API, credential placeholders need to be replaced with real IDs:

```bash
API_KEY=$(cat ~/.n8n-api-key)
python3 -c "
import json, urllib.request

api_key = open('$HOME/.n8n-api-key').read().strip()
GMAIL_ID = '<your-gmail-credential-id>'
ANTHROPIC_ID = '<your-anthropic-credential-id>'

wf_id = '<WORKFLOW_ID>'
req = urllib.request.Request(
    'http://localhost:5678/api/v1/workflows/' + wf_id,
    headers={'X-N8N-API-KEY': api_key}
)
wf = json.loads(urllib.request.urlopen(req).read())

for node in wf.get('nodes', []):
    creds = node.get('credentials', {})
    if 'gmailOAuth2' in creds and creds['gmailOAuth2'].get('id') == 'GMAIL_CREDENTIAL_ID':
        node['credentials']['gmailOAuth2']['id'] = GMAIL_ID
    if 'anthropicApi' in creds and creds['anthropicApi'].get('id') == 'ANTHROPIC_CREDENTIAL_ID':
        node['credentials']['anthropicApi']['id'] = ANTHROPIC_ID

payload = json.dumps({
    'name': wf['name'],
    'nodes': wf['nodes'],
    'connections': wf['connections'],
    'settings': {'executionOrder': wf.get('settings', {}).get('executionOrder', 'v1')}
}).encode()

req2 = urllib.request.Request(
    'http://localhost:5678/api/v1/workflows/' + wf_id,
    data=payload, method='PUT',
    headers={'X-N8N-API-KEY': api_key, 'Content-Type': 'application/json'}
)
urllib.request.urlopen(req2)
print('Done')
"
```

### Notes

- The n8n API **does not** support `GET /api/v1/credentials` — you can't list credentials via API
- When updating workflows via API, credentials set in the UI will be **overwritten** by whatever is in the JSON payload — always include real credential IDs
- The `settings` field must only contain known properties (e.g. `executionOrder`) — extra fields cause a 400 error
- `batchModify` endpoints return 204 No Content — use `responseFormat: "text"` with `neverError: true` in HTTP Request nodes

## Project Structure

```
workflows/          n8n workflow JSON files
deploy/             Docker Compose config and setup script
docs/               Setup and deployment guides
scripts/            Helper scripts
```

## License

MIT
