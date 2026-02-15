


# VPLS Configuration Script for Juniper Routers

This Python script generates Juniper router configuration commands to set up **VPLS (Virtual Private LAN Service)**, based on user input.

## 🔧 Features

* Accepts inputs for:

  * VPLS instance name
  * Bundle interface (e.g., `ae6`)
  * VLAN ID
* Optionally configures one or more VPLS neighbors
* Outputs complete CLI configuration commands for Juniper routers

## 🧪 Example Usage

```bash
$ python vpls_config.py
Enter the name of vpls: CUSTOMER1-VPLS
Enter the Bundle name Eg:ae6: ae6
Enter the vlan : 100
Do you want to configure a neighbor? (yes/no): yes
Enter neighbor IP: 192.0.2.1
Add another neighbour? (yes/no)): yes
Enter neighbor IP: 192.0.2.2
Add another neighbour? (yes/no)): no
```

### 🖥️ Sample Output

```bash
### The Command to configure VPLS in JUNIPER ROUTER ####

set interfaces ae6 unit 100 description CUSTOMER1-VPLS
set interfaces ae6 unit 100 encapsulation vlan-vpls
set interfaces ae6 unit 100 vlan-id 100
set interfaces ae6 unit 100 family vpls
set routing-instances CUSTOMER1-VPLS interface ae6.100
set routing-instances CUSTOMER1-VPLS protocols vpls vpls-id 100
set routing-instances CUSTOMER1-VPLS description CUSTOMER1-VPLS
set routing-instances CUSTOMER1-VPLS instance-type vpls
set routing-instances CUSTOMER1-VPLS protocols vpls no-tunnel-services
set routing-instances CUSTOMER1-VPLS protocols vpls vpls-id 100
set routing-instances CUSTOMER1-VPLS protocols vpls neighbor 192.0.2.1 pseudowire-status-tlv
set routing-instances CUSTOMER1-VPLS protocols vpls neighbor 192.0.2.2 pseudowire-status-tlv
```

## 💾 File Structure

```
vpls_config.py       # Main Python script
README.md            # Documentation file
```

## 📋 Requirements

* Python 3.x

## 🚀 How to Run

```bash
python vpls_config.py
```
