
````markdown
# Jnpr-VPLS-Configuration-Script

Automate VPLS configuration on Juniper routers using interactive Python or Bash scripts. This tool helps network engineers quickly generate configuration commands for interfaces, VLANs, and VPLS neighbors.

---

## 🛠 Features

- Generate Juniper VPLS configuration commands interactively.
- Supports multiple neighbor entries for VPLS instances.
- Works with both Python (`jnpr_vpls.py`) and Bash (`vpls_config.sh`) scripts.
- Easy-to-use prompts to reduce manual configuration errors.

---

## ⚙️ Prerequisites

- Linux or macOS terminal environment
- Python 3.x (for `jnpr_vpls.py`)
- Bash shell (for `vpls_config.sh`)
- Access to Juniper routers to apply configuration

---

## 💾 Setup

1. Clone the repository:

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts.git
cd Network-Automation-Scripts/Jnpr\ Network\ Automation/Jnpr-VPLS-Configuration-Script
````

2. Choose your preferred script:

* **Python:** `jnpr_vpls.py`
* **Bash:** `vpls_config.sh`

3. Make Bash script executable (if using `vpls_config.sh`):

```bash
chmod +x vpls_config.sh
```

---

## 🚀 Usage

### Python Script

Run the Python script:

```bash
python3 jnpr_vpls.py
```

* Enter the VPLS name, bundle (e.g., `ae6`), VLAN.
* Optionally, add neighbors (multiple entries supported).
* The script prints all commands needed for Juniper VPLS configuration.

### Bash Script

Run the Bash script:

```bash
./vpls_config.sh
```

* Follow interactive prompts for VPLS name, bundle, VLAN, and neighbors.
* The script outputs the full set of configuration commands.
* Press Enter to exit after reviewing the output.

---

## 📂 File Structure

```
.
├── jnpr_vpls.py        # Python VPLS configuration script
├── vpls_config.sh       # Bash VPLS configuration script
└── README.md            # Project documentation
```

---

## ⚠️ Notes

* Scripts only **generate configuration commands**. You still need to copy/apply them on the actual Juniper devices.
* Python script requires Python 3.x installed.
* Bash script requires a Bash shell environment.

---

## 👤 Author

Made by **SUBASH SUBEDI**
GitHub: [whosubashsubedii](https://github.com/whosubashsubedii)

```

