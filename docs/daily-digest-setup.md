# Daily Digest Setup Guide

Send a daily Discord summary of all emails processed by the Email Classifier.

## Architecture Overview

```
Schedule (midnight) ─→ Gmail API ─→ Count processed emails ─→ Discord Webhook
                         ↑
                   OAuth2 credential
```

## Prerequisites

- Email Classifier workflow already running
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
5. Click the **Send to Discord** node → paste your webhook URL in the URL field
6. **Activate** the workflow

## Testing

Use the **Manual Trigger** node to test immediately without waiting for midnight:

1. Open the workflow in the editor
2. Click **Test Workflow**
3. Check your Discord channel for the digest message

## Customization

### Change Schedule

Edit the **Schedule Trigger** node to adjust when the digest runs (default: midnight).

### Adjust Email Query

Edit the **Get Processed Emails** node query parameter to change what's included (default: `label:_System/Processed newer_than:1d`).

## Troubleshooting

### No message in Discord
- Verify the webhook URL is pasted in the **Send to Discord** node
- Check n8n execution logs for HTTP errors
- Test the webhook URL with `curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_WEBHOOK_URL`

### Missing emails in count
- Ensure the Email Classifier is applying the `_System/Processed` label
- The `newer_than:1d` query covers roughly the last 24 hours from execution time
