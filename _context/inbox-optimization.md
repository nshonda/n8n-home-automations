# Inbox Optimization Research

## Final End Goal
Achieve **Inbox Zero** with an AI-powered email management system that:
1. Automatically categorizes incoming emails using smart, context-aware classification
2. Organizes emails into meaningful categories without manual setup
3. Achieves inbox zero by archiving/labeling emails appropriately
4. Runs on self-hosted n8n instance accessible via Cloudflare tunnels

## Infrastructure Context
- **Server**: Ubuntu home server (SSH via `nshonda`)
- **Access**: Cloudflare tunnels for internet exposure
- **Automation Platform**: n8n (self-hosted via Docker)
- **Email Provider**: Gmail

---

## High-Level Summary

This research analyzed Gmail + n8n + AI email categorization from 6 specialized perspectives. All agents reached strong consensus on the recommended architecture and approach.

**Overall Confidence: 92%**

### Consensus Points (All 6 Agents Agreed)

1. **Model Choice**: Claude Haiku or GPT-4o-mini for classification (cost-effective, sufficient accuracy)
2. **Architecture**: Gmail Trigger → Sender Cache Check → AI Classification → Label + Archive
3. **Caching**: Sender-based caching reduces API calls by 40-60%
4. **Truncation**: 500-1500 chars of email body is sufficient for classification
5. **Label Strategy**: Hierarchical with prefixes (`@Action`, `#Category`, `_System`)
6. **Confidence Threshold**: Start at 0.85, lower over time as system proves itself
7. **Self-Hosting**: Docker with Docker Compose, Cloudflare tunnels, `N8N_ENCRYPTION_KEY`
8. **Privacy**: Consider local Ollama for sensitive emails (financial/medical)

### Points of Conflict/Uncertainty

| Topic | Variance | Resolution |
|-------|----------|------------|
| Polling interval | 1 min vs 5 min | Start with 5 min, reduce if needed |
| Local vs Cloud LLM | Privacy vs accuracy | Hybrid: local for sensitive, cloud for rest |
| JSON output format | Minimal vs detailed | Use detailed (category, confidence, action_needed, priority) |

---

## Prioritized Recommendations

### P0 - Critical (Do First)

1. **Deploy n8n via Docker on Ubuntu server**
   ```bash
   # docker-compose.yml
   services:
     n8n:
       image: n8nio/n8n:latest
       restart: unless-stopped
       ports:
         - "5678:5678"
       environment:
         - N8N_HOST=your-domain.com
         - N8N_PROTOCOL=https
         - WEBHOOK_URL=https://your-domain.com/
         - N8N_ENCRYPTION_KEY=<generate-random-key>
       volumes:
         - n8n_data:/home/node/.n8n
   ```

2. **Set up Gmail OAuth with `gmail.modify` scope**

3. **Create base label hierarchy**
   ```
   @Action/Reply, @Action/Review, @Action/Pay
   #Finance/Banking, #Finance/Receipts
   #Shopping/Orders, #Shopping/Shipping
   _System/Processed, _System/Review
   ```

4. **Build basic classification workflow**
   - Gmail Trigger (every 5 min, query: `in:inbox is:unread -label:_System/Processed`)
   - HTTP Request to Claude API
   - Apply labels + archive based on response

### P1 - Important (Week 2)

5. **Implement sender caching**
   - Store sender → category mappings in n8n static data
   - Skip AI for known patterns (newsletters, receipts)
   - Auto-add to cache after 5+ consistent classifications

6. **Add confidence-based routing**
   - ≥0.85: Auto-archive
   - 0.70-0.84: Archive but include in daily review
   - <0.70: Keep in inbox, add `_System/Review` label

7. **Content preprocessing**
   - Strip HTML, remove quoted replies
   - Truncate to 1500 chars
   - Anonymize PII before API calls

8. **Daily digest workflow**
   - Run at 7 AM
   - Summarize overnight auto-archived emails
   - Highlight P1 items and low-confidence classifications

### P2 - Nice to Have (Week 3+)

