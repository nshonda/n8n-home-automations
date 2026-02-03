# Quick Start Guide

Deploy AI-powered email classification on your Ubuntu server in 30 minutes.

## Architecture Overview

```
Gmail → n8n (Docker) → Claude Haiku → Labels + Archive
           ↑
    Cloudflare Tunnel
```

## Prerequisites

- Ubuntu server with Docker
- Domain name with Cloudflare DNS
- Gmail account
- Anthropic API key (~$1/month for typical usage)

## Step 1: Deploy n8n (5 min)

```bash
# SSH to your server
ssh nshonda

# Clone or copy the deploy folder
mkdir -p ~/n8n-email && cd ~/n8n-email

# Copy files (from your local machine)
# scp -r deploy/* nshonda:~/n8n-email/

# Or create manually - see deploy/docker-compose.yml

# Run setup
chmod +x setup.sh
./setup.sh
```

## Step 2: Cloudflare Tunnel (5 min)

```bash
# Install cloudflared (if not already)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create n8n

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: n8n.yourdomain.com
    service: http://localhost:5678
  - service: http_status:404
EOF

# Add DNS record
cloudflared tunnel route dns n8n n8n.yourdomain.com

# Run tunnel (or set up as service)
cloudflared tunnel run n8n
```

### Run as Service
```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

## Step 3: Gmail OAuth (10 min)

See [gmail-oauth-setup.md](./gmail-oauth-setup.md) for detailed instructions.

Quick version:
1. Google Cloud Console → Create project → Enable Gmail API
2. OAuth consent screen → External → Add scopes
3. Credentials → OAuth client ID → Web application
4. Add redirect URI: `https://n8n.yourdomain.com/rest/oauth2-credential/callback`
5. In n8n: Add Gmail OAuth2 credential with Client ID/Secret

## Step 4: Import Workflow (5 min)

**Option A: Via SSH script** (recommended after API key is set up)
```bash
./scripts/import-workflows.sh workflows/email-classifier.json
```

**Option B: Via n8n UI**
1. Open n8n at `https://n8n.yourdomain.com`
2. Go to **Workflows** > **Import from File**
3. Select `workflows/email-classifier.json`

Then update credential references:
- Click Gmail nodes → Select your Gmail credential
- Click AI Classification node → Select your Anthropic credential
- **Activate** the workflow

## Step 5: Create Gmail Labels (5 min)

Run the label creation script or create manually in Gmail:

```bash
cd scripts
chmod +x create-gmail-labels.sh
./create-gmail-labels.sh
```

Or manually create in Gmail Settings > Labels:
- `@Action/Reply`, `@Action/Review`
- `#Finance`, `#Shopping`, `#Work`, etc.
- `_System/Processed`, `_System/Review`

## Testing

1. Send yourself a test email
2. Wait for next poll interval (5 min) or trigger manually
3. Check n8n execution logs
4. Verify email has labels applied

## Monitoring

```bash
# View n8n logs
docker compose logs -f n8n

# Check execution history in n8n UI
# Settings > Executions
```

## Cost Estimate

| Emails/Month | Claude Haiku Cost |
|-------------|-------------------|
| 500 | ~$0.50 |
| 2,000 | ~$1.80 |
| 10,000 | ~$8.80 |

With sender caching enabled, actual costs are 40-60% lower.

## Next Steps

1. **Monitor** for a week, review `_System/Review` labels
2. **Tune** confidence threshold based on false positives
3. **Add** sender exceptions for VIPs
4. **Enable** daily digest workflow (optional)

## Troubleshooting

### Emails not processing
- Check workflow is active
- Verify Gmail credential has `gmail.modify` scope
- Check execution logs for errors

### Wrong classifications
- Review AI prompt in workflow
- Add few-shot examples for edge cases
- Lower confidence threshold temporarily

### High API costs
- Enable sender caching (already in workflow)
- Increase poll interval to 10 min
- Truncate email body further
