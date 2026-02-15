````markdown
# Jnpr-Alarm-Monitor-Automation

Automate Juniper network device alarm monitoring using SSH. This script allows you to securely log in to your Juniper devices and retrieve active chassis alarms and location information without manually entering passwords.

---

## 🛠 Features

- SSH login to Juniper devices using encrypted passwords.
- Fetch active chassis alarms and device location.
- Supports multiple devices via short name mapping.
- Color-coded terminal output for easy readability.

---

## ⚙️ Prerequisites

- Linux or macOS terminal environment
- `sshpass` installed
- `openssl` for encryption/decryption
- Juniper devices accessible via SSH

---

## 💾 Setup

1. Clone the repository:

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts.git
cd Network-Automation-Scripts/Jnpr\ Network\ Automation/Jnpr-Alarm-Monitor-Automation
````

2. Encrypt your SSH password (if not already done):

```bash
printf '%s' 'YOUR_SSH_PASSWORD_HERE' | openssl enc -aes-256-cbc -pbkdf2 -salt -out my_ssh_pass.enc -pass pass:MySecurePass123
chmod 600 my_ssh_pass.enc
```

3. Update the script `jnpr-Alarm-check.sh`:

* Replace `#ENTER YOUR ENCRYPT PASSWORD NAME` with your encryption password.
* Replace `#ENTER YOUR USERNAME` with your SSH username.

---

## 🚀 Usage

Run the script:

```bash
./jnpr-Alarm-check.sh
```

You will be prompted to enter the short name of the device (e.g., `amar`, `dnkt`). The script will:

* Map the short name to the full router name.
* SSH into the device.
* Execute commands to check active chassis alarms and device location.

Example commands executed on the device:

```text
show chassis alarms
show chassis location
```

---

## 📂 File Structure

```
.
├── jnpr-Alarm-check.sh      # Main automation script
├── README.md                 # Project documentation
└── YOUR SSH PASSWORD.txt     # Instructions for SSH password encryption
```

---

## ⚠️ Warning

* This script uses SSH with passwords stored in encrypted form. Ensure the `.enc` files and passwords are kept secure.
* Use this script responsibly in production environments.

---

## 👤 Author

Made by **SUBASH SUBEDI**
GitHub: [whosubashsubedii](https://github.com/whosubashsubedii)

```


