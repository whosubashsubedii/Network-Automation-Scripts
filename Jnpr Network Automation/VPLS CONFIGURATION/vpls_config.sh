#!/bin/bash

# Prompt for VPLS name, bundle, and VLAN
read -p "Enter the name of VPLS: " vpls
read -p "Enter the Bundle name (e.g., ae6): " bundle
read -p "Enter the VLAN: " vlan

neighbour_cmd=""

# Ask if user wants to configure neighbors
read -p "Do you want to configure a neighbor? (yes/no): " add_neighbour
add_neighbour=$(echo $add_neighbour | tr '[:upper:]' '[:lower:]')

if [ "$add_neighbour" == "yes" ]; then
  while true; do
    read -p "Enter neighbor IP: " neighbour_ip
    neighbour_cmd+="set routing-instances $vpls protocols vpls neighbor $neighbour_ip pseudowire-status-tlv"$'\n'
    read -p "Add another neighbor? (yes/no): " more
    more=$(echo $more | tr '[:upper:]' '[:lower:]')
    if [ "$more" != "yes" ]; then
      break
    fi
  done
fi

# Print the final configuration
echo "### The Command to configure VPLS in JUNIPER ROUTER ####"
echo "set interfaces $bundle unit $vlan description $vpls"
echo "set interfaces $bundle unit $vlan encapsulation vlan-vpls"
echo "set interfaces $bundle unit $vlan vlan-id $vlan"
echo "set interfaces $bundle unit $vlan family vpls"
echo "set routing-instances $vpls interface $bundle.$vlan"
echo "set routing-instances $vpls protocols vpls vpls-id $vlan"
echo "set routing-instances $vpls description $vpls"
echo "set routing-instances $vpls instance-type vpls"
echo "set routing-instances $vpls protocols vpls no-tunnel-services"
echo "set routing-instances $vpls protocols vpls vpls-id $vlan"
echo "$neighbour_cmd"

# Pause to let user see the output
read -p "Press Enter to exit..."
