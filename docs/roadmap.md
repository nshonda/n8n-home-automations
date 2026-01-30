# Roadmap

Future workflow ideas for automating day-to-day life, organized by build priority.

## New Integrations Needed

| Integration | Setup Effort | Unlocks |
|-------------|-------------|---------|
| **Google Sheets API** | 5 min (enable in existing Google Cloud project) | Expense tracker, bill reminders, subscription tracker, habit tracker |
| **Google Calendar API** | 10 min (enable API + add OAuth scope) | Morning briefing, weekly review, meeting prep |
| **OpenWeatherMap API** | 5 min (free account + API key) | Weather alerts, morning briefing |
| **GitHub Personal Access Token** | 5 min | PR/issue notifier, commit digest |

**Recommended setup order**: Google Sheets → Google Calendar → OpenWeatherMap → GitHub PAT

---

## Wave 1 — Quick Wins (P0)

No new integrations needed. Build with what already exists.

### Email Snooze System
Activate the existing `_Snooze/Tomorrow`, `_Snooze/NextWeek`, `_Snooze/NextMonth` labels.

- **Trigger**: Cron daily at 6:00 AM
- **Flow**: Check `_Snooze/Tomorrow` (daily), `_Snooze/NextWeek` (Mondays), `_Snooze/NextMonth` (1st of month) → Gmail `batchModify` to move back to INBOX and remove snooze label → Discord notification
- **Complexity**: Simple (~8 nodes)

### VIP Sender Alerts
Instant Discord ping for emails from important contacts — no waiting for the daily digest.

- **Approach**: Add 2-3 nodes to the existing `email-classifier.json` after the "Preprocess Email" node
- **Flow**: Code node checks sender against a VIP list → IF match → Discord instant alert with sender + subject → continue normal classification
- **Complexity**: Simple (~3 new nodes)

### Server Health Monitor
Prevent outages on the self-hosted infrastructure.

- **Trigger**: Cron every 5 minutes
- **Flow**: Execute Command (disk, memory, CPU, Docker stats) → parse + threshold check → IF exceeded → Discord alert (color-coded severity)
- **Complexity**: Simple (~6 nodes)
- **Note**: Requires mounting Docker socket in `docker-compose.yml`

---

## Wave 2 — Foundation (P1)

Requires Google Sheets, Google Calendar, and OpenWeatherMap API setup.

### Morning Briefing
One consolidated morning Discord message with everything you need to start the day.

