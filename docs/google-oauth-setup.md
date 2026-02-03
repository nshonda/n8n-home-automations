# Google OAuth Setup for n8n

This guide covers setting up Google OAuth credentials for Google Drive and Google Sheets access in n8n workflows.

## Prerequisites

- A Google account
- Access to your n8n instance
- Your n8n domain (e.g., `n8n.yourdomain.com`)

## 1. Create or Select a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown (top-left) → **New Project**
   - Or select an existing project (e.g., one used for Gmail OAuth)
3. Name it something like "n8n Automations"
4. Click **Create**

## 2. Enable Required APIs

Go to **APIs & Services → Library** and enable:

| API | Purpose |
|-----|---------|
| **Google Drive API** | Download resume PDF, access files |
| **Google Sheets API** | Store profile embeddings, track seen jobs |

For each API:
1. Search for the API name
2. Click on it
3. Click **Enable**

## 3. Configure OAuth Consent Screen

Go to **APIs & Services → OAuth consent screen**:

1. Select **External** (or **Internal** if using Google Workspace and want org-only access)
2. Click **Create**

### App Information
- **App name**: `n8n Automations`
- **User support email**: your email address
- **App logo**: optional

### App Domain (optional)
- Leave blank for testing

### Developer Contact
- Add your email address

Click **Save and Continue**

### Scopes
Click **Add or Remove Scopes** and add:
```
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/spreadsheets
```

Or search for:
- Google Drive API → `.../auth/drive.readonly`
- Google Sheets API → `.../auth/spreadsheets`

Click **Save and Continue**

### Test Users
1. Click **Add Users**
2. Add your Google email address (the account that owns the Drive files and Sheets)
3. Click **Save and Continue**

**Note**: While in "Testing" mode, only test users can authorize. Once you've verified everything works, you can publish the app to remove this restriction.

## 4. Create OAuth Client Credentials

Go to **APIs & Services → Credentials**:

1. Click **Create Credentials → OAuth client ID**
2. **Application type**: Web application
3. **Name**: `n8n`

### Authorized Redirect URIs
Add this URI (replace with your actual n8n domain):
```
https://YOUR_N8N_DOMAIN/rest/oauth2-credential/callback
```

Examples:
- `https://n8n.example.com/rest/oauth2-credential/callback`
- `https://n8n.mysite.io/rest/oauth2-credential/callback`

4. Click **Create**
5. Copy the **Client ID** and **Client Secret** — you'll need these for n8n

## 5. Add Credentials in n8n

### Google Drive OAuth2

1. Open your n8n instance
2. Go to **Credentials** (left sidebar)
3. Click **Add Credential**
4. Search for **Google Drive OAuth2**
5. Fill in:
   - **Name**: `Google Drive OAuth2` (or any name you prefer)
   - **Client ID**: paste from Google Cloud
   - **Client Secret**: paste from Google Cloud
6. Click **Sign in with Google**
7. Select your Google account (must be a test user)
8. Grant the requested permissions
9. Click **Save**

### Google Sheets OAuth2

1. Click **Add Credential** again
2. Search for **Google Sheets OAuth2**
3. Fill in:
   - **Name**: `Google Sheets OAuth2`
   - **Client ID**: same as above
   - **Client Secret**: same as above
4. Click **Sign in with Google**
5. Grant permissions
6. Click **Save**

## 6. Verify Credentials

To test that credentials work:

1. Create a new workflow
2. Add a **Google Drive** node
3. Select your Google Drive OAuth2 credential
4. Set operation to **List**
5. Execute the node — it should return your Drive files

Repeat with a **Google Sheets** node to verify Sheets access.

## Troubleshooting

### "Access blocked: This app's request is invalid"
- Verify the redirect URI in Google Cloud exactly matches your n8n URL
- Check for typos, trailing slashes, or http vs https

### "Error 403: access_denied"
- Make sure your Google account is added as a test user
- Wait a few minutes after adding test users (can take time to propagate)

### "This app isn't verified"
- Click **Advanced** → **Go to n8n Automations (unsafe)**
- This is normal for apps in testing mode

### Credential shows "Invalid" in n8n
- The OAuth token may have expired
- Click on the credential → **Sign in with Google** again

## Scopes Reference

| Scope | Access Level |
|-------|--------------|
| `drive.readonly` | Read-only access to Drive files |
| `drive` | Full read/write access to Drive |
| `spreadsheets.readonly` | Read-only access to Sheets |
| `spreadsheets` | Full read/write access to Sheets |

The job digest workflows only need read access to Drive (resume PDF) and read/write to Sheets (profile storage, seen jobs tracking).

## Security Notes

- Never commit Client ID/Secret to git
- Use the minimum required scopes
- Regularly review which apps have access in [Google Account Security](https://myaccount.google.com/permissions)
- Consider publishing the OAuth app once tested to remove "unverified app" warnings
