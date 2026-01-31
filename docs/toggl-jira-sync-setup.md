# Toggl → Jira/Tempo Sync Setup Guide

Syncs Toggl time entries to Jira/Tempo worklogs. Runs automatically on the last weekday of each month, or on-demand via Manual Trigger (from phone/browser).

## Architecture Overview

```
Schedule (28th–31st 5pm) ──→ Check Last Weekday ──→ Fetch Toggl Entries
Manual Trigger ────────────┘         │                      │
                            (stop if not last       Filter Entries
                             weekday, unless          (exclude in-jira,
                             manual)                   extract ticket #,
                                                       store in static data)
                                                          │
                                                    Skip If Empty?
                                                     ┌────┴────┐
                                                   Yes         No
                                                    │           │
                                                    │     Get Jira Issue ID
                                                    │           │
                                                    │     Prepare Tempo (restore + merge issueId)
                                                    │           │
                                                    │     Check Existing Worklog
                                                    │           │
                                                    │     Process Check Results (mark duplicates)
                                                    │           │
                                                    │     Log Tempo (skip dupes via neverError)
                                                    │           │
                                                    │     Prepare Toggl Tag (restore from static data)
                                                    │           │
                                                    │     Tag Toggl "in-jira" + project + billable
                                                    │           │
                                                    │     Collect Result
                                                    │           │
                                                    └─── Summary ──┘
                                                           │
                                                    Discord Notification
```

## Prerequisites

- Toggl account with time entries that start with a Jira ticket number (e.g., `CR-123 Fix login bug`)
- Jira Cloud instance with API access
- Tempo Timesheets plugin installed on Jira

## Step 1: Gather API Credentials

### Toggl — API Token

Using an API token is recommended over your login password.

