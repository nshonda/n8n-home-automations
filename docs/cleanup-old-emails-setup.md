# Cleanup Old Unread Emails Setup

One-time workflow to trash unread emails older than 2 years.

## What It Does

Trashes all unread emails older than 2 years (`is:unread older_than:2y`) using Gmail's `batchModify` endpoint (100 messages per API call).

## Prerequisites

- Gmail OAuth2 credential configured in n8n (same as the email classifier)

## Setup

1. Import `workflows/cleanup-old-emails.json` in n8n
2. Connect your Gmail OAuth2 credential to the **List Old Unread** and **Batch Trash** nodes
3. Run manually

## How It Works

- Lists 100 messages per batch, collects IDs, sends a single `batchModify` call
- Loops until no more matches
- Shows a summary at the end with total trashed count

## Recovery Workflows

If something goes wrong, two recovery workflows are available:

- `recovery-untrash-all.json` — Moves all trashed emails back to inbox (uses `batchModify` with 100 per call)
- `recovery-remove-processed-label.json` — Strips `_System/Processed` from all emails so they can be re-classified

**Run order for full recovery:**
1. Untrash all emails
2. Remove processed labels
3. Run cleanup (this workflow)
4. Run batch classify workflows

## Notes

- **Trashed, not permanently deleted** — emails go to Trash and are auto-deleted after 30 days
- **No AI classification** — this workflow just trashes, no Anthropic API calls
- **Safe to re-run** — already-trashed emails won't appear in the query
