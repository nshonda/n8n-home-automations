#!/bin/bash
# Create Gmail labels for the email classifier
# Requires: pip install google-auth google-auth-oauthlib google-api-python-client

# Gmail label hierarchy for inbox zero automation
LABELS=(
    # Action labels (things you need to do)
    "@Action"
    "@Action/Reply"
    "@Action/Review"
    "@Action/Pay"
    "@Action/Read"

    # Category labels
    "#Finance"
    "#Finance/Banking"
    "#Finance/Receipts"
    "#Finance/Bills"
    "#Finance/Investments"

    "#Work"
    "#Work/Projects"
    "#Work/Meetings"

    "#Personal"
    "#Personal/Family"
    "#Personal/Health"

    "#Shopping"
    "#Shopping/Orders"
    "#Shopping/Shipping"
    "#Shopping/Deals"

    "#Travel"
    "#Travel/Flights"
    "#Travel/Hotels"
    "#Travel/Reservations"

    "#Notifications"
    "#Newsletters"
    "#Social"
    "#Security"
    "#Other"

    # Priority labels
    "!Priority"
    "!Priority/Urgent"
    "!Priority/Important"

    # Reference labels
    "~Reference"
    "~Reference/Docs"
    "~Reference/Receipts"

    # System labels (automation)
    "_System"
    "_System/Processed"
    "_System/Review"
    "_System/VIP"

    # Snooze labels
    "_Snooze"
    "_Snooze/Tomorrow"
    "_Snooze/NextWeek"
    "_Snooze/NextMonth"
)

echo "Gmail Label Setup"
echo "================="
echo ""
echo "This script will create the following labels in Gmail:"
echo ""
for label in "${LABELS[@]}"; do
    echo "  $label"
done
echo ""
echo "To create these labels:"
echo ""
echo "Option 1: Manual (Recommended for first time)"
echo "  1. Go to Gmail Settings > Labels"
echo "  2. Create each label manually"
echo "  3. Parent labels (like @Action) must exist before children (@Action/Reply)"
echo ""
echo "Option 2: Python Script"
echo "  Run: python3 create_labels.py"
echo ""
echo "Option 3: Gmail API (requires OAuth setup)"
echo "  The n8n workflow can create missing labels automatically"
echo ""

# Create Python script for label creation
cat > create_labels.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""
Create Gmail labels using the Gmail API.
Requires OAuth credentials from Google Cloud Console.

Setup:
1. Go to https://console.cloud.google.com/
2. Create a project and enable Gmail API
3. Create OAuth 2.0 credentials (Desktop app)
4. Download credentials.json to this directory
5. Run: pip install google-auth google-auth-oauthlib google-api-python-client
6. Run: python3 create_labels.py
"""

import os
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import pickle

SCOPES = ['https://www.googleapis.com/auth/gmail.labels']

LABELS = [
    "@Action", "@Action/Reply", "@Action/Review", "@Action/Pay", "@Action/Read",
    "#Finance", "#Finance/Banking", "#Finance/Receipts", "#Finance/Bills", "#Finance/Investments",
    "#Work", "#Work/Projects", "#Work/Meetings",
    "#Personal", "#Personal/Family", "#Personal/Health",
    "#Shopping", "#Shopping/Orders", "#Shopping/Shipping", "#Shopping/Deals",
    "#Travel", "#Travel/Flights", "#Travel/Hotels", "#Travel/Reservations",
    "#Notifications", "#Newsletters", "#Social", "#Security", "#Other",
    "!Priority", "!Priority/Urgent", "!Priority/Important",
    "~Reference", "~Reference/Docs", "~Reference/Receipts",
    "_System", "_System/Processed", "_System/Review", "_System/VIP",
    "_Snooze", "_Snooze/Tomorrow", "_Snooze/NextWeek", "_Snooze/NextMonth"
]

def get_service():
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists('credentials.json'):
                print("ERROR: credentials.json not found")
                print("Download OAuth credentials from Google Cloud Console")
                return None
            flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    return build('gmail', 'v1', credentials=creds)

def create_labels(service):
    # Get existing labels
    results = service.users().labels().list(userId='me').execute()
    existing = {label['name'] for label in results.get('labels', [])}

    created = 0
    skipped = 0

    for label_name in LABELS:
        if label_name in existing:
            print(f"  Exists: {label_name}")
            skipped += 1
            continue

        try:
            label_body = {
                'name': label_name,
                'labelListVisibility': 'labelShow',
                'messageListVisibility': 'show'
            }
            service.users().labels().create(userId='me', body=label_body).execute()
            print(f"  Created: {label_name}")
            created += 1
        except Exception as e:
            print(f"  Error creating {label_name}: {e}")

    print(f"\nDone! Created: {created}, Already existed: {skipped}")

if __name__ == '__main__':
    print("Gmail Label Creator")
    print("===================\n")

    service = get_service()
    if service:
        create_labels(service)
PYTHON_SCRIPT

echo "Created create_labels.py - run with: python3 create_labels.py"