- **Trigger**: Cron at 7:00 AM
- **Flow**: Google Calendar (today's events) + Gmail (unread urgent emails) + HTTP Request (weather forecast) → Claude AI composes a briefing → Discord formatted message
- **Complexity**: Medium (~8 nodes)
- **New integrations**: Google Calendar, OpenWeatherMap

### Expense Tracker from Receipts
Build a real expense database from emails already labeled `#Finance/Receipts`.

- **Trigger**: Gmail poll for `#Finance/Receipts` without `_System/ExpenseLogged`
- **Flow**: Extract email body + attachments → Claude AI extracts merchant, amount, date, category (JSON) → Google Sheets append row → Discord confirmation → Gmail relabel
- **Complexity**: Medium (~12 nodes)
- **New integrations**: Google Sheets

### Backup Automation
Daily n8n data backup to Google Drive for disaster recovery.

- **Trigger**: Cron daily at 2:00 AM
- **Flow**: n8n API export all workflows as JSON → compress → upload to Google Drive backup folder → Discord confirmation with file count
- **Complexity**: Medium (~12 nodes)
- **New integrations**: None (Google Drive already connected)

---

## Wave 3 — Intelligence Layer (P1)

### Weekly Review
Sunday evening summary of the past and upcoming week.

- **Trigger**: Cron Sunday at 8:00 PM
- **Flow**: Gmail (weekly email stats by category/priority) + Google Calendar (past week events + upcoming week events) → Claude AI composes review → Discord rich embed
- **Complexity**: Medium (~10 nodes)
- **New integrations**: Google Calendar

### Newsletter AI Summarizer
Stop reading 20+ newsletters — get a curated weekly AI digest instead.

- **Trigger**: Cron weekly (Saturday morning)
- **Flow**: Gmail list `#Newsletters` from past 7 days → fetch each email body → Claude AI batch-summarize into key highlights → Discord digest + optional Google Sheets log
- **Complexity**: Medium (~10 nodes)
- **New integrations**: Google Sheets (optional)

### Bill Due Date Reminders
Parse bills for due dates, remind 3 days before — prevents missed payments.

- **Trigger**: Gmail poll for `#Finance/Bills` + daily cron for reminder checks
- **Flow**: Claude AI extracts due date + amount from bill emails → Google Sheets stores due dates → daily cron checks upcoming due dates → Discord reminder 3 days before
- **Complexity**: Medium (~16 nodes)
- **New integrations**: Google Sheets

---

## Wave 4 — Lifestyle & Productivity (P2)

### Habit Tracker
Daily Discord checklist with weekly stats.

- **Trigger**: Cron daily at 8:00 AM (prompt) + webhook for check-ins + weekly cron for stats
- **Flow**: Discord morning prompt → user responds via webhook → log to Google Sheets → weekly summary with streak counts
- **Complexity**: Medium (~10 nodes)
- **New integrations**: Google Sheets

### RSS/News Digest
Morning tech news summary from RSS feeds.

- **Trigger**: Cron daily at 7:30 AM
- **Flow**: RSS Feed Read (multiple feeds) → aggregate → Claude AI summarize top stories → Discord formatted digest
- **Complexity**: Simple (~12 nodes)
- **New integrations**: None (n8n has built-in RSS)

### Subscription Tracker
Detect recurring charges and track total subscription spend.

- **Trigger**: Monthly cron + Gmail poll for recurring payment emails
- **Flow**: Claude AI identifies recurring charges from `#Finance/Receipts` → Google Sheets tracks subscriptions + amounts → monthly Discord report of total subscription cost
- **Complexity**: Complex (~18 nodes)
- **New integrations**: Google Sheets

### Package Tracking
Auto-detect shipping emails and poll for delivery status.

- **Trigger**: Gmail poll for `#Shopping/Shipping`
- **Flow**: Claude AI extracts tracking numbers + carrier → HTTP Request to tracking API (17track) → Google Sheets stores active shipments → daily status check → Discord alerts on status changes
- **Complexity**: Complex (~18 nodes)
- **New integrations**: 17track API

### Smart Follow-Up Reminders
Detect unanswered emails where you promised to reply.

- **Trigger**: Daily cron
- **Flow**: Gmail list sent emails from past 7 days → check threads for missing replies (3+ days) → Claude AI detects if user committed to follow up → Discord reminder with thread link
- **Complexity**: Complex (~14 nodes)
- **New integrations**: None

### Uptime Monitor
Ping key URLs and alert when down.

- **Trigger**: Cron every 5 minutes
- **Flow**: HTTP Request to each URL → check response code/time → IF unhealthy → Discord alert → track in staticData to avoid duplicate alerts
- **Complexity**: Medium (~9 nodes)
- **New integrations**: None

### Meeting Prep Automation
Pre-meeting summary of related emails and docs.

- **Trigger**: Cron 30 minutes before each calendar event
- **Flow**: Google Calendar next event → extract attendees/topic → Gmail search related threads → Claude AI compose prep summary → Discord message
- **Complexity**: Complex (~12 nodes)
- **New integrations**: Google Calendar

### GitHub PR/Issue Notifier
AI-summarized daily repository activity alerts.

- **Trigger**: Cron daily at 9:00 AM
- **Flow**: GitHub API fetch recent PRs/issues/commits → Claude AI summarize activity → Discord digest
- **Complexity**: Medium (~12 nodes)
- **New integrations**: GitHub PAT

### Monthly Spending Summary
Aggregate financial data from the Expense Tracker workflow.

- **Trigger**: Cron 1st of month
- **Flow**: Google Sheets read current month expenses → aggregate by category → Claude AI compose summary with trends → Discord report
- **Complexity**: Medium (~12 nodes)
- **New integrations**: Google Sheets (depends on Expense Tracker)
