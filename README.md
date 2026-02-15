
```markdown
# Network Automation Scripts

A centralized collection of network automation scripts for multiple vendors including Juniper, Cisco, and MikroTik. This repository is designed to help network engineers automate routine tasks like monitoring, configuration, and device management.

---

## 🛠 Features

- Vendor-specific automation scripts: Juniper, Cisco, MikroTik.
- Automated SSH login with encrypted passwords.
- Monitoring scripts for temperature, alarms, and environment.
- Configuration helpers (e.g., VPLS configuration for Juniper).
- Interactive scripts with prompts for ease of use.
- Scalable structure for future tools and scripts.

---

## 📂 Repository Structure

```

Network-Automation-Scripts/
├── Csco Network Automation/
│
├── Jnpr Network Automation/
│
├── MikroTik Network Automation/
│
└── README.md

````

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts.git
cd "Network-Automation-Scripts"
````

### 2. Navigate to the vendor-specific folder

| Vendor   | Folder                      | Description                               |
| -------- | --------------------------- | ----------------------------------------- |
| Juniper  | Jnpr Network Automation     | Juniper network automation scripts        |
| Cisco    | Csco Network Automation     | Cisco network automation scripts (TBD)    |
| MikroTik | MikroTik Network Automation | MikroTik network automation scripts (TBD) |

### 3. Follow individual README.md files

Each vendor folder contains its own `README.md` with setup, usage, and instructions specific to that set of scripts.

---

## ⚠️ Notes

* Bash scripts may require `sshpass` and `openssl`.
* Python scripts require Python 3.x.
* Always secure `.enc` password files and use scripts responsibly in production environments.

---

## 📝 Future Additions

* Expanded scripts for Cisco and MikroTik.
* Automated configuration push for multiple devices.
* Logging, alerting, and reporting integration.
* Vendor-specific dashboards or monitoring tools.

---

## 👤 Author

Made by **SUBASH SUBEDI**
GitHub: [whosubashsubedii](https://github.com/whosubashsubedii)

```
