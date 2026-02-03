#!/bin/bash
# Import n8n workflows via the REST API over SSH
#
# Usage:
#   ./scripts/import-workflows.sh                          # Import all workflows
#   ./scripts/import-workflows.sh workflows/job-digest-daily.json  # Import one workflow
#
# Prerequisites:
#   - SSH alias "nshonda" configured in ~/.ssh/config
#   - n8n API key stored on server at ~/.n8n-api-key
#     (generate in n8n: Settings → API → Create API Key)

set -e

SSH_HOST="nshonda"
N8N_URL="http://localhost:5678"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Determine which files to import
if [ -n "$1" ]; then
    FILES=("$@")
else
    FILES=("$REPO_ROOT"/workflows/*.json)
fi

echo "=== n8n Workflow Importer ==="
echo ""

# Verify SSH connectivity
if ! ssh -o ConnectTimeout=5 "$SSH_HOST" "test -f ~/.n8n-api-key" 2>/dev/null; then
    echo "ERROR: Cannot connect to $SSH_HOST or ~/.n8n-api-key not found."
    echo ""
    echo "Setup:"
    echo "  1. Ensure SSH alias 'nshonda' is in ~/.ssh/config"
    echo "  2. On the server, create an API key in n8n (Settings → API)"
    echo "  3. Run: ssh nshonda 'echo YOUR_API_KEY > ~/.n8n-api-key && chmod 600 ~/.n8n-api-key'"
    exit 1
fi

# Get existing workflows to detect updates vs creates
echo "Fetching existing workflows..."
EXISTING=$(ssh "$SSH_HOST" "
    API_KEY=\$(cat ~/.n8n-api-key)
    curl -sf '$N8N_URL/api/v1/workflows' \
        -H \"X-N8N-API-KEY: \$API_KEY\" 2>/dev/null || echo '{}'
")

imported=0
updated=0
failed=0

for filepath in "${FILES[@]}"; do
    if [ ! -f "$filepath" ]; then
        echo "  SKIP: $filepath (not found)"
        continue
    fi

    filename=$(basename "$filepath")
    workflow_name=$(python3 -c "import json; print(json.load(open('$filepath'))['name'])" 2>/dev/null || echo "$filename")

    # Check if workflow already exists by name
    existing_id=$(echo "$EXISTING" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for wf in data.get('data', []):
        if wf['name'] == '''$workflow_name''':
            print(wf['id'])
            break
except:
    pass
" 2>/dev/null)

    if [ -n "$existing_id" ]; then
        # Update existing workflow
        echo "  UPDATE: $workflow_name (id: $existing_id)"
        result=$(cat "$filepath" | python3 -c "
import sys, json
wf = json.load(sys.stdin)
payload = json.dumps({
    'name': wf['name'],
    'nodes': wf['nodes'],
    'connections': wf['connections'],
    'settings': wf.get('settings', {})
})
print(payload)
" | ssh "$SSH_HOST" "
            API_KEY=\$(cat ~/.n8n-api-key)
            curl -sf -X PUT '$N8N_URL/api/v1/workflows/$existing_id' \
                -H \"X-N8N-API-KEY: \$API_KEY\" \
                -H 'Content-Type: application/json' \
                -d @- 2>&1
        ")
        if echo "$result" | python3 -c "import sys,json; json.load(sys.stdin)['id']" &>/dev/null; then
            echo "    OK"
            updated=$((updated + 1))
        else
            echo "    FAILED: $result"
            failed=$((failed + 1))
        fi
    else
        # Create new workflow
        echo "  CREATE: $workflow_name"
        result=$(cat "$filepath" | python3 -c "
import sys, json
wf = json.load(sys.stdin)
payload = json.dumps({
    'name': wf['name'],
    'nodes': wf['nodes'],
    'connections': wf['connections'],
    'settings': wf.get('settings', {})
})
print(payload)
" | ssh "$SSH_HOST" "
            API_KEY=\$(cat ~/.n8n-api-key)
            curl -sf -X POST '$N8N_URL/api/v1/workflows' \
                -H \"X-N8N-API-KEY: \$API_KEY\" \
                -H 'Content-Type: application/json' \
                -d @- 2>&1
        ")
        new_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
        if [ -n "$new_id" ]; then
            echo "    OK (id: $new_id)"
            imported=$((imported + 1))
        else
            echo "    FAILED: $result"
            failed=$((failed + 1))
        fi
    fi
done

echo ""
echo "Done: $imported created, $updated updated, $failed failed"
echo ""
if [ $((imported + updated)) -gt 0 ]; then
    echo "Next steps:"
    echo "  1. Open n8n and update credential references on imported workflows"
    echo "  2. For job digest workflows, see docs/job-digest-setup.md"
fi