1. Go to [Toggl Track](https://track.toggl.com/)
2. Click your **profile icon** (bottom left) → **Profile Settings**
3. Scroll to **API Token** at the bottom of the page
4. Copy the token
5. You also need your **Workspace ID** (for reference — the workflow extracts it automatically from entries):
   - Go to **Reports** (left sidebar)
   - Check the URL: `https://track.toggl.com/reports/summary/<WORKSPACE_ID>`

### Jira — API Token

1. Go to [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)
   - Or: Jira → click your **profile icon** (top right) → **Manage account** → **Security** tab → **API Tokens**
2. Click **Create API token**
3. Label it something like `n8n-toggl-sync`
4. Copy the generated token — you won't see it again
5. Note your **Jira login email** (used as the username)

### Jira — Account ID

Needed for the Tempo worklog `authorAccountId` field.

1. In Jira, click your **profile icon** (top right) → **Profile**
2. Check the URL: `https://yourcompany.atlassian.net/jira/people/<ACCOUNT_ID>`
3. Copy the account ID string

### Jira — Base URL

Your Jira instance URL, e.g. `https://yourcompany.atlassian.net`

### Tempo — API Token

1. In Jira, open **Tempo** (left sidebar → Timesheets → Open Tempo)
2. Click the **gear icon** → **Settings** → **API Integration**
   - Or go directly to: `https://yourcompany.atlassian.net/plugins/servlet/ac/io.tempo.jira/tempo-app#!/configuration/api-integration`
3. Click **Create new token**
4. Give it a name like `n8n-sync` and grant **Worklogs: Write** permission
5. Copy the token

## Step 2: Create n8n Credentials

With the values from Step 1, create three credentials in n8n:

### Toggl Basic Auth (HTTP Basic Auth)

1. In n8n, go to **Credentials** → **Add Credential** → **HTTP Basic Auth**
2. Name: `Toggl Basic Auth`
3. User: your Toggl API token
4. Password: `api_token` (the literal string)
5. Save

n8n automatically encodes to base64 — no manual encoding needed.

### Jira Basic Auth (HTTP Basic Auth)

1. **Add Credential** → **HTTP Basic Auth**
2. Name: `Jira Basic Auth`
3. User: your Jira login email
4. Password: the API token from Step 1
5. Save

### Tempo Bearer Token (HTTP Header Auth)

1. **Add Credential** → **Header Auth**
2. Name: `Tempo Bearer Token`
3. Header Name: `Authorization`
4. Header Value: `Bearer <your-tempo-api-token>` (paste the Tempo token after `Bearer `)
5. Save

## Step 3: Set Environment Variables

Set the following environment variables in your n8n instance (Settings → Environment Variables, or in your Docker/`.env` config):

| Variable | Description | Example |
|----------|-------------|---------|
| `JIRA_BASE_URL` | Your Jira instance URL (no trailing slash) | `https://yourcompany.atlassian.net` |
| `JIRA_ACCOUNT_ID` | Your Jira account ID for Tempo worklogs | `5abcdef1234567890abcdef0` |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL for sync notifications | `https://discord.com/api/webhooks/...` |
| `TOGGL_PROJECT_ID` | Toggl project ID to assign to synced entries | `123456789` |
| `TOGGL_WORKSPACE_ID` | Toggl workspace ID | `1234567` |

## Step 4: Import Workflow

1. Open n8n at `https://n8n.yourdomain.com`
2. Go to **Workflows** → **Import from File**
3. Select `workflows/toggl-jira-sync.json`

## Step 5: Configure Credential References

Click each HTTP Request node and select the correct credential:

| Node | Credential Type | Credential Name |
|------|----------------|-----------------|
| Fetch Toggl Entries | HTTP Basic Auth | Toggl Basic Auth |
| Get Jira Issue ID | HTTP Basic Auth | Jira Basic Auth |
| Check Existing Worklog | Header Auth | Tempo Bearer Token |
| Log Tempo Worklog | Header Auth | Tempo Bearer Token |
| Tag Toggl Entry | HTTP Basic Auth | Toggl Basic Auth |

## Step 6: Activate

1. Toggle the workflow **Active**
2. The schedule triggers on the 28th–31st of each month at 5 PM — it will only actually run on the last weekday

## Workflow Nodes

| Node | Type | Purpose |
|------|------|---------|
| Schedule Trigger | Schedule | Fires on 28th–31st at 5 PM |
| Manual Trigger | Manual | On-demand runs from n8n UI |
| Check Last Weekday | Code | Stops if not last weekday (manual always proceeds) |
| Fetch Toggl Entries | HTTP Request | GET Toggl time entries (last 33 days) |
| Filter Entries | Code | Excludes `in-jira` tagged, zero durations, non-ticket entries. Stores entries in workflow static data. |
| Skip If Empty | IF | Routes to Summary if nothing to sync |
| Get Jira Issue ID | HTTP Request | Resolves ticket key → Jira issue ID (rate limited: 5/batch, 1s interval) |
| Prepare Tempo | Code | Restores entry data from static data, merges with Jira issue ID |
| Check Existing Worklog | HTTP Request | GET Tempo worklogs to check for duplicates (rate limited: 3/batch, 1s interval) |
| Process Check Results | Code | Restores entry data, marks duplicates with `tempoSkipped` flag |
| Log Tempo Worklog | HTTP Request | POST worklog to Tempo; skips duplicates via conditional body + neverError (rate limited: 3/batch, 1s interval) |
| Prepare Toggl Tag | Code | Restores entry data from static data for Toggl tagging |
| Tag Toggl Entry | HTTP Request | PUT `in-jira` tag + project + billable on Toggl entry (rate limited: 1/batch, 1.1s interval) |
| Collect Result | Code | Restores entry data, formats results with tempoLogged/tempoSkipped |
| Summary | Code | Aggregates results into final summary |
| Build Discord Embed | Code | Builds color-coded Discord embed message |
| Send to Discord | HTTP Request | Posts summary to Discord webhook |

## Testing

1. Open the workflow in the editor
2. Click **Test Workflow** (uses the Manual Trigger)
3. Check each node's output — especially:
   - **Filter Entries**: should show only un-synced entries with valid ticket numbers
   - **Get Jira Issue ID**: should return a Jira issue object with numeric `id` field
   - **Prepare Tempo**: should show entry data merged with `issueId`
   - **Check Existing Worklog**: should return `metadata.count` (0 = new, >0 = duplicate)
   - **Process Check Results**: should show entries with `tempoSkipped` flag
   - **Log Tempo Worklog**: should return 200 for new entries (400 for skipped — expected)
   - **Tag Toggl Entry**: should return 200 with updated Toggl entry
   - **Summary**: should list all synced entries (duplicates shown as "already in Tempo")
   - **Send to Discord**: should post color-coded embed to your channel

## Customization

### Change Schedule Time

Edit the **Schedule Trigger** node — modify `triggerAtHour` (default: 17 = 5 PM).

### Adjust Lookback Period

Edit the **Check Last Weekday** Code node — change `33` in `startDate.setDate(startDate.getDate() - 33)` to your preferred number of days.

### Tempo Work Attributes

The worklog payload includes `attributes: [{ key: '_Dev_', value: 1 }]`. If your Tempo config uses different work attribute keys, update the JSON body in the **Log Tempo Worklog** node.

## Troubleshooting

### Toggl returns empty array
- Verify your Toggl credential is correct (test with `curl -u YOUR_API_TOKEN:api_token https://api.track.toggl.com/api/v9/me`)
- Check that the date range covers your entries (default: 33 days back)

### Jira 401/403 errors
- Verify your Jira API token is valid and the email matches
- Ensure the user has permission to view the ticket

### Tempo 400 errors
- Verify `JIRA_ACCOUNT_ID` env var is set correctly
- Check that the Jira issue ID is numeric (not the ticket key)
- Ensure the Tempo API token has write permissions

### Duplicate worklogs
- The workflow checks for existing worklogs before posting. If you see duplicates from before this update, manually delete them in Tempo.

### Entries not getting tagged in Toggl
- The workspace ID is extracted automatically from each Toggl entry
- Verify your Toggl credentials have write access to the workspace

### Discord notification not sending
- Verify `DISCORD_WEBHOOK_URL` env var is set
- Test the webhook URL with a simple curl: `curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_WEBHOOK_URL`

### Environment variables not resolving
- Ensure variables are set in n8n Settings → Environment Variables (or in your Docker/`.env` config)
- Restart n8n after adding new environment variables
