# MikroTik Basic Configuration Generator

This script helps generate basic MikroTik router configuration commands quickly.
It takes user input and outputs ready-to-use CLI commands for initial setup.

---

## 🛠 Features

* Interactive input (easy for beginners)
* Generates full basic configuration:

  * Bridge setup
  * WAN & LAN IP assignment
  * DNS configuration
  * DHCP server setup
  * Default route
  * NAT (internet access)
* Copy-paste ready output

---

## ⚙️ Prerequisites

* Linux / macOS terminal or Windows (with Git Bash)
* Basic MikroTik CLI knowledge
* Access to MikroTik RouterOS

---

## 💾 Setup

1. Clone the repository:

```bash
git clone https://github.com/Network-Automation-Scripts/MikroTik Network Automation/MIKROTIK ROUTER BASIC AUTOMATED SETUP
cd MIKROTIK ROUTER BASIC AUTOMATED SETUP
```

---

2. Make the script executable:

```bash
chmod +x mikrotik-config-generator.sh
```

---

## 🚀 Usage

Run the script:

```bash
./mikrotik-config-generator.sh
```

---

## 🧾 Example Input

```text
Enter Bridge Name: bridge1
Enter WAN Interface: ether1
Enter LAN Interface: ether2
Enter Public IP: 10.10.69.50/24
Enter Local IP: 192.168.1.1/24
Enter DNS: 8.8.8.8
Enter Gateway: 10.10.69.250
```

---

## 📤 Example Output

```bash
/interface bridge add name=bridge1
/interface bridge port add bridge=bridge1 interface=ether2

/ip address add address=10.10.69.50/24 interface=ether1
/ip address add address=192.168.1.1/24 interface=bridge1

/ip dns set servers=8.8.8.8

/ip pool add name=dhcp_pool ranges=192.168.1.2-192.168.1.254

/ip dhcp-server add name=dhcp1 interface=bridge1 address-pool=dhcp_pool disabled=no
/ip dhcp-server network add address=192.168.1.0/24 gateway=192.168.1.1 dns-server=8.8.8.8

/ip route add dst-address=0.0.0.0/0 gateway=10.10.69.250

/ip firewall nat add chain=srcnat action=masquerade
```

---

## 📂 File Structure

```
.
├── mikrotik-config-generator.sh   # Main script
├── README.md                      # Documentation
```

---

## ⚠️ Notes

* This script only generates configuration. It does NOT apply it automatically.
* Always verify values before applying on production routers.
* Default DHCP range is fixed (192.168.1.2–254). Modify if needed.

---

## 🔐 Security Considerations

* Do not use real production IPs in public examples
* Review firewall rules before deployment
* Apply configurations in a safe environment first

---

## 🔧 Possible Improvements

* Add input validation (IP format, interface check)
* Dynamic DHCP pool based on subnet
* Option to export config to file
* Add firewall filter rules

---

## 👤 Author

**Subash Subedi**
GitHub: https://github.com/whosubashsubedii

---
