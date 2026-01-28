# Gmail OAuth Setup for n8n

## Prerequisites
- Google account with Gmail
- n8n instance running and accessible

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Note your project ID

## Step 2: Enable Gmail API

1. Go to **APIs & Services** > **Library**
2. Search for "Gmail API"
3. Click **Enable**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** (unless you have Google Workspace)
3. Fill in required fields:
   - App name: `n8n Email Classifier`
   - User support email: Your email
   - Developer contact: Your email
4. Click **Save and Continue**

### Add Scopes
1. Click **Add or Remove Scopes**
2. Add these scopes:
   - `https://www.googleapis.com/auth/gmail.modify` (required)
   - `https://www.googleapis.com/auth/gmail.labels` (required)
3. Click **Save and Continue**

### Add Test Users (Required for External)
1. Add your Gmail address as a test user
2. Click **Save and Continue**

## Step 4: Create OAuth Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Application type: **Web application**
4. Name: `n8n`
5. Add Authorized redirect URIs:
   ```
   https://your-n8n-domain.com/rest/oauth2-credential/callback
   ```
   Replace `your-n8n-domain.com` with your actual n8n domain
6. Click **Create**
7. **Save the Client ID and Client Secret**

## Step 5: Configure n8n

1. Open n8n at `https://your-n8n-domain.com`
2. Go to **Settings** > **Credentials**
3. Click **Add Credential**
4. Search for **Gmail OAuth2**
5. Enter:
   - **Client ID**: From Step 4
   - **Client Secret**: From Step 4
6. Click **Sign in with Google**
7. Complete OAuth flow with your Gmail account
8. Click **Save**

## Step 6: Add Anthropic API Credential

1. Get API key from [Anthropic Console](https://console.anthropic.com/)
2. In n8n, go to **Settings** > **Credentials**
3. Click **Add Credential**
4. Search for **Header Auth**
5. Configure:
   - **Name**: `Anthropic API`
   - **Header Name**: `x-api-key`
   - **Header Value**: Your Anthropic API key
6. Click **Save**

## Troubleshooting

### "Access blocked: This app's request is invalid"
- Ensure redirect URI exactly matches your n8n domain
- Check that Gmail API is enabled
- Verify OAuth consent screen is configured

### "This app isn't verified"
- This is expected for external apps
- Click **Advanced** > **Go to app (unsafe)**
- This only appears during initial setup

### Token Expired
- n8n automatically refreshes tokens
- If issues persist, delete credential and re-authenticate

## Security Notes

- Keep Client Secret confidential
- Use HTTPS for n8n (via Cloudflare tunnel)
- Limit OAuth scopes to minimum needed
- Consider Google Workspace for production use
