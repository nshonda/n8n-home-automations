# Daily Digest Setup Guide

Send a daily Discord summary of all emails processed by the Email Classifier, with per-email detail including subject, sender, categories, and priority.

## Architecture Overview

```
Schedule (midnight) ─→ Fetch Labels ─→ Build Label Map
                                            │
                       Gmail API ←──────────┘
                       (list messages)
                            │
                       Split IDs ─→ Fetch Details (per message)
                            │
                       Aggregate & Categorize
                            │
                       Build Discord Embed(s) ─→ Discord Webhook
```

Each message is fetched individually to get subject, sender, and label metadata. The workflow resolves Gmail label IDs to human-readable names using the same label-fetching pattern as the Email Classifier.

## Prerequisites

- Email Classifier workflow already running and applying labels
- Discord server with a channel for digest messages
- Discord webhook URL

## Step 1: Create Discord Webhook

1. Open your Discord server
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it (e.g., "n8n Email Digest"), select the target channel
5. Copy the **Webhook URL**

## Step 2: Import Workflow

1. Open n8n at `https://n8n.yourdomain.com`
2. Go to **Workflows** → **Import from File**
3. Select `workflows/daily-digest.json`
4. Update credential references:
   - Click each **HTTP Request** node that uses Gmail → Select your Gmail OAuth2 credential
   - Nodes requiring credentials: **Fetch Labels**, **Get Processed Emails**, **Fetch Message Details**
5. Click the **Send to Discord** node → paste your webhook URL in the URL field
6. **Activate** the workflow

## Workflow Nodes

| Node | Type | Purpose |
|------|------|---------|
| Schedule Trigger | Schedule | Fires at midnight daily |
| Manual Trigger | Manual | For testing without waiting |
| Compute Date Range | Code | Calculates today's date and day of week |
| Fetch Labels | HTTP Request | GET Gmail labels API (OAuth2) |
| Build Label Map | Code | Builds ID → name map for label resolution |
| Get Processed Emails | HTTP Request | Lists messages with `label:_System/Processed newer_than:1d` (up to 500) |
| Has Emails? | IF | Routes to digest or quiet day message |
| Split Message IDs | Code | Outputs one item per message ID |
| Fetch Message Details | HTTP Request | GET each message's metadata (subject, sender, labels) |
| Aggregate & Categorize | Code | Groups emails by category, priority, and action |
| Build Discord Embed | Code | Formats rich Discord embed(s) with all sections |
| Quiet Day Message | Code | Minimal embed when no emails were processed |
| Send to Discord | HTTP Request | POSTs embed payload to Discord webhook |

## Discord Embed Format

The digest includes these sections:

- **Total Processed** — email count
- **By Category** — emoji-tagged breakdown (e.g., 💰 Finance: 5, 💼 Work: 8)
- **Urgent** — individually listed with subject and sender (only shown if any exist)
- **Action Needed** — listed with action type like Reply/Review (only shown if any exist)
- **All Emails** — every email with category tag, subject, and sender

The embed color reflects urgency: green (no urgent), yellow (1–2 urgent), red (3+ urgent).

When the email listing exceeds Discord's 1024-character field limit, it automatically splits across multiple fields and embeds (up to 10 embeds per message).

## Testing

Use the **Manual Trigger** node to test immediately without waiting for midnight:

1. Open the workflow in the editor
2. Click **Test Workflow**
3. Check your Discord channel for the digest message
4. Verify emails appear with correct categories and sender names

## Customization

### Change Schedule

Edit the **Schedule Trigger** node to adjust when the digest runs. The `triggerAtHour` parameter controls the hour (0 = midnight, 7 = 7 AM, etc.).

### Adjust Email Query

Edit the **Get Processed Emails** node `q` query parameter:
- `label:_System/Processed newer_than:1d` — last 24 hours (default)
- `label:_System/Processed newer_than:2d` — last 48 hours
- `label:_System/Processed after:2026/01/15` — after a specific date

### Add Categories

Update the `catEmoji` mapping in the **Build Discord Embed** node to add emoji icons for new categories.

## Troubleshooting

### No message in Discord
- Verify the webhook URL is correct in the **Send to Discord** node
- Check n8n execution logs for HTTP errors
- Test the webhook directly: `curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_WEBHOOK_URL`

### Emails showing but no categories
- Ensure the Email Classifier is applying `#Category` labels (e.g., `#Finance`, `#Work`)
- Check the **Build Label Map** node output — it should contain your custom labels
- Labels must exist in Gmail before they can be resolved

### Missing emails
- The `newer_than:1d` query covers roughly the last 24 hours from execution time
- `maxResults` is set to 500 — if you process more than 500 emails/day, increase this value
- Ensure the Email Classifier is applying the `_System/Processed` label

### Embed too large / truncated
- Discord limits: 1024 chars per field, 6000 chars per embed, 10 embeds per message
- With very high volume (200+ emails), some entries may be cut off at the 10-embed limit
- Consider filtering to only show high-priority emails if volume is consistently high
