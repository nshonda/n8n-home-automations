# n8n API Deployment Guide

How to deploy, update, and manage workflows via the n8n REST API.

## Best Practices

### Credentials

- Workflow JSON files in this repo use **placeholder IDs** (`GMAIL_CREDENTIAL_ID`, `ANTHROPIC_CREDENTIAL_ID`) — never commit real credential IDs to git
- When updating a workflow via the API, the payload **overwrites** all node data including credentials — always fetch the current workflow first to preserve real credential IDs, or replace placeholders after import
- The n8n API does **not** support `GET /api/v1/credentials` — you cannot list or discover credentials via the API; find real IDs by inspecting a working workflow
- Set credentials once via the API with real IDs, then avoid overwriting them in future updates unless you include the real IDs in the payload

### Workflow Updates

- Always include `name`, `nodes`, `connections`, and `settings` in PUT requests — missing fields will be cleared
- The `settings` field must only contain known properties (e.g. `executionOrder`) — extra properties from the server (like `saveManualExecutions`) cause a 400 error; when in doubt, use `{"executionOrder": "v1"}`
- To safely update a workflow without touching credentials: fetch it from the API first, modify what you need, and PUT it back

### Gmail API Specifics

- `batchModify` returns 204 No Content — n8n's HTTP Request node will fail with "Invalid JSON in response body" unless you set `responseFormat: "text"` with `neverError: true` in the node's response options
- Use `batchModify` over individual message calls — it handles up to 1000 messages per request and avoids rate limiting
- When looping with `batchModify`, add a 1s delay between batches to stay within Gmail quotas

## API Key Setup

Store your n8n API key on the server:

```bash
echo "your-api-key-here" > ~/.n8n-api-key
chmod 600 ~/.n8n-api-key
```

Generate the key in n8n: Settings → API → Create API Key.

## Finding Credential IDs

Inspect a working workflow to find real credential IDs:

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

## Importing a New Workflow

```bash
API_KEY=$(cat ~/.n8n-api-key)
curl -s -X POST "http://localhost:5678/api/v1/workflows" \
  -H "X-N8N-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/my-workflow.json
```

The response includes the new workflow's `id` — save it for future updates.

## Updating an Existing Workflow

```bash
API_KEY=$(cat ~/.n8n-api-key)
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

## Fixing Credentials After Import

After importing via API, replace placeholder credential IDs with real ones:

```bash
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

## Activating / Deactivating a Workflow

```bash
API_KEY=$(cat ~/.n8n-api-key)

# Activate
curl -s -X PATCH "http://localhost:5678/api/v1/workflows/<WORKFLOW_ID>/activate" \
  -H "X-N8N-API-KEY: $API_KEY"

# Deactivate
curl -s -X PATCH "http://localhost:5678/api/v1/workflows/<WORKFLOW_ID>/deactivate" \
  -H "X-N8N-API-KEY: $API_KEY"
```
