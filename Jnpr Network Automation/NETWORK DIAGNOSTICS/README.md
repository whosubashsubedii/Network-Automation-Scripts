# Jnpr-Network-Check-Automation

Automate routine Juniper network checks using SSH. This script connects to a remote device and runs multiple diagnostic commands such as BGP status, interface health, logs, and connectivity tests.

---

## 🛠 Features

* Automated SSH login using encrypted password
* Runs multiple operational commands in a single session
* Checks:

  * BGP summary
  * Interface flap status
  * Interface descriptions
  * Recent logs (up/down events)
  * Connectivity using ping
* Lightweight and easy to modify

---

## ⚙️ Prerequisites

* Linux environment (Kali, Ubuntu, etc.)
* `sshpass` installed
* `openssl` installed
* SSH access to your Juniper device

Install dependencies (if needed):

```bash
sudo apt update
sudo apt install sshpass openssl
```

---

## 💾 Setup

1. Clone the repository:

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts/
cd NETWORK DIAGNOSTICS
```

---

2. Encrypt your SSH password:

```bash
printf '%s' 'YOUR_SSH_PASSWORD' | openssl enc -aes-256-cbc -pbkdf2 -salt -out yourfile.enc -pass pass:YOUR_ENCRYPTION_PASSWORD
chmod 600 yourfile.enc
```

---

3. Set environment variables (recommended instead of hardcoding):

```bash
export SSH_USER="your_username"
export ENCRYPTION_PASSWORD="your_encryption_password"
```

---

4. Update script placeholders:

Replace the following values inside the script:

* `YOUR_SERVER_IP` → your actual server IP
* `yourfile.enc` → your encrypted password file
* `XXXXX` → your ASN or filter values
* `LOCATION1/2/3` → your interface/location tags
* `X.X.X.X` → target IPs for ping tests

---

## 🚀 Usage

Make the script executable:

```bash
chmod +x your-script.sh
```

Run the script:

```bash
./your-script.sh
```

---

## 📋 Example Commands Executed

```text
show bgp summary | match XXXXX
show interfaces aeX | match flap
show log updown | match DATE
show interface description | match LOCATION
ping X.X.X.X source X.X.X.X count 10 rapid
```

---

## 📂 File Structure

```
.
├── your-script.sh      # Main automation script
├── yourfile.enc        # Encrypted SSH password (DO NOT SHARE)
├── README.md           # Documentation
```

---

## 🔐 Security Notes

* Do NOT upload:

  * Real IP addresses
  * Username/passwords
  * `.enc` files
  * Encryption passwords

* Always use environment variables instead of hardcoding secrets.

* `sshpass` is used for simplicity. For production:
  → Use SSH key-based authentication instead.

---

## ⚠️ Disclaimer

This script is intended for learning and internal automation purposes.
Ensure proper security practices before using in production environments.

---

## 👤 Author

**SUBASH SUBEDI**
GitHub: https://github.com/whosubashsubedii

---
