# Inbox Zero Automation Patterns

## Inbox Zero Philosophy

### Core Principles

The inbox zero methodology, popularized by Merlin Mann, is fundamentally about **decision latency**, not emptiness. The goal is to minimize the time emails spend in an undecided state.

**The Four D's Framework:**
1. **Delete** - Remove immediately if no value
2. **Do** - If it takes <2 minutes, handle now
3. **Delegate** - Forward to appropriate person
4. **Defer** - Schedule for later with context preserved

**Key Philosophy Shifts:**
- Inbox is a **processing queue**, not a storage system
- Every email requires a **decision**, not just reading
- Labels/folders are for **retrieval**, not organization
- Archive aggressively - search is powerful enough to find anything

### What Stays in Inbox

**Keep in Inbox (Action Required):**
| Criteria | Examples |
|----------|----------|
| Requires your response | Direct questions, requests for input |
| Has a deadline within 48 hours | Meeting confirmations, urgent approvals |
| Blocking someone else's work | Approvals, sign-offs, feedback requests |
| Financial/legal requiring action | Bills to pay, contracts to sign |
| Calendar-related requiring RSVP | Event invitations needing response |

**Archive Immediately (FYI/Reference):**
| Criteria | Examples |
|----------|----------|
| Informational only | Newsletters, announcements, status updates |
| Already handled | Sent confirmations, automated receipts |
| CC'd for awareness | Team discussions where you're not primary |
| Automated notifications | GitHub, Jira, shipping updates |
| Promotional content | Marketing emails, offers |

### Time-Based Rules

```
Inbox Aging Policy:
├── 0-24 hours: Active processing window
├── 24-72 hours: Review for stuck items
├── 72+ hours: Auto-archive with "Stale" label
└── 7+ days: Force archive, create reminder if actionable
```

**Rationale:** If you haven't acted on an email in 72 hours, either:
1. It wasn't actually important
2. You need a different system (task manager, calendar)
3. It requires explicit scheduling (snooze equivalent)

### Priority Inbox Concept

**Three-Tier Priority Model:**

| Priority | Trigger Conditions | Treatment |
|----------|-------------------|-----------|
| **P1 - Urgent** | Known VIP sender, contains deadline keywords, reply-to-your-sent | Push notification, stays in inbox |
| **P2 - Important** | Direct recipient (not CC), from known contact, contains action words | No notification, inbox review |
| **P3 - Low** | Bulk sender, CC'd, automated, promotional | Auto-archive with label, daily digest |

---

## Automation Rules

### Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│                    EMAIL ARRIVES                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Is it spam/junk │──Yes──▶ [DELETE/SPAM]
                    └─────────────────┘
                              │ No
                              ▼
                    ┌─────────────────┐
                    │ Is it automated │──Yes──┬──▶ Is it actionable?
                    │ (newsletter,    │       │         │
                    │  notification)  │       │    Yes  │  No
                    └─────────────────┘       │    ▼    ▼
                              │ No            │  [INBOX] [ARCHIVE+LABEL]
                              ▼               │
                    ┌─────────────────┐       │
                    │ Am I primary    │──No───┤
                    │ recipient (To:) │       │
                    └─────────────────┘       │
                              │ Yes           │
                              ▼               │
                    ┌─────────────────┐       │
                    │ From VIP/known  │──Yes──▶ [INBOX + P1 NOTIFY]
                    │ important sender│
                    └─────────────────┘
                              │ No
                              ▼
                    ┌─────────────────┐
                    │ Contains action │──Yes──▶ [INBOX + P2]
                    │ request/deadline│
                    └─────────────────┘
                              │ No
                              ▼
                    ┌─────────────────┐
                    │ Part of active  │──Yes──▶ [INBOX]
                    │ thread I started│
                    └─────────────────┘
                              │ No
                              ▼
                         [ARCHIVE + LABEL]