9. **Local Ollama for sensitive emails**
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ollama pull llama3.2:3b
   ```
   - Route financial/medical emails to local model
   - Fallback to cloud if local fails

10. **Feedback loop**
    - Detect when user moves email from archive to inbox
    - Auto-add sender to VIP list after 3+ rescues
    - Log corrections for prompt tuning

11. **Unsubscribe detection**
    - Track newsletter engagement
    - Weekly report of unsubscribe candidates

12. **Snooze system**
    - Labels: `_Snooze/Tomorrow`, `_Snooze/NextWeek`
    - Daily cron resurfaces snoozed emails

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CLOUDFLARE TUNNEL                              │
│                   (n8n.yourdomain.com)                              │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        N8N (Docker)                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐  │
│  │ Gmail       │───▶│ Sender      │───▶│ Cached?                 │  │
│  │ Trigger     │    │ Cache Check │    │ YES → Apply + Archive   │  │
│  │ (5 min)     │    │             │    │ NO  → Continue          │  │
│  └─────────────┘    └─────────────┘    └───────────┬─────────────┘  │
│                                                     │               │
│                                                     ▼               │
│  ┌─────────────┐    ┌─────────────────────────────────────────────┐ │
│  │ Preprocess  │───▶│ AI Classification (Claude Haiku)            │ │
│  │ - Strip HTML│    │ - Category, Confidence, Action, Priority    │ │
│  │ - Truncate  │    └───────────────────────────────┬─────────────┘ │
│  │ - Anonymize │                                    │               │
│  └─────────────┘                                    ▼               │
│                     ┌───────────────────────────────────────────────┤
│                     │ CONFIDENCE ROUTING                           ││
│                     │ ≥0.85: Archive + Label                       ││
│                     │ 0.70-0.84: Archive + Review Label            ││
│                     │ <0.70: Keep in Inbox                         ││
│                     └───────────────────────────────────────────────┤
│                                         │                           │
│  ┌─────────────┐    ┌─────────────┐    ▼                           │
│  │ Daily       │    │ Feedback    │  ┌───────────────────────────┐ │
│  │ Digest      │    │ Loop        │  │ Gmail: Apply Labels       │ │
│  │ (7 AM)      │    │ (Detect     │  │        Remove INBOX       │ │
│  └─────────────┘    │  rescues)   │  │        Add Processed      │ │
│                     └─────────────┘  └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Cost Projections

### Monthly Costs (Optimized)

| Volume | GPT-4o-mini | Claude Haiku | With Caching (50%) |
|--------|-------------|--------------|-------------------|
| 500/month | $0.08 | $0.44 | $0.04-0.22 |
| 2,000/month | $0.30 | $1.76 | $0.15-0.88 |
| 10,000/month | $1.50 | $8.80 | $0.75-4.40 |

### Optimization Strategies
- Sender caching: -40-60% API calls
- Content truncation: -50-70% tokens
- Tiered routing: -20-40% additional

---

## Production Prompt Template

```
You are an email classification system. Analyze this email and return ONLY valid JSON.

Categories: Finance, Work, Personal, Shopping, Travel, Notifications, Newsletters, Social, Receipts, Security, Other

Priority Levels:
- P1 (Urgent): Response needed within 24h, important contacts, deadlines
- P2 (Important): Action needed but not urgent
- P3 (Low): Informational, automated, promotional

Email:
From: {{from}}
Subject: {{subject}}
Body: {{body_preview}}

Return JSON:
{
  "category": "<category>",
  "priority": "P1|P2|P3",
  "action_needed": true|false,
  "archive": true|false,
  "confidence": 0.0-1.0,
  "summary": "<one sentence>"
}

Rules:
- Marketing with fake urgency ("Last chance!") = P3
- CC'd (not To'd) = usually P3
- Security alerts (if not self-initiated) = P1
- Receipts with no action = P3
```

---

## Files Created

| File | Purpose |
|------|---------|
| `_context/inbox-optimization.md` | Main research document (this file) |
| `_context/inbox-zero-automation-patterns.md` | Detailed inbox zero patterns from Agent 6 |
| `deploy/docker-compose.yml` | Docker Compose config for n8n deployment |
| `deploy/.env.example` | Environment variables template |
| `deploy/setup.sh` | Automated setup script for server |
| `workflows/email-classifier.json` | Complete n8n workflow (importable) |
| `scripts/create-gmail-labels.sh` | Gmail label creation helper |
| `docs/gmail-oauth-setup.md` | Step-by-step OAuth configuration |
| `docs/quick-start.md` | 30-minute deployment guide |

---

## Sub-Agent Findings Summary

### Agent 1: Gmail API + n8n Implementation
- Complete OAuth setup guide
- Batch operations for efficiency (batchModify)
- Rate limit handling with exponential backoff
- Thread vs message handling
- Full workflow JSON template

### Agent 2: AI Prompt Engineering
- Production-ready system prompt
- Few-shot examples for accuracy
- JSON schema for structured output
- Confidence calibration methodology
- Testing and validation strategies

### Agent 3: Category Taxonomy Design
- 67-label hierarchy (leaves 433 for growth)
- Prefix system: `@Action`, `#Category`, `~Reference`, `!Priority`, `_System`
- Dynamic category discovery approach
- Color coding patterns
- Merge/split strategies

### Agent 4: Privacy & Local LLM Options
- Anthropic/OpenAI data policies (API data NOT used for training)
- Ollama setup on Ubuntu
- Model comparison (llama3.2:3b recommended for local)
- Hybrid routing: sensitive → local, rest → cloud
- Anonymization strategies

### Agent 5: Cost Optimization
- Token breakdown per email (~600-800 optimized)
- Tiered model routing
- Sender pattern caching implementation
- Batch processing architecture
- Usage tracking and alerting

### Agent 6: Inbox Zero Automation Patterns
- Core philosophy (Four D's: Delete, Do, Delegate, Defer)
- Complete decision tree for archive vs keep
- Snooze implementation via labels
- Daily digest workflow
- Feedback loop for corrections

---

## Next Steps

1. **SSH to server**: `ssh nshonda`
2. **Create docker-compose.yml** for n8n
3. **Set up Cloudflare tunnel** pointing to `localhost:5678`
4. **Configure Gmail OAuth** in Google Cloud Console
5. **Import initial workflow** from templates above
6. **Create label hierarchy** in Gmail
7. **Test with 10 emails** before full deployment

---

## Follow-up Research (If Confidence Needs Improvement)

- Google Pub/Sub for real-time Gmail notifications (vs polling)
- n8n AI Agents node capabilities
- Gmail API push notifications setup
- Custom model fine-tuning for email classification
