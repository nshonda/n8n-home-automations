# Cleanup Old Emails Setup

One-time workflow to clean up old unread emails and spam.

## What It Does

Runs two phases in sequence:

1. **Old Unread** — Trashes all unread emails older than 2 years (`is:unread older_than:2y`)
2. **Spam Cleanup** — Trashes all emails in the spam folder (`in:spam`)

Emails are moved to Gmail's Trash, which auto-deletes after 30 days. This gives you a safety window to recover anything trashed by mistake.

## Prerequisites

- Gmail OAuth2 credential configured in n8n (same as the email classifier)

## Setup

1. Import `workflows/cleanup-old-emails.json` in n8n
2. Connect your Gmail OAuth2 credential to the **List Emails** and **Trash Email** nodes
3. Run manually

## How It Works

- Processes 50 emails per batch with retry on fail
- First processes all old unread emails, then switches to spam
- Loops until both phases are empty
- Shows a summary at the end with counts for each phase

## Notes

- **Trashed, not permanently deleted** — emails go to Trash and are auto-deleted after 30 days
- **No AI classification** — this workflow just trashes, no Anthropic API calls
- **Safe to re-run** — already-trashed emails won't appear in the query
- To permanently delete instead of trash, change the API endpoint from `/trash` to `/delete` (irreversible)
