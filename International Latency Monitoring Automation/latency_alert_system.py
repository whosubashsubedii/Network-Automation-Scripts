#!/usr/bin/env python3
"""
SAFE VERSION - No secrets inside code
Use environment variables for all sensitive data
"""

import subprocess
import re
import smtplib
import textwrap
import gspread
import sys
import os
from email.mime.text import MIMEText
from datetime import datetime
from google.oauth2.service_account import Credentials

# ================= CONFIGURATION =================

# -------- EMAIL SETTINGS (from environment) --------
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587

EMAIL_SENDER = os.getenv("EMAIL_SENDER")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD")

EMAIL_RECEIVERS = os.getenv("EMAIL_RECEIVERS", "").split(",")
EMAIL_CC = os.getenv("EMAIL_CC", "").split(",")
EMAIL_BCC = os.getenv("EMAIL_BCC", "").split(",")

# -------- ENCRYPTION --------
ENCRYPTION_PASSWORD = os.getenv("ENCRYPTION_PASSWORD")
ENCRYPTED_FILE = os.getenv("ENCRYPTED_FILE", "password.enc")

# -------- GOOGLE SHEETS --------
GOOGLE_SHEET_NAME = os.getenv("GOOGLE_SHEET_NAME")
SERVICE_ACCOUNT_FILE = os.getenv("SERVICE_ACCOUNT_FILE", "credentials.json")

# -------- MONITORING TARGETS (SANITIZED) --------
CHECKS = [
    {
        "name": "LOCATION_1",
        "host": "YOUR_SERVER_IP",
        "source": "SOURCE_IP",
        "target": "TARGET_IP",
        "threshold": 50
    },
]

SSH_USER = os.getenv("SSH_USER")

# =================================================

def validate_env():
    required_vars = [
        "EMAIL_SENDER",
        "EMAIL_PASSWORD",
        "ENCRYPTION_PASSWORD",
        "SSH_USER",
        "GOOGLE_SHEET_NAME"
    ]
    missing = [var for var in required_vars if not os.getenv(var)]
    if missing:
        print(f"Missing environment variables: {', '.join(missing)}")
        sys.exit(1)


def log_to_google_sheets(rows):
    try:
        scope = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive"
        ]
        creds = Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE, scopes=scope
        )
        client = gspread.authorize(creds)
        sheet = client.open(GOOGLE_SHEET_NAME).get_worksheet(0)
        sheet.append_rows(rows)
    except Exception as e:
        print(f"Google Sheets error: {e}")


def decrypt_password():
    try:
        result = subprocess.run(
            [
                'openssl', 'enc', '-aes-256-cbc', '-d', '-pbkdf2',
                '-in', ENCRYPTED_FILE,
                '-pass', f'pass:{ENCRYPTION_PASSWORD}'
            ],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except Exception as e:
        print(f"Decryption failed: {e}")
        sys.exit(1)


def run_ssh_ping(host, source, target):
    password = decrypt_password()

    cmd = [
        'sshpass', '-p', password,
        'ssh', '-o', 'StrictHostKeyChecking=no', '-T',
        f'{SSH_USER}@{host}',
        f'ping {target} source {source} count 1000 rapid'
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        return result.stdout
    except Exception as e:
        return f"Execution failed: {e}"


def parse_latency(output):
    match = re.search(r"([\d.]+)/([\d.]+)/([\d.]+)/", output)
    return float(match.group(1)) if match else None


def send_email(body):
    msg = MIMEText(body)
    msg['Subject'] = "Latency Monitoring Report"
    msg['From'] = EMAIL_SENDER
    msg['To'] = ', '.join(EMAIL_RECEIVERS)
    msg['Cc'] = ', '.join(EMAIL_CC)

    recipients = EMAIL_RECEIVERS + EMAIL_CC + EMAIL_BCC

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_SENDER, EMAIL_PASSWORD)
            server.sendmail(EMAIL_SENDER, recipients, msg.as_string())
    except Exception as e:
        print(f"Email error: {e}")


def main():
    validate_env()

    alerts = []
    sheet_data = []
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for check in CHECKS:
        output = run_ssh_ping(
            check['host'],
            check['source'],
            check['target']
        )

        min_latency = parse_latency(output)

        status = "OK"
        if min_latency is None:
            status = "FAILED"
        elif min_latency > check['threshold']:
            status = "HIGH LATENCY"

        sheet_data.append([
            timestamp,
            check['name'],
            check['target'],
            min_latency or "N/A",
            check['threshold'],
            status
        ])

        if status != "OK":
            alerts.append(f"{check['name']} -> {status} ({min_latency})")

    if sheet_data:
        log_to_google_sheets(sheet_data)

    if alerts:
        send_email("\n".join(alerts))


if __name__ == "__main__":
    main()