```

### Urgency Detection Patterns

**High-Confidence Urgency Signals:**

```javascript
const urgencyPatterns = {
  // Time-based keywords
  temporal: [
    /\b(urgent|asap|immediately|today|tonight|by (end of day|EOD|COB))\b/i,
    /\b(deadline|due|expires?|last chance|final)\b/i,
    /\bwithin \d+ (hour|minute|day)s?\b/i,
  ],

  // Action-required phrases
  actionRequired: [
    /\b(action required|response needed|please (confirm|reply|respond))\b/i,
    /\b(waiting (on|for) (you|your)|need your (input|approval|signature))\b/i,
    /\b(can you|could you|would you).*(by|before|today)\b/i,
  ],

  // Relationship signals
  relational: [
    /\b(boss|manager|CEO|CTO|director|VP)\b/i,  // Title mentions
    /\b(escalat(e|ed|ing)|critical|emergency|crisis)\b/i,
  ],

  // Financial/legal
  highStakes: [
    /\b(payment|invoice|overdue|past due|account|legal|contract)\b/i,
    /\b(security|breach|compromise|unauthorized|fraud)\b/i,
  ]
};
```

**Context Modifiers (Reduce False Positives):**

```javascript
const urgencyDampeners = {
  // Newsletter/marketing context
  marketing: [
    /\b(unsubscribe|opt.out|email preferences)\b/i,
    /\b(limited time offer|sale ends|don't miss)\b/i,  // Fake urgency
  ],

  // Automated notifications
  automated: [
    /\b(no.reply|donotreply|automated|notification)\b/i,
    /\b(this is an automated|do not reply to this)\b/i,
  ],

  // FYI signals
  informational: [
    /\b(fyi|for your (information|records|reference))\b/i,
    /\b(no action (needed|required)|just (letting you know|fyi))\b/i,
  ]
};
```

### Handling Future Actions (Snooze Equivalent)

Since Gmail's native snooze isn't accessible via API, implement with labels:

**Snooze System Architecture:**

```
Labels:
├── _Snooze/Tomorrow
├── _Snooze/NextWeek
├── _Snooze/NextMonth
├── _Snooze/Someday
└── _Snooze/WaitingFor
```

**Workflow Logic:**

```javascript
// When AI detects "future action needed"
const snoozeBehavior = {
  // Detected patterns -> snooze label
  patterns: {
    "meeting next week": "_Snooze/NextWeek",
    "review before [date]": calculateSnoozeLabel(date),
    "waiting for response from": "_Snooze/WaitingFor",
    "think about later": "_Snooze/Someday",
  },

  // Archive but preserve for resurface
  action: {
    removeFromInbox: true,
    addLabel: snoozeLabel,
    addLabel: "AutoSnoozed",  // For tracking
  }
};

// Periodic workflow (runs daily at 6 AM)
const resurfaceLogic = {
  "_Snooze/Tomorrow": "Move to inbox if labeledDate < today",
  "_Snooze/NextWeek": "Move to inbox if labeledDate + 7 days <= today",
  // ... etc
};
```

### Thread Handling

**Thread Classification Rules:**

| Scenario | Detection | Action |
|----------|-----------|--------|
| New thread to you | No In-Reply-To header, you in To: | Full classification |
| Reply to your sent | In-Reply-To matches your Message-ID | P1, inbox |
| Thread you're watching | Thread ID in "watching" list | Inbox |
| Thread you left | Previous reply from you, now CC'd | Archive with label |
| FYI addition | Added to CC mid-thread | Archive unless @mentioned |

**Thread State Machine:**

```
States: [New] → [Active] → [Waiting] → [Resolved] → [Archived]

Transitions:
- New → Active: You open/read
- Active → Waiting: You replied, awaiting response
- Waiting → Active: New reply received
- Active → Resolved: Detected closure phrases
- Resolved → Archived: 24h after resolution
- Any → Archived: Manual archive or 7-day timeout
```

---

## n8n Workflows

### Main Categorization Workflow

**Workflow: Email Triage Bot**

```
Trigger: Gmail Trigger (Poll every 1 minute)
         └── Filter: Label = INBOX, is:unread

┌─────────────────────────────────────────────────────────────────┐
│  1. FETCH EMAIL DETAILS                                         │
├─────────────────────────────────────────────────────────────────┤
│  Gmail Node: Get Message                                        │
│  - Fetch full message (headers, body, attachments list)         │
│  - Extract: From, To, CC, Subject, Date, Thread-ID              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. PREPROCESS & EXTRACT SIGNALS                                │
├─────────────────────────────────────────────────────────────────┤
│  Code Node (JavaScript):                                        │
│  - Clean HTML → plain text                                      │
│  - Detect sender type (human vs automated)                      │
│  - Extract links, detect unsubscribe presence                   │
│  - Check against VIP list (stored in n8n static data)           │
│  - Truncate body to ~2000 chars for AI                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. AI CLASSIFICATION                                           │
├─────────────────────────────────────────────────────────────────┤
│  HTTP Request Node (Claude API):                                │
│  POST https://api.anthropic.com/v1/messages                     │
│                                                                 │
│  Prompt Template:                                               │
│  """                                                            │
│  Classify this email. Respond in JSON only.                     │
│                                                                 │
│  Email:                                                         │
│  From: {{from}}                                                 │
│  To: {{to}}                                                     │
│  Subject: {{subject}}                                           │
│  Body: {{body_truncated}}                                       │
│                                                                 │
│  Respond with:                                                  │
│  {                                                              │
│    "category": "<primary category>",                            │
│    "subcategory": "<specific type>",                            │
│    "priority": "P1|P2|P3",                                      │
│    "action_type": "respond|review|archive|delete",              │
│    "urgency_score": 1-10,                                       │
│    "is_automated": true|false,                                  │
│    "requires_response": true|false,                             │
│    "suggested_snooze": "none|tomorrow|next_week|someday",       │
│    "confidence": 0.0-1.0,                                       │
│    "reasoning": "<brief explanation>"                           │
│  }                                                              │
│                                                                 │
│  Categories: Finance, Work, Personal, Shopping, Travel,         │
│              Notifications, Newsletters, Social, Receipts,      │
│              Security, Calendar, Support                        │
│  """                                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. APPLY ACTIONS                                               │
├─────────────────────────────────────────────────────────────────┤
│  Switch Node (based on action_type):                            │
│                                                                 │
│  Case "respond" (P1):                                           │
│    → Add label: "Category/{{category}}"                         │
│    → Add label: "Priority/P1"                                   │
│    → Keep in inbox                                              │
│    → Optional: Send push notification                           │
│                                                                 │
│  Case "review" (P2):                                            │
│    → Add label: "Category/{{category}}"                         │
│    → Add label: "Priority/P2"                                   │
│    → Keep in inbox                                              │
│                                                                 │
│  Case "archive":                                                │
│    → Add label: "Category/{{category}}"                         │
│    → Add label: "AutoArchived"                                  │
│    → Remove from inbox (archive)                                │
│    → Mark as read (optional)                                    │
│                                                                 │
│  Case "delete":                                                 │
│    → Move to trash (or archive with "Junk" label)               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. LOG & LEARN                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Google Sheets Node (or Database):                              │
│  - Log: timestamp, message_id, from, subject, classification    │
│  - Track: confidence scores for review                          │
│  - Enable: correction feedback loop                             │
└─────────────────────────────────────────────────────────────────┘
```

**n8n JSON Snippet (Core Classification):**

```json
{
  "nodes": [
    {
      "name": "Gmail Trigger",
      "type": "n8n-nodes-base.gmailTrigger",
      "parameters": {
        "pollTimes": {
          "item": [{ "mode": "everyMinute" }]
        },
        "filters": {
          "q": "is:unread in:inbox"
        }
      }
    },
    {
      "name": "AI Classify",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "headers": {
          "x-api-key": "={{$credentials.anthropicApi.apiKey}}",
          "anthropic-version": "2023-06-01",
          "content-type": "application/json"
        },
        "body": {
          "model": "claude-3-haiku-20240307",
          "max_tokens": 500,
          "messages": [{
            "role": "user",
            "content": "={{$node['Build Prompt'].json.prompt}}"
          }]
        }
      }
    },
    {
      "name": "Apply Labels",
      "type": "n8n-nodes-base.gmail",
      "parameters": {
        "operation": "addLabels",
        "messageId": "={{$node['Gmail Trigger'].json.id}}",
        "labelIds": "={{$node['Parse AI Response'].json.labels}}"
      }
    }
  ]
}
```

### Periodic Cleanup Workflow

**Workflow: Inbox Hygiene (Runs Daily at 6 AM)**

```
┌─────────────────────────────────────────────────────────────────┐
│  SCHEDULE TRIGGER: Cron (0 6 * * *)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ STALE EMAIL     │ │ SNOOZE          │ │ WAITING-FOR     │
│ CLEANUP         │ │ RESURFACE       │ │ CHECK           │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ Query: in:inbox │ │ Query: label:   │ │ Query: label:   │
│ older_than:3d   │ │ _Snooze/*       │ │ WaitingFor      │
│                 │ │ older_than:Xd   │ │ older_than:7d   │
│ Action:         │ │                 │ │                 │
│ - Add: Stale    │ │ Action:         │ │ Action:         │
│ - Archive       │ │ - Move to inbox │ │ - Send reminder │
│ - Log for review│ │ - Remove snooze │ │   or escalate   │
│                 │ │   label         │ │                 │
└─────────────────┘ └─────────────────┘ └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CLEANUP METRICS                                                │
├─────────────────────────────────────────────────────────────────┤
│  Log to Google Sheets:                                          │
│  - Emails processed today                                       │
│  - Stale emails archived                                        │
│  - Snoozes resurfaced                                           │
│  - Current inbox count                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Daily Digest Workflow

**Workflow: Morning Briefing (Runs Daily at 7 AM)**

```
┌─────────────────────────────────────────────────────────────────┐
│  SCHEDULE TRIGGER: Cron (0 7 * * *)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GATHER OVERNIGHT ACTIVITY                                      │
├─────────────────────────────────────────────────────────────────┤
│  Gmail Search Queries (parallel):                               │
│  1. "in:inbox newer_than:1d" → New inbox items                  │
│  2. "label:AutoArchived newer_than:1d" → Auto-processed         │
│  3. "label:Priority/P1 is:unread" → Urgent unread               │
│  4. "from:VIP-list newer_than:1d" → VIP activity                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  AI SUMMARIZATION                                               │
├─────────────────────────────────────────────────────────────────┤
│  Prompt:                                                        │
│  """                                                            │
│  Create a morning email briefing from this data:                │
│                                                                 │
│  NEW IN INBOX ({{inbox_count}}):                                │
│  {{inbox_items_summary}}                                        │
│                                                                 │
│  AUTO-ARCHIVED ({{archived_count}}):                            │
│  {{archived_summary}}                                           │
│                                                                 │
│  URGENT/UNREAD:                                                 │
│  {{urgent_items}}                                               │
│                                                                 │
│  Format as:                                                     │
│  1. Top 3 priorities for today                                  │
│  2. Brief summary of auto-archived (grouped by category)        │
│  3. Anything requiring same-day response                        │
│  4. FYI items of interest                                       │
│  """                                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  DELIVER DIGEST                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Options (choose based on preference):                          │
│  - Email to self (Gmail Send)                                   │
│  - Push notification (Pushover/Pushbullet)                      │
│  - Slack/Discord message                                        │
│  - iOS Shortcut trigger                                         │
└─────────────────────────────────────────────────────────────────┘
```

**Digest Output Example:**

```markdown
## Morning Email Briefing - Jan 28, 2026

### Requires Action Today (3)
1. **[Finance]** Invoice #4521 from Vendor - Due today
2. **[Work]** PR Review requested by @teammate - "Critical fix"
3. **[Personal]** Flight confirmation needs seat selection

### Auto-Processed Overnight (47)
- Newsletters: 12 (TechCrunch, Morning Brew, etc.)
- Notifications: 23 (GitHub, Jira, AWS)
- Receipts: 5 (Amazon, DoorDash)
- Promotions: 7 (archived, no action)

### VIP Activity
- Boss sent 2 emails (both auto-archived as FYI)
- Client ABC replied to proposal thread

### Quick Stats
- Current inbox: 8 items
- Processed this week: 312 emails
- Auto-archive rate: 87%
```

### Unsubscribe Detection Workflow

**Workflow: Newsletter Management**

```
┌─────────────────────────────────────────────────────────────────┐
│  TRIGGER: New email with "List-Unsubscribe" header              │
│  OR: AI classification = "Newsletter" with confidence > 0.9     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CHECK ENGAGEMENT HISTORY                                       │
├─────────────────────────────────────────────────────────────────┤
│  Query Google Sheets / Database:                                │
│  - How many emails from this sender in 30 days?                 │
│  - How many were opened/read?                                   │
│  - Was any ever moved back to inbox manually?                   │
│  - Click-through rate (if tracking links)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  DECISION LOGIC                                                 │
├─────────────────────────────────────────────────────────────────┤
│  IF:                                                            │
│    - >10 emails/month AND <10% open rate AND                    │
│    - Never manually rescued from archive                        │
│  THEN:                                                          │
│    → Add to "Unsubscribe Candidates" list                       │
│    → Weekly: Present list for bulk unsubscribe decision         │
│                                                                 │
│  ELSE IF:                                                       │
│    - 1-5 emails/month AND sometimes read                        │
│  THEN:                                                          │
│    → Keep subscribed, continue auto-archive                     │
│                                                                 │
│  ELSE IF:                                                       │
│    - User manually moved to inbox in past                       │
│  THEN:                                                          │
│    → Mark as "Valued Newsletter", don't auto-archive            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  WEEKLY UNSUBSCRIBE REVIEW                                      │
├─────────────────────────────────────────────────────────────────┤
│  Send summary email:                                            │
│  "You received 47 emails from these senders this week           │
│   but never opened them. Unsubscribe?"                          │
│                                                                 │
│  [Sender A] - 12 emails, 0 opened - [Keep] [Unsub]              │
│  [Sender B] - 8 emails, 0 opened - [Keep] [Unsub]               │
│  ...                                                            │
│                                                                 │
│  User clicks link → triggers n8n webhook →                      │
│  auto-unsubscribe via List-Unsubscribe header                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## User Experience

### Label Navigation (Mobile-Friendly)

**Label Hierarchy Design:**

```
📁 Email Labels
├── 📁 Category/
│   ├── Finance
│   ├── Work
│   ├── Personal
│   ├── Shopping
│   ├── Travel
│   ├── Notifications
│   ├── Newsletters
│   └── Social
├── 📁 Priority/
│   ├── P1-Urgent
│   ├── P2-Important
│   └── P3-Low
├── 📁 Status/
│   ├── ActionRequired
│   ├── WaitingFor
│   ├── Delegated
│   └── Reference
├── 📁 _Snooze/
│   ├── Tomorrow
│   ├── NextWeek
│   └── Someday
└── 📁 _System/
    ├── AutoArchived
    ├── AutoLabeled
    ├── LowConfidence
    └── Processed
```

**Mobile Optimization Principles:**

1. **Prefix with emoji for visual scanning** (optional, some prefer clean)
2. **Use "/" hierarchy** - Gmail collapses these on mobile
3. **Keep top-level labels under 10** - prevents scroll fatigue
4. **Most-used labels first** - Gmail sorts alphabetically, use "!" prefix for priority

**Quick Access Shortcuts:**

| Action | Gmail Search | Purpose |
|--------|--------------|---------|
| Today's priority | `in:inbox label:Priority/P1` | Morning review |
| Needs response | `label:Status/ActionRequired` | Action queue |
| Recent from VIP | `from:(vip1 OR vip2) newer_than:7d` | VIP catch-up |
| Auto-archived today | `label:AutoArchived newer_than:1d` | Audit automation |
| Low confidence | `label:_System/LowConfidence` | Review AI mistakes |

### Quick Review Workflows

**Daily Review Ritual (5 minutes):**

```
1. Open Priority/P1 label → Handle or defer each
2. Scan inbox count → Should be <10 if healthy
3. Check AutoArchived/LowConfidence → Rescue any mistakes
4. Quick scan of VIP filter → Ensure nothing missed
```

**Weekly Review (15 minutes):**

```
1. Review "Stale" labeled items → Decide or delete
2. Check Unsubscribe Candidates → Clean up subscriptions
3. Review WaitingFor → Follow up or close
4. Audit auto-archive accuracy → Adjust VIP list if needed
```

### Notification Filtering

**Push Notification Rules:**

```javascript
const notificationRules = {
  // SEND notification
  notify: {
    conditions: [
      "priority === 'P1'",
      "from in VIP_LIST && requires_response",
      "urgency_score >= 8",
      "contains('urgent', 'emergency', 'asap')"
    ],
    channels: ["push", "sms_if_after_hours"]
  },

  // SILENT (no notification)
  silent: {
    conditions: [
      "is_automated === true",
      "category in ['Newsletter', 'Promotion', 'Notification']",
      "I am CC'd, not To'd",
      "confidence < 0.7"  // Don't notify on uncertain classifications
    ]
  },

  // BATCH (daily digest only)
  batch: {
    conditions: [
      "priority === 'P3'",
      "category === 'Receipts'",
      "is_automated && requires_no_action"
    ]
  }
};
```

**Implementation in n8n:**

```json
{
  "name": "Send Push Notification",
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "boolean": [
        {
          "value1": "={{$json.priority}}",
          "value2": "P1"
        }
      ]
    }
  },
  "onTrue": {
    "type": "n8n-nodes-base.pushover",
    "parameters": {
      "message": "Urgent: {{$json.subject}} from {{$json.from}}",
      "priority": 1
    }
  }
}
```

### Feedback Mechanism for Corrections

**Correction Flow:**

```
User moves email FROM archive TO inbox (manual action)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GMAIL TRIGGER: Label change detected                           │
│  (label:INBOX added to previously archived message)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  LOG CORRECTION                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Record in feedback database:                                   │
│  - Message ID                                                   │
│  - Original classification                                      │
│  - User action: "rescued from archive"                          │
│  - Timestamp                                                    │
│  - Sender domain/address                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ANALYZE PATTERN                                                │
├─────────────────────────────────────────────────────────────────┤
│  IF same sender rescued 3+ times:                               │
│    → Add sender to VIP/important list                           │
│    → Future emails stay in inbox                                │
│                                                                 │
│  IF same category consistently rescued:                         │
│    → Adjust category → action mapping                           │
│    → Alert user: "Noticed you keep rescuing [category]..."      │
└─────────────────────────────────────────────────────────────────┘
```

**Explicit Feedback Interface:**

Option 1: **Email-based feedback**
- Weekly email: "Were these classifications correct?"
- Reply with numbers to correct (e.g., "1, 3, 7 wrong")

Option 2: **Webhook + Simple Web UI**
- n8n webhook serves simple HTML page
- Shows recent classifications
- Toggle buttons: "Correct" / "Wrong"
- Corrections feed back into prompt or rules

Option 3: **Label-based feedback**
- User adds "WronglyArchived" label
- System detects and logs
- No additional UI needed

---

## Edge Cases

### Recovery Patterns

#### Misclassified Important Emails

**Problem:** AI archived something that needed action.

**Recovery Strategy:**

```
┌─────────────────────────────────────────────────────────────────┐
│  SAFETY NET: Low Confidence Review                              │
├─────────────────────────────────────────────────────────────────┤
│  IF AI confidence < 0.75:                                       │
│    → Archive as usual BUT                                       │
│    → Add label: "_System/LowConfidence"                         │
│    → Include in daily digest for manual review                  │
│                                                                 │
│  Daily digest section:                                          │
│  "These were auto-archived but AI was uncertain:"               │
│  - [Subject] from [Sender] - Confidence: 68%                    │
│  - [Subject] from [Sender] - Confidence: 71%                    │
└─────────────────────────────────────────────────────────────────┘
```

**Recovery Actions:**

1. **Immediate:** Search `label:AutoArchived newer_than:1d` daily
2. **Sender whitelist:** If rescued, add sender to VIP list
3. **Pattern learning:** Log corrections, review weekly for prompt tuning
4. **Audit trail:** Keep 30 days of classification logs for debugging

#### "Show Me Everything From Sender X"

**Query Pattern:**

```
Gmail search: from:sender@domain.com
             OR from:*@domain.com (for entire domain)

With date range: from:sender@domain.com newer_than:30d
With labels: from:sender@domain.com label:Category/Work
```

**n8n Webhook Implementation:**

```
Webhook URL: https://your-n8n.domain/webhook/sender-search
Parameters: ?sender=email@domain.com&days=30

Workflow:
1. Receive webhook with sender parameter
2. Gmail search: from:{sender} newer_than:{days}d
3. Return JSON with message list
4. Optional: Generate summary via AI
```

#### Undo/Correction Workflows

**Pattern: Undo Last Archive**

```javascript
// Store last N actions in n8n static data or Redis
const actionHistory = [
  { messageId: "abc123", action: "archive", labels: ["Work"], timestamp: "..." },
  { messageId: "def456", action: "archive", labels: ["Newsletter"], timestamp: "..." },
  // ...
];

// Webhook: /undo-last
// Reverses most recent action
async function undoLast() {
  const lastAction = actionHistory.pop();
  if (lastAction.action === "archive") {
    await gmail.messages.modify({
      id: lastAction.messageId,
      addLabelIds: ["INBOX"],
      // Optionally remove auto-applied labels
    });
  }
  return { undone: lastAction };
}
```

**Pattern: Bulk Undo by Time Window**

```
"Undo all auto-archives from last hour"

Gmail search: label:AutoArchived newer_than:1h
Action: Add INBOX label to all results
```

#### Thread Topic Changes

**Problem:** Email thread starts as "Lunch tomorrow?" and evolves into "Project deadline discussion."

**Detection Strategies:**

```javascript
const topicChangeDetection = {
  // Strategy 1: Subject line change
  subjectDrift: {
    detect: "Subject changed significantly from thread start",
    example: "Re: Lunch → Re: URGENT: Project deadline",
    action: "Re-classify new message independently"
  },

  // Strategy 2: Semantic drift
  semanticDrift: {
    detect: "AI detects topic shift in content",
    prompt: `
      Original thread topic: {{first_message_summary}}
      New message: {{new_message}}

      Has the topic changed significantly?
      If yes, what's the new topic and priority?
    `,
    action: "Apply new classification labels alongside thread labels"
  },

  // Strategy 3: Urgency escalation
  urgencyEscalation: {
    detect: "Thread was P3, new message contains urgency signals",
    action: "Upgrade thread priority, move to inbox if archived"
  }
};
```

**Implementation:**

```
For each new message in existing thread:
1. Compare new subject to original thread subject
2. If >30% different (fuzzy match), flag for re-evaluation
3. Run AI classification on new message alone
4. If new priority > thread priority, escalate
5. If topic significantly different, apply additional labels
```

---

## Key Recommendations

### Prioritized Implementation Roadmap

#### Phase 1: Foundation (Week 1)
1. **Set up Gmail label structure** - Create hierarchy as defined above
2. **Build basic classification workflow** - Trigger → AI → Label → Archive
3. **Establish VIP list** - Manual list of must-see senders
4. **Simple logging** - Google Sheet for all classifications

#### Phase 2: Intelligence (Week 2)
5. **Tune AI prompt** - Iterate based on classification logs
6. **Add confidence thresholds** - Low confidence stays in inbox
7. **Implement urgency detection** - Regex + AI combined
8. **Build daily digest** - Morning summary email

#### Phase 3: Automation (Week 3)
9. **Snooze system** - Labels + periodic resurface workflow
10. **Feedback loop** - Track corrections, auto-update VIP list
11. **Stale email cleanup** - Auto-archive after 72 hours
12. **Unsubscribe detection** - Track engagement, suggest cleanup

#### Phase 4: Polish (Week 4)
13. **Push notifications** - P1 only, with quiet hours
14. **Undo mechanism** - Webhook for quick reversal
15. **Dashboard** - Weekly stats, accuracy metrics
16. **Thread handling** - Topic change detection

### Critical Success Factors

| Factor | Why It Matters | How to Achieve |
|--------|----------------|----------------|
| **Conservative archiving initially** | False negatives (missing important) worse than false positives | Start with high confidence threshold (0.85+), lower over time |
| **Fast feedback loop** | Catches mistakes early, builds trust | Daily low-confidence review, easy correction mechanism |
| **VIP list maintenance** | Some senders always matter | Auto-add after 2+ manual rescues |
| **Audit trail** | Debug issues, prove system works | Log everything to Google Sheets for 30 days |
| **Gradual rollout** | Builds confidence, catches issues | Start with 10% of emails, expand weekly |

### Cost Optimization

```
Estimated monthly costs (1000 emails/day):

Claude Haiku: ~$2-4/month
- Input: ~500 tokens/email × 30K emails × $0.25/1M = $3.75
- Output: ~100 tokens/email × 30K emails × $1.25/1M = $3.75

Optimization strategies:
1. Skip classification for known automated senders (saves 40-60%)
2. Cache sender → category mappings (saves 20-30%)
3. Batch process during off-peak (no cost savings, but faster)
4. Use regex pre-filters before AI (saves 10-20% of API calls)
```

### Metrics to Track

```
Daily:
- Emails processed
- Auto-archive rate
- Manual rescues (corrections)
- P1 accuracy (did urgent emails reach inbox?)

Weekly:
- Classification accuracy by category
- False positive rate (archived but should have stayed)
- False negative rate (inbox but should have archived)
- Time to inbox zero (if tracking)

Monthly:
- Unsubscribe candidates identified
- Total emails reduced via unsub
- Cost per email processed
- User satisfaction (if surveyed)
```

---

## Appendix: AI Prompt Template (Production-Ready)

```
You are an email triage assistant. Classify the following email and respond ONLY with valid JSON.

## Email Details
From: {{from}}
To: {{to}}
CC: {{cc}}
Subject: {{subject}}
Date: {{date}}
Body (truncated):
{{body}}

## Classification Rules
1. **Priority P1 (Urgent)**: Requires response within 24 hours, from known important contacts, contains deadline today/tomorrow, financial/legal urgency
2. **Priority P2 (Important)**: Requires action but not urgent, direct requests, meeting-related
3. **Priority P3 (Low)**: Informational, automated notifications, newsletters, promotions, receipts

## Response Format
{
  "category": "Finance|Work|Personal|Shopping|Travel|Notifications|Newsletters|Social|Receipts|Security|Calendar|Support|Other",
  "priority": "P1|P2|P3",
  "action": "keep_inbox|archive|archive_and_label",
  "is_automated": true|false,
  "requires_response": true|false,
  "urgency_score": <1-10>,
  "confidence": <0.0-1.0>,
  "reasoning": "<one sentence explanation>"
}

## Important
- Marketing emails with fake urgency ("Last chance!") are P3, not P1
- Emails where user is CC'd (not To'd) are usually P3
- Thread replies to user's sent emails are P2 minimum
- Security alerts (password reset, login notification) are P1 if not self-initiated
- Receipts/confirmations with no action needed are P3

Respond with JSON only, no additional text.
```

---

*This research document provides patterns and recommendations. Actual implementation should be adapted based on personal email volume, patterns, and preferences.*
