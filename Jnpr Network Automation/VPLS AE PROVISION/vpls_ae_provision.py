vpls_name = input("Enter the name of VPLS: ")
aggregated_ethernet = input("Enter the Aggregated Ethernet number (e.g., 16): ")
vlan = input("Enter the VLAN Number: ")

print(f"""

### Command to Configure a Missing Aggregated Ethernet (AE) Interface in Juniper Router  ####

configure private

set interfaces ae{aggregated_ethernet} unit {vlan} description {vpls_name}
set interfaces ae{aggregated_ethernet} unit {vlan} encapsulation vlan-vpls
set interfaces ae{aggregated_ethernet} unit {vlan} vlan-id {vlan}
set interfaces ae{aggregated_ethernet} unit {vlan} family vpls
set routing-instances {vpls_name} interface ae{aggregated_ethernet}.{vlan}
set routing-instances {vpls_name} protocols vpls vpls-id {vlan}
set routing-instances {vpls_name} description {vpls_name}
set routing-instances {vpls_name} instance-type vpls
set routing-instances {vpls_name} protocols vpls no-tunnel-services
set routing-instances {vpls_name} protocols vpls vpls-id {vlan}

commit check

""")

input("Press Enter to exit...")