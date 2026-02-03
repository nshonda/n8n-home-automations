#!/bin/bash
# n8n Email Classifier Setup Script
# Run this on your Ubuntu server after copying the deploy folder

set -e

echo "=== n8n Email Classifier Setup ==="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env from template..."
    cp .env.example .env

    # Generate encryption key
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    sed -i "s/N8N_ENCRYPTION_KEY=/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env

    echo "Generated N8N_ENCRYPTION_KEY"
    echo ""
    echo "IMPORTANT: Edit .env and set your N8N_HOST domain"
    echo "Then run this script again."
    exit 0
fi

# Validate .env
source .env
if [ -z "$N8N_HOST" ] || [ "$N8N_HOST" = "n8n.yourdomain.com" ]; then
    echo "ERROR: Please set N8N_HOST in .env to your actual domain"
    exit 1
fi

if [ -z "$N8N_ENCRYPTION_KEY" ]; then
    echo "ERROR: N8N_ENCRYPTION_KEY is not set in .env"
    exit 1
fi

echo "Configuration validated:"
echo "  Host: $N8N_HOST"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in, then run this script again."
    exit 0
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "ERROR: Docker Compose not found. Please install Docker Compose v2."
    exit 1
fi

echo "Starting services..."
docker compose up -d

echo ""
echo "Waiting for Ollama to become healthy..."
OLLAMA_RETRIES=0
OLLAMA_MAX_RETRIES=20
while [ $OLLAMA_RETRIES -lt $OLLAMA_MAX_RETRIES ]; do
    if docker inspect --format='{{.State.Health.Status}}' ollama 2>/dev/null | grep -q "healthy"; then
        echo "Ollama is healthy."
        break
    fi
    OLLAMA_RETRIES=$((OLLAMA_RETRIES + 1))
    echo "  Waiting for Ollama... ($OLLAMA_RETRIES/$OLLAMA_MAX_RETRIES)"
    sleep 5
done

if [ $OLLAMA_RETRIES -eq $OLLAMA_MAX_RETRIES ]; then
    echo "WARNING: Ollama did not become healthy within expected time."
    echo "Check logs with: docker compose logs ollama"
else
    echo "Waiting for model pull (ollama-init)..."
    docker compose logs -f ollama-init 2>/dev/null | while read -r line; do
        echo "  $line"
        echo "$line" | grep -q "pulling\|success\|already exists" && continue
    done
    echo "Verifying models..."
    docker exec ollama ollama list 2>/dev/null || echo "  Could not list models. Check: docker exec ollama ollama list"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "n8n is starting at http://localhost:5678"
echo ""
echo "Next steps:"
echo "1. Set up Cloudflare tunnel to expose https://$N8N_HOST"
echo "2. Access n8n and create your admin account"
echo "3. Add Gmail OAuth2 credentials (see docs/gmail-oauth-setup.md)"
echo "4. Add Anthropic API credentials"
echo "5. Import workflow from ../workflows/email-classifier.json"
echo "6. Create Gmail labels (run: ../scripts/create-gmail-labels.sh)"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"
