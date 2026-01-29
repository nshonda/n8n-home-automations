# Invoice Forwarding Setup

Automatically collect Husky and Deel invoices each month and email them to the accountant.

## Architecture Overview

```
Husky Email → Gmail Trigger → Download PDF → Google Drive (Pending)
Deel Email  → Gmail Trigger → Reminder Email                  ↓
                                    You upload Deel PDF → Google Drive (Pending)
                                                               ↓
                                          Drive Trigger → Both PDFs? → Compose & Send → Move to Processed
```

## Prerequisites

- n8n instance running (see [Quick Start](./quick-start.md))
- Gmail OAuth2 credential configured (see [Gmail OAuth Setup](./gmail-oauth-setup.md))
- Google Drive OAuth2 credential (see Step 1 below)

## Step 1: Google Drive OAuth Credential

If you already have a Google Cloud project from Gmail OAuth setup:

1. Go to **APIs & Services** > **Library**
2. Search for "Google Drive API" and click **Enable**
3. Go to **APIs & Services** > **OAuth consent screen**
4. Add scope: `https://www.googleapis.com/auth/drive`
5. In n8n, go to **Settings** > **Credentials** > **Add Credential**
6. Search for **Google Drive OAuth2 API**
7. Enter the same Client ID and Client Secret from your Gmail OAuth setup
8. Click **Sign in with Google** and authorize Drive access
9. Note the credential ID for the workflow

## Step 2: Create Google Drive Folders

1. In Google Drive, create a folder called `Invoices`
2. Inside it, create two subfolders:
   - `Pending` — staging area for incoming invoices
   - `Processed` — archive for sent invoices
3. Get the folder IDs from the URL:
   - Open each folder in Drive
   - The ID is the last segment of the URL: `https://drive.google.com/drive/folders/<FOLDER_ID>`

## Step 3: Create Gmail Label

Create the label `_System/InvoiceProcessed` in Gmail:

1. Go to Gmail **Settings** > **Labels** > **Create new label**
2. Name: `_System/InvoiceProcessed`
   - If `_System` already exists (from the email classifier), create `InvoiceProcessed` nested under it

## Step 4: Import Workflow

1. Open n8n at your instance URL
2. Go to **Workflows** > **Import from File**
3. Select `workflows/forward-invoices.json`
4. Replace placeholder values in the workflow:

| Placeholder | Where to find it |
|---|---|
| `GMAIL_CREDENTIAL_ID` | n8n Settings > Credentials > Gmail OAuth2 > URL contains the ID |
| `GOOGLE_DRIVE_CREDENTIAL_ID` | n8n Settings > Credentials > Google Drive OAuth2 > URL contains the ID |
| `INVOICES_PENDING_FOLDER_ID` | Google Drive folder URL (see Step 2) |
| `INVOICES_PROCESSED_FOLDER_ID` | Google Drive folder URL (see Step 2) |

5. Click each node and verify credentials are connected
6. **Activate** the workflow

## How It Works

### Monthly Flow

1. **Husky invoice** arrives via email from `friends@husky.io`
   - Workflow downloads the PDF attachment automatically
   - Uploads it to `Invoices/Pending` in Google Drive
   - Labels the email `_System/InvoiceProcessed`

2. **Deel invoice** notification arrives from `no-reply@deel.support`
   - Workflow sends you a reminder email
   - Labels the notification `_System/InvoiceProcessed`
   - You download the invoice from Deel and upload the PDF to `Invoices/Pending`

3. **Both PDFs in folder** triggers the send
   - Drive watcher detects the new file, lists all PDFs in `Pending`
   - If 2+ PDFs are present, composes the email:
     - **To:** `mohamadhemersson@gmail.com`
     - **CC:** `mohamadariss@hotmail.com`
     - **Subject:** `Notas Fiscais [Month in Portuguese] [Year]`
     - **Body:** Standard template with OneRhino LLC and Deel Inc. details
     - **Attachments:** Both PDFs
   - Moves files to `Invoices/Processed`

## Testing

1. **Test Husky path:** Forward or send a test email matching `from:friends@husky.io subject:"Money is coming"` with a PDF attachment
2. **Test Deel path:** Forward or send a test email matching `from:no-reply@deel.support subject:"money's on the way"`, then upload a PDF to `Invoices/Pending`
3. Check the `Invoices/Pending` folder — once both PDFs are there, the email should send automatically
4. Verify the composed email in the accountant's inbox

## Troubleshooting

### Husky PDF not uploading
- Check that the email has a PDF attachment (not a link)
- Verify Gmail credential has `gmail.modify` scope
- Check execution logs for attachment extraction errors

### Drive trigger not firing
- Verify the folder ID matches `Invoices/Pending`
- Google Drive triggers can have a delay — wait a few minutes
- Check that Google Drive OAuth2 credential is connected

### Email not sending after both PDFs are present
- Open the execution log for the Drive trigger
- Check the "Check Both Ready" node — it requires 2+ PDF files
- Verify the files are actual PDFs (not shortcuts or Google Docs)
