````markdown
# Jnpr-Temp-Monitor-Automation

Automate Juniper network device temperature and fan monitoring using SSH. This script allows you to securely log in to your Juniper devices and retrieve key environment metrics without manually entering passwords.

---

## 🛠 Features

- SSH login to Juniper devices using encrypted passwords.
- Fetch temperature, fan status, and hot log messages.
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
cd Network-Automation-Scripts/Jnpr\ Network\ Automation/Jnpr-Temp-Monitor-Automation
````

2. Encrypt your SSH password (if not already done):

```bash
printf '%s' 'YOUR_SSH_PASSWORD_HERE' | openssl enc -aes-256-cbc -pbkdf2 -salt -out my_ssh_pass.enc -pass pass:MySecurePass123
chmod 600 my_ssh_pass.enc
```

3. Update the script `jnpr-temp-check.sh`:

* Replace `#ENTER YOUR ENCRYPT PASSWORD NAME` with your encryption password.
* Replace `#ENTER YOUR USERNAME` with your SSH username.

---

## 🚀 Usage

Run the script:

```bash
./jnpr-temp-check.sh
```

You will be prompted to enter the short name of the device (e.g., `amar`, `dnkt`). The script will:

* Map the short name to the full router name.
* SSH into the device.
* Execute commands to check temperature, fan status, and hot log messages.

Example commands executed on the device:

```text
show chassis routing-engine | match TEMP
show chassis environment | match FAN
show log messages | match HOT
```

---

## 📂 File Structure

```
.
├── jnpr-temp-check.sh       # Main automation script
├── README.md                # Project documentation
└── YOUR SSH PASSWORD.txt    # Instructions for SSH password encryption
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


