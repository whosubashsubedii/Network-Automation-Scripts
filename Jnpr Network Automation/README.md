
```markdown
# Jnpr Network Automation

A collection of automation scripts for Juniper network devices, designed to simplify monitoring, configuration, and management tasks. This repository currently includes tools for temperature monitoring, alarm monitoring, and VPLS configuration.

---

## 🛠 Features

- **Automated SSH login** with encrypted passwords for secure access.
- **Temperature monitoring** of chassis and fans.
- **Alarm monitoring** to track active device alarms and location.
- **VPLS configuration** helper for interfaces, VLANs, and neighbors.
- Interactive scripts for both Bash and Python.
- Scalable structure for adding new automation tools in the future.

---

## 📂 Repository Structure

```

Jnpr Network Automation/
├── Jnpr-Temp-Monitor-Automation
│   ├── jnpr-temp-check.sh       # Temperature monitoring script
│   ├── README.md
│   └── YOUR SSH PASSWORD.txt    # Instructions for SSH password encryption
├── Jnpr-Alarm-Monitor-Automation
│   ├── jnpr-Alarm-check.sh      # Alarm monitoring script
│   ├── README.md
│   └── YOUR SSH PASSWORD.txt
├── Jnpr-VPLS-Configuration-Script
│   ├── jnpr_vpls.py             # Python VPLS configuration script
│   ├── vpls_config.sh           # Bash VPLS configuration script
│   └── README.md
└── README.md                    # Central repository README

````

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts.git
cd "Network-Automation-Scripts/Jnpr Network Automation"
````

### 2. Choose the automation tool

| Script Folder                  | Description                                                   | Language/Type |
| ------------------------------ | ------------------------------------------------------------- | ------------- |
| Jnpr-Temp-Monitor-Automation   | Monitor chassis temperature, fan status, and hot log messages | Bash          |
| Jnpr-Alarm-Monitor-Automation  | Monitor chassis alarms and device location                    | Bash          |
| Jnpr-VPLS-Configuration-Script | Generate VPLS configuration commands interactively            | Python/Bash   |

### 3. Setup (For Bash Scripts)

1. Encrypt your SSH password (if not already done):

```bash
printf '%s' 'YOUR_SSH_PASSWORD_HERE' | openssl enc -aes-256-cbc -pbkdf2 -salt -out my_ssh_pass.enc -pass pass:MySecurePass123
chmod 600 my_ssh_pass.enc
```

2. Update the script with your SSH username and encryption password.

3. Make the Bash scripts executable if needed:

```bash
chmod +x jnpr-temp-check.sh
chmod +x jnpr-Alarm-check.sh
chmod +x vpls_config.sh
```

### 4. Usage

* **Temperature Monitoring:**

```bash
./Jnpr-Temp-Monitor-Automation/jnpr-temp-check.sh
```

* **Alarm Monitoring:**

```bash
./Jnpr-Alarm-Monitor-Automation/jnpr-Alarm-check.sh
```

* **VPLS Configuration:**

```bash
# Bash version
./Jnpr-VPLS-Configuration-Script/vpls_config.sh

# Python version
python3 ./Jnpr-VPLS-Configuration-Script/jnpr_vpls.py
```

Follow the interactive prompts for device short names, VPLS details, VLANs, bundles, and neighbors.

---

## ⚠️ Notes

* Scripts **generate commands** or **fetch device info**. You still need to apply configurations on Juniper devices manually.
* Keep `.enc` password files secure.
* Use scripts responsibly in production environments.

---

## 📝 Future Additions

* Automated configuration push to Juniper devices.
* Support for Junos OS versions compatibility.
* Integration with logging and alerting tools.

---

## 👤 Author

Made by **SUBASH SUBEDI**
GitHub: [whosubashsubedii](https://github.com/whosubashsubedii)

```


