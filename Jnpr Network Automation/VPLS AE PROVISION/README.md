# Jnpr-VPLS-Config-Generator

Generate Juniper configuration commands for creating a VPLS instance and Aggregated Ethernet (AE) interface. This script helps reduce manual errors and speeds up provisioning.

---

## 🛠 Features

* Generates ready-to-use Junos configuration
* Supports:

  * Aggregated Ethernet (AE) interface setup
  * VLAN configuration
  * VPLS instance creation
* Simple interactive input
* Reduces syntax mistakes during manual config

---

## ⚙️ Prerequisites

* Python 3 installed
* Basic knowledge of Juniper CLI
* Access to Juniper router (for applying config)

---

## 💾 Setup

1. Clone the repository:

```bash
git clone https://github.com/whosubashsubedii/Network-Automation-Scripts/
cd VPLS AE PROVISION
```

---

2. Save the script as:

```bash
vpls-config-generator.py
```

---

## 🚀 Usage

Run the script:

```bash
python3 vpls-config-generator.py
```

You will be prompted to enter:

* VPLS Name
* Aggregated Ethernet number (e.g., 16 → ae16)
* VLAN ID

---

## 📋 Example Input

```text
Enter the name of VPLS: CUSTOMER_A
Enter the Aggregated Ethernet number (e.g., 16): 16
Enter the VLAN Number: 100
```

---

## 📤 Example Output

```text
configure private

set interfaces ae16 unit 100 description CUSTOMER_A
set interfaces ae16 unit 100 encapsulation vlan-vpls
set interfaces ae16 unit 100 vlan-id 100
set interfaces ae16 unit 100 family vpls
set routing-instances CUSTOMER_A interface ae16.100
set routing-instances CUSTOMER_A protocols vpls vpls-id 100
set routing-instances CUSTOMER_A description CUSTOMER_A
set routing-instances CUSTOMER_A instance-type vpls
set routing-instances CUSTOMER_A protocols vpls no-tunnel-services

commit check
```

---

## 📂 File Structure

```
.
├── vpls_ae_provision.py   # Main script
├── README.md                 # Documentation
```

---

## ⚠️ Notes

* This script only generates configuration. It does NOT push config to devices.
* Always verify output before applying on production routers.
* Use `commit check` before actual commit.

---

## 🔐 Best Practice

* Avoid duplicate VLAN IDs in same VPLS domain
* Confirm AE interface exists before applying config
* Follow your network naming standards

---

## 👤 Author

**SUBASH SUBEDI**
GitHub: https://github.com/whosubashsubedii

---
