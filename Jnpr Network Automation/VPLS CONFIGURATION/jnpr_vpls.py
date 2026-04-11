vpls = input("Enter the name of vpls: ")
bundle = input("Enter the Bundle name Eg:ae6: ")
vlan = input ("Enter the vlan : ")

neighbour_cmd = ""

add_neighbour = input("Do you want to configure a neighbor? (yes/no):").strip().lower()

if add_neighbour == "yes":
   while True:
     neighbour_ip = input("Enter neighbor IP: ")
     neighbour_cmd += f"set routing-instances {vpls} protocols vpls neighbor {neighbour_ip} pseudowire-status-tlv\n"
     more = input("Add another neighbour? (yes/no)): ")
     if more != "yes":
        break

print(f"""
      ### The Command to configure VPLS in JUNIPER ROUTER ####

set interfaces {bundle} unit {vlan} description {vpls}
set interfaces {bundle} unit {vlan} encapsulation vlan-vpls
set interfaces {bundle} unit {vlan} vlan-id {vlan}
set interfaces {bundle} unit  {vlan} family vpls
set routing-instances {vpls} interface {bundle}.{vlan}
set routing-instances {vpls} protocols vpls vpls-id {vlan}
set routing-instances {vpls} description {vpls}
set routing-instances {vpls} instance-type vpls
set routing-instances {vpls} protocols vpls no-tunnel-services
set routing-instances {vpls} protocols vpls vpls-id {vlan}
{neighbour_cmd}
""")

a = input()