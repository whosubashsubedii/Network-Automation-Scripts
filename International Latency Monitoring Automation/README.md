# International Latency Monitoring Automation

Automated latency monitoring system for international network links using Juniper routers.
This script performs periodic latency checks, logs results, and sends email alerts.

---

## 🛠 Features

* SSH into remote monitoring servers
* Run 1000 rapid ping tests
* Extract **minimum latency** (baseline performance)
* Compare against defined thresholds
* Log results to Google Sheets
* Send automated email reports:

  * Critical alerts
  * Normal status summary
* Designed to run hourly via cron

---

## ⚙️ How It Works

For each configured location:

1. SSH into monitoring server
2. Run rapid ping test
3. Extract **minimum latency (min/avg/max)**
4. Compare with threshold
5. Store results in Google Sheets
6. Send combined email report

---

## ⚙️ Prerequisites

* Python 3
* Linux environment (recommended)
* `sshpass` installed
* `openssl` installed
* Google Cloud Service Account (for Sheets)
* Gmail App Password (for email)

Install dependencies:

```bash
sudo apt update
sudo apt install sshpass openssl
pip install gspread google-auth
```

---

## 💾 Setup

### 1. Clone Repository

```bash
git clone https://github.com/Network-Automation-Scripts/International Latency Monitoring Automation
cd International Latency Monitoring Automation
```

---

### 2. Google Sheets Setup

* Create a Google Sheet (e.g., **International Latency**)
* Create a Service Account in Google Cloud
* Download `credentials.json`
* Share the sheet with the service account email

---

### 3. Encrypt SSH Password

```bash
printf '%s' 'YOUR_SSH_PASSWORD' | openssl enc -aes-256-cbc -pbkdf2 -salt -out yourfile.enc -pass pass:YOUR_ENCRYPTION_PASSWORD
chmod 600 yourfile.enc
```

---

### 4. Update Script Configuration

⚠ **DO NOT upload real values to GitHub**

Update these safely:

#### Email Settings

* `EMAIL_SENDER`
* `EMAIL_PASSWORD` → use Gmail App Password
* `EMAIL_RECEIVERS / CC / BCC`

#### Encryption

* `ENCRYPTION_PASSWORD`
* `ENCRYPTED_FILE`

#### Google Sheets

* `GOOGLE_SHEET_NAME`
* `SERVICE_ACCOUNT_FILE`

#### Monitoring Targets

Replace with your actual values:

```python
CHECKS = [
    {
        "name": "LOCATION_NAME",
        "host": "YOUR_SERVER_IP",
        "source": "SOURCE_IP",
        "target": "TARGET_IP",
        "threshold": 50
    }
]
```

---

## 🚀 Usage

Run manually:

```bash
python3 your-script.py
```

---

### ⏰ Run Automatically (Cron)

```bash
crontab -e
```

Example (run every hour):

```bash
0 * * * * /usr/bin/python3 /path/to/your-script.py >> /path/to/logfile.log 2>&1
```

---

## 📊 Output

### Google Sheets

Logs:

* Timestamp
* Location
* Target IP
* Minimum latency
* Threshold
* Status

---

### Email Report

Includes:

* Critical alerts (high latency / failure)
* Normal status checks
* Full ping output for troubleshooting

---

## 📂 File Structure

```
.
├── latency-monitor.py        # Main script
├── credentials.json         # Google service account (DO NOT SHARE)
├── yourfile.enc             # Encrypted SSH password (DO NOT SHARE)
├── README.md
```

---

## 🔐 Security Notes (Important)

Before pushing to GitHub:

* ❌ Remove:

  * Real IP addresses
  * Email passwords
  * Encryption passwords
  * `.enc` files
  * `credentials.json`

* ✅ Use:

  * Environment variables
  * `.gitignore`

Example `.gitignore`:

```
*.enc
credentials.json
.env
```

---

## ⚠️ Limitations

* Uses `sshpass` (not recommended for production)
* Depends on remote device SSH access
* Requires stable internet for Google Sheets logging

---

## 🔧 Recommended Improvements

* Replace password auth with SSH keys
* Add retry logic for failed SSH
* Add latency graph visualization
* Store logs locally (backup)

---

## 👤 Author

**Subash Subedi**
Contact: [wlink.contact@subashsubedi0.com.np](mailto:wlink.contact@subashsubedi0.com.np)
GitHub: https://github.com/whosubashsubedii

---
