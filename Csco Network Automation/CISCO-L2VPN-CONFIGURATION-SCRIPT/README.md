
# Cisco VPLS Configuration Generator

This Python script generates CLI-ready configuration commands for setting up **VPLS (Virtual Private LAN Service)** on Cisco routers using **L2VPN**.

## 🔧 What It Does

- Prompts the user for:
  - VPLS instance name
  - Bundle interface name (e.g., `10` for `Bundle-Ether10`)
  - VLAN ID
  - Optional neighbor IP for pseudowire configuration

- Outputs a pre-formatted configuration snippet for use in Cisco routers.

---

## ✅ Requirements

- Python 3.x installed on your machine
- Basic knowledge of Cisco VPLS/L2VPN configurations

---

## 🚀 How to Use

1. Run the script in a terminal:

   ```bash
   python vpls_cisco_config.py
````

2. Follow the prompts:

   ```text
   Enter the name of vpls: Cust-A
   Enter the Bundle name Eg:Bundle-Ether10: 10
   Enter the vlan : 200
   Do you want to configure neighbour? (yes/no): yes
   Enter the neighbour ip: 192.0.2.10
   ```

3. The script will output:

   ```text
   ### The Command to configure VPLS in Cisco ####

   l2vpn

    bridge group Cust-A 

     bridge-domain Cust-A 

      interface Bundle-Ether10.200

      exit

      vfi Cust-A neighbour 192.0.2.10 pw-id 200

      exit

     exit

    exit

   exit


   -----------------------------------------------------------

   interface Bundle-Ether10.200 l2transport description Cust-A
   interface Bundle-Ether10.200 l2transport encapsulation dot1q 200

   end
   ```

---

## 📁 File Structure

```
vpls_cisco_config.py
README.md
```

---

## 💡 Notes

* The script does not push configuration to a live device; it only generates it.
* Make sure to adjust any interface or VFI settings as needed for your network design.
* `pw-id` is set to match the VLAN ID by default.

---

## 🔄 To-Do (Optional Enhancements)

* Support multiple neighbors
* Save output to a `.txt` file
* Add error handling for input formats

---

## 🛡 Disclaimer

This script is provided as-is for lab and production prep. Always validate configurations in a staging environment before deploying to live equipment.