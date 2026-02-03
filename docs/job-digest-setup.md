# Job Search Digest Setup Guide

This system fetches jobs daily from Adzuna, matches them against your resume + LinkedIn profile using Ollama embeddings, and delivers a ranked digest to Discord.

## Prerequisites

- Docker with GPU support (NVIDIA Container Toolkit)
- Google Drive with your resume PDF
- Google Sheets for profile storage and job tracking
- Discord server with a webhook

## 1. Get an Adzuna API Key

1. Go to https://developer.adzuna.com/ and create a free account
2. You'll receive an **App ID** and **API Key**
3. Add them to your `.env` file:
   ```
   ADZUNA_APP_ID=your_app_id
   ADZUNA_API_KEY=your_api_key
   ```

## 2. Export LinkedIn Data

1. Go to LinkedIn → Settings → Data Privacy → **Get a copy of your data**
2. Select: **Skills**, **Positions**, **Education**
3. Request the archive and wait for the email
4. Download and extract the ZIP file
5. Open these CSVs and paste the data into a Google Sheet:
   - `Skills.csv` → Sheet tab named "Skills"
   - `Positions.csv` → Sheet tab named "Positions"
6. Note the Google Sheet URL — you'll paste it into the setup workflow

## 3. Get Your Resume Google Drive File ID

1. Upload your resume PDF to Google Drive
2. Right-click → **Share** → **Copy link**
3. The file ID is the long string in the URL: `https://drive.google.com/file/d/FILE_ID_HERE/view`
4. Add to `.env`:
   ```
   GOOGLE_DRIVE_RESUME_FILE_ID=your_file_id_here
   ```

## 4. Create a Discord Webhook

1. In your Discord server, go to **Server Settings → Integrations → Webhooks**
2. Click **New Webhook**
3. Name it "Job Digest" and select the target channel
4. Click **Copy Webhook URL**
5. Add to `.env`:
   ```
   JOB_SEARCH_DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
   ```

## 5. Create the Job Config Google Sheet

Create a new Google Sheet with these tabs:

| Tab Name | Columns |
|----------|---------|
| **Profile** | Row, Embedding, Skills, Titles, Dimensions, Generated At |
| **SeenJobs** | job_id, title, seen_date |

Note the sheet URL — you'll need it for both workflows.

## 6. Deploy and Configure

```bash
cd deploy
./setup.sh
```

Wait for Ollama to become healthy and models to download (nomic-embed-text, qwen2.5:3b).

## 7. Import Workflows

Import both workflows via SSH:

```bash
# Import all workflows (including job digest)
./scripts/import-workflows.sh

# Or import just the job digest workflows
./scripts/import-workflows.sh workflows/job-digest-setup.json workflows/job-digest-daily.json
```

This requires an n8n API key on the server (see `docs/n8n-api-deployment.md` for setup).

## 8. Configure Workflows

### Setup Workflow (`job-digest-setup.json`)

1. Open the imported workflow in n8n
2. Configure these nodes with your credentials:
   - **Download Resume PDF** → Google Drive OAuth2 credential
   - **Read LinkedIn Skills/Positions** → Google Sheets OAuth2 credential + paste your LinkedIn sheet URL
   - **Store Profile in Google Sheet** → Google Sheets credential + paste your Job Config sheet URL
3. Create an **Ollama** credential in n8n:
   - Base URL: `http://ollama:11434`
4. Run the workflow manually — it will parse your resume, extract LinkedIn data, generate an embedding, and store everything

### Daily Workflow (`job-digest-daily.json`)

1. Open the imported workflow in n8n
2. Configure these nodes:
   - **Read Seen Jobs** / **Read Profile** / **Append Seen Jobs** → Google Sheets credential + Job Config sheet URL
3. Test by clicking "Execute Workflow" manually
4. Once working, activate the workflow to run daily at 8 AM

## 9. Tuning

### Match Threshold

The default threshold is **0.65** (65% similarity). To adjust:

- Edit the "Rank & Filter" code node in the daily workflow
- Change `j.json.similarity_score >= 0.65` to your preferred value
- **0.70+**: Stricter, fewer but more relevant matches
- **0.60**: Looser, more matches but some may be less relevant

### Search Keywords

Edit the "Fetch Jobs (Adzuna)" node's `what` query parameter to change search terms. Examples:
- `software engineer`
- `backend developer python`
- `devops engineer remote`

### Country

Change `us` in the Adzuna URL to your country code (e.g., `gb`, `ca`, `au`).

### Discord Colors

Matches are color-coded in Discord:
- **Green** (score >= 0.80): Excellent match
- **Blue** (score 0.70-0.79): Good match
- **Yellow** (score 0.65-0.69): Fair match
