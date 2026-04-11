#!/usr/bin/env bash
set -euo pipefail

###############################################
# MikroTik RouterOS v7.x Deployment Builder
# Bash script that generates a RouterOS .rsc file
# and can optionally apply it over SSH.
###############################################

SCRIPT_NAME="$(basename "$0")"
TMP_RSC="/tmp/mikrotik_deploy_$$.rsc"

cleanup() {
    rm -f "$TMP_RSC"
}
trap cleanup EXIT

# ----------------------------
# Helper functions
# ----------------------------
prompt() {
    local var_name="$1"
    local text="$2"
    local default="${3:-}"
    local value

    if [[ -n "$default" ]]; then
        read -r -p "$text [$default]: " value
        value="${value:-$default}"
    else
        read -r -p "$text: " value
    fi

    printf -v "$var_name" '%s' "$value"
}

prompt_secret() {
    local var_name="$1"
    local text="$2"
    local value
    read -r -s -p "$text: " value
    echo
    printf -v "$var_name" '%s' "$value"
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

require_number() {
    local value="$1"
    local field="$2"
    if ! is_number "$value"; then
        echo "ERROR: $field must be a number."
        exit 1
    fi
}

ssh_apply() {
    local target_ip="$1"
    local username="$2"
    local password="$3"
    local rsc_file="$4"

    echo
    echo "Applying configuration to $target_ip ..."

    if [[ -n "$password" ]]; then
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$password" scp -o StrictHostKeyChecking=accept-new "$rsc_file" "$username@$target_ip:/$(
                basename "$rsc_file"
            )"
            sshpass -p "$password" ssh -o StrictHostKeyChecking=accept-new "$username@$target_ip" \
                "/import file-name=$(basename "$rsc_file")"
        else
            echo "sshpass not found. Falling back to interactive SSH/SCP."
            scp -o StrictHostKeyChecking=accept-new "$rsc_file" "$username@$target_ip:/$(basename "$rsc_file")"
            ssh -o StrictHostKeyChecking=accept-new "$username@$target_ip" \
                "/import file-name=$(basename "$rsc_file")"
        fi
    else
        scp -o StrictHostKeyChecking=accept-new "$rsc_file" "$username@$target_ip:/$(basename "$rsc_file")"
        ssh -o StrictHostKeyChecking=accept-new "$username@$target_ip" \
            "/import file-name=$(basename "$rsc_file")"
    fi

    echo "Configuration imported on router."
}

# ----------------------------
# Banner
# ----------------------------
echo "##############################################################"
echo "#     MikroTik Interactive Provisioning Builder (Bash)       #"
echo "#     VLAN-per-port + Security + Dynamic DHCP               #"
echo "##############################################################"
echo

# ----------------------------
# Router access (optional apply)
# ----------------------------
prompt APPLY_NOW "Apply config directly to MikroTik over SSH? (yes/no)" "no"

TARGET_IP=""
SSH_USER=""
SSH_PASS=""

if [[ "$APPLY_NOW" == "yes" ]]; then
    prompt TARGET_IP "Target MikroTik IP address"
    prompt SSH_USER "SSH username" "admin"
    prompt_secret SSH_PASS "SSH password (leave empty if none)"
fi

# ----------------------------
# Collect config inputs
# ----------------------------
echo
echo "--- SYSTEM IDENTITY ---"
prompt ROUTER_NAME "Router identity name" "MikroTik-Router"

echo
echo "--- TIMEZONE ---"
prompt TIMEZONE "Timezone" "Asia/Kathmandu"

echo
echo "--- WAN INTERFACE ---"
prompt WAN_IFACE "WAN interface name" "ether1"
prompt WAN_COMMENT "WAN interface comment" "WAN uplink on $WAN_IFACE"

echo
echo "--- TRUNK / UPLINK PORT (OPTIONAL) ---"
prompt TRUNK_IFACE "Trunk/uplink interface for tagged VLANs (leave blank if none)" ""
HAS_TRUNK=0
if [[ -n "$TRUNK_IFACE" ]]; then
    HAS_TRUNK=1
fi

prompt BRIDGE_COMMENT "Comment for br-lan bridge" "LAN bridge with VLAN filtering"

echo
echo "--- VLAN CONFIGURATION ---"
prompt START_VLAN_ID "Starting VLAN ID" "92"
prompt NUM_VLANS "Number of VLANs to create (1-9)" "9"
prompt BASE_OCTET "Base IP second octet" "20"
prompt MGMT_VLAN_ID "Management VLAN ID" "$START_VLAN_ID"

require_number "$START_VLAN_ID" "Starting VLAN ID"
require_number "$MGMT_VLAN_ID" "Management VLAN ID"

if (( NUM_VLANS < 1 )); then NUM_VLANS=1; fi
if (( NUM_VLANS > 9 )); then NUM_VLANS=9; fi

echo
echo "--- DNS CONFIGURATION ---"

prompt DNS_SERVERS "Upstream DNS servers" "1.1.1.1,8.8.8.8"


echo
echo "##############################################################"
echo "#                  CONFIGURATION SUMMARY                    #"
echo "##############################################################"
echo "  Router Name    : $ROUTER_NAME"
echo "  Timezone       : $TIMEZONE"
echo "  WAN Interface  : $WAN_IFACE ($WAN_COMMENT)"
echo "  Bridge Comment : $BRIDGE_COMMENT"
if (( HAS_TRUNK == 1 )); then
    echo "  Trunk Port     : $TRUNK_IFACE"
fi
echo "  Start VLAN ID  : $START_VLAN_ID"
echo "  VLAN Count     : $NUM_VLANS"
echo "  Base IP Octet  : $BASE_OCTET"
echo "  Mgmt VLAN ID   : $MGMT_VLAN_ID"
echo "  DNS Servers    : $DNS_SERVERS"
echo

prompt CONFIRM "Generate configuration? (yes/no)" "yes"
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

# ----------------------------
# Calculate management subnet
# ----------------------------
MGMT_SUBNET=""
for ((i=0; i<NUM_VLANS; i++)); do
    THIS_VLAN_ID=$((START_VLAN_ID + i))
    THIS_OCTET=$((BASE_OCTET + (i * 10)))
    if (( THIS_VLAN_ID == MGMT_VLAN_ID )); then
        MGMT_SUBNET="10.${THIS_OCTET}.0.0/24"
        break
    fi
done

if [[ -z "$MGMT_SUBNET" ]]; then
    echo "ERROR: Management VLAN ID $MGMT_VLAN_ID is outside generated VLAN range."
    exit 1
fi

# ----------------------------
# Build RouterOS .rsc
# ----------------------------
{

    echo "# ==============================================="
    echo "# Generated by $SCRIPT_NAME"
    echo "# RouterOS v7.x deployment config"

    echo "# ==============================================="
    echo
    echo ":log info \"=== Deployment Import Started ===\";"
    echo


    echo "/system identity set name=\"$ROUTER_NAME\""
    echo "/system clock set time-zone-name=\"$TIMEZONE\""

    echo "/system ntp client set enabled=yes"
    echo "/system ntp client servers add address=pool.ntp.org"
    echo

    echo "/interface list add name=WAN comment=\"WAN uplinks\""
    echo "/interface list add name=LAN comment=\"All internal VLAN L3 interfaces\""
    echo "/interface list add name=MGMT comment=\"Management VLAN interface\""
    echo "/interface list member add list=WAN interface=\"$WAN_IFACE\" comment=\"$WAN_COMMENT\""
    echo

    echo "/interface bridge add name=br-lan protocol-mode=rstp vlan-filtering=no auto-mac=yes comment=\"$BRIDGE_COMMENT\""
    echo

    # Bridge ports
    for ((i=0; i<NUM_VLANS; i++)); do
        PORT_NUM=$((i + 2))
        ETH_NAME="ether${PORT_NUM}"
        THIS_VLAN_ID=$((START_VLAN_ID + i))
        THIS_OCTET=$((BASE_OCTET + (i * 10)))
        NETWORK_BASE="10.${THIS_OCTET}.0"

        echo "/interface bridge port add bridge=br-lan interface=\"$ETH_NAME\" pvid=$THIS_VLAN_ID frame-types=admit-only-untagged-and-priority-tagged comment=\"Access: VLAN${THIS_VLAN_ID} -> ${NETWORK_BASE}.0/24\""
    done

    if (( HAS_TRUNK == 1 )); then
        echo "/interface bridge port add bridge=br-lan interface=\"$TRUNK_IFACE\" frame-types=admit-only-vlan-tagged comment=\"Trunk/uplink: tagged all VLANs\""
    fi
    echo

    # Bridge VLAN table
    for ((i=0; i<NUM_VLANS; i++)); do
        PORT_NUM=$((i + 2))
        ETH_NAME="ether${PORT_NUM}"
        THIS_VLAN_ID=$((START_VLAN_ID + i))

        if (( HAS_TRUNK == 1 )); then
            echo "/interface bridge vlan add bridge=br-lan vlan-ids=$THIS_VLAN_ID tagged=br-lan,\"$TRUNK_IFACE\" untagged=\"$ETH_NAME\" comment=\"VLAN${THIS_VLAN_ID} untagged on $ETH_NAME, tagged on trunk\""
        else
            echo "/interface bridge vlan add bridge=br-lan vlan-ids=$THIS_VLAN_ID tagged=br-lan untagged=\"$ETH_NAME\" comment=\"VLAN${THIS_VLAN_ID} untagged on $ETH_NAME\""
        fi

    done
    echo

    # VLAN interfaces
    MGMT_IFACE_NAME=""

    for ((i=0; i<NUM_VLANS; i++)); do

        PORT_NUM=$((i + 2))
        THIS_VLAN_ID=$((START_VLAN_ID + i))
        VLAN_IFNAME="V${THIS_VLAN_ID}-ETH-${PORT_NUM}"


        echo "/interface vlan add name=\"$VLAN_IFNAME\" interface=br-lan vlan-id=$THIS_VLAN_ID comment=\"L3 VLAN${THIS_VLAN_ID} gateway interface\""
        echo "/interface list member add list=LAN interface=\"$VLAN_IFNAME\""


        if (( THIS_VLAN_ID == MGMT_VLAN_ID )); then
            MGMT_IFACE_NAME="$VLAN_IFNAME"
            echo "/interface list member add list=MGMT interface=\"$VLAN_IFNAME\""
        fi
    done
    echo

    # Loopback + IPs
    echo "/interface bridge add name=loopback protocol-mode=none comment=\"Router loopback bridge\""
    echo "/ip address add address=10.255.255.1/32 interface=loopback comment=\"Loopback /32 (stable router ID)\""

    for ((i=0; i<NUM_VLANS; i++)); do
        PORT_NUM=$((i + 2))
        THIS_VLAN_ID=$((START_VLAN_ID + i))
        THIS_OCTET=$((BASE_OCTET + (i * 10)))
        VLAN_IFNAME="V${THIS_VLAN_ID}-ETH-${PORT_NUM}"
        GW_ADDRESS="10.${THIS_OCTET}.0.1/24"
        ADDR_COMMENT="GW VLAN${THIS_VLAN_ID}"

        if (( THIS_VLAN_ID == MGMT_VLAN_ID )); then
            ADDR_COMMENT="${ADDR_COMMENT} (MANAGEMENT)"
        fi

        echo "/ip address add address=\"$GW_ADDRESS\" interface=\"$VLAN_IFNAME\" comment=\"$ADDR_COMMENT\""
    done
    echo

    echo "/ip dhcp-client add interface=\"$WAN_IFACE\" add-default-route=yes use-peer-dns=no use-peer-ntp=no disabled=no comment=\"WAN via DHCP on $WAN_IFACE\""
    echo

    echo "/ip dns set servers=\"$DNS_SERVERS\" allow-remote-requests=yes cache-size=4096KiB"
    echo "/ip dns static add name=router.lan address=10.255.255.1 comment=\"Router hostname\""

    echo

    # DHCP
    for ((i=0; i<NUM_VLANS; i++)); do
        PORT_NUM=$((i + 2))

        THIS_VLAN_ID=$((START_VLAN_ID + i))
        THIS_OCTET=$((BASE_OCTET + (i * 10)))

        VLAN_IFNAME="V${THIS_VLAN_ID}-ETH-${PORT_NUM}"
        POOL_NAME="DHCP_POOL_V${THIS_VLAN_ID}"

        SERVER_NAME="DHCP_V${THIS_VLAN_ID}"
        POOL_RANGE="10.${THIS_OCTET}.0.10-10.${THIS_OCTET}.0.254"

        NETWORK_ADDR="10.${THIS_OCTET}.0.0/24"
        GW_ADDR="10.${THIS_OCTET}.0.1"

        echo "/ip pool add name=\"$POOL_NAME\" ranges=\"$POOL_RANGE\" comment=\"VLAN${THIS_VLAN_ID} address pool\""
        echo "/ip dhcp-server add name=\"$SERVER_NAME\" interface=\"$VLAN_IFNAME\" address-pool=\"$POOL_NAME\" lease-time=30m authoritative=after-2sec-delay disabled=no comment=\"DHCP server for VLAN${THIS_VLAN_ID}\""
        echo "/ip dhcp-server network add address=\"$NETWORK_ADDR\" gateway=\"$GW_ADDR\" dns-server=\"$GW_ADDR\" comment=\"VLAN${THIS_VLAN_ID} DHCP network options\""
    done
    echo

    echo "/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment=\"NAT: masquerade all LAN VLANs to WAN\""
    echo

    echo "/ip firewall address-list add list=MGMT_ALLOWED address=\"$MGMT_SUBNET\" comment=\"Management access: VLAN${MGMT_VLAN_ID} only\""
    echo

    # IPv4 firewall
    echo "/ip firewall filter add chain=input action=accept connection-state=established,related,untracked comment=\"INPUT: accept established, related, untracked\""
    echo "/ip firewall filter add chain=input action=drop connection-state=invalid comment=\"INPUT: drop invalid connections\""
    echo "/ip firewall filter add chain=input action=accept protocol=icmp comment=\"INPUT: accept ICMP (ping/traceroute)\""
    echo "/ip firewall filter add chain=input action=accept in-interface-list=LAN protocol=udp dst-port=67,68 comment=\"INPUT: accept DHCP from VLAN clients\""
    echo "/ip firewall filter add chain=input action=accept in-interface-list=LAN protocol=udp dst-port=53 comment=\"INPUT: accept DNS UDP from LAN\""
    echo "/ip firewall filter add chain=input action=accept in-interface-list=LAN protocol=tcp dst-port=53 comment=\"INPUT: accept DNS TCP from LAN\""
    echo "/ip firewall filter add chain=input action=add-src-to-address-list address-list=SSH_BRUTE address-list-timeout=1d protocol=tcp dst-port=22 connection-state=new src-address-list=!MGMT_ALLOWED comment=\"INPUT: tag non-MGMT SSH attempts for blocklist\""
    echo "/ip firewall filter add chain=input action=drop src-address-list=SSH_BRUTE comment=\"INPUT: drop SSH brute-force sources\""
    echo "/ip firewall filter add chain=input action=accept src-address-list=MGMT_ALLOWED protocol=tcp dst-port=22 comment=\"INPUT: allow SSH from MGMT VLAN only\""
    echo "/ip firewall filter add chain=input action=accept src-address-list=MGMT_ALLOWED protocol=tcp dst-port=8291 comment=\"INPUT: allow Winbox from MGMT VLAN only\""
    echo "/ip firewall filter add chain=input action=accept src-address-list=MGMT_ALLOWED protocol=tcp dst-port=80,443 comment=\"INPUT: allow HTTP/HTTPS mgmt from MGMT VLAN\""
    echo "/ip firewall filter add chain=input action=drop comment=\"INPUT: default deny all other input\""
    echo
    echo "/ip firewall filter add chain=forward action=accept connection-state=established,related,untracked comment=\"FWD: accept established, related, untracked\""
    echo "/ip firewall filter add chain=forward action=drop connection-state=invalid comment=\"FWD: drop invalid\""
    echo "/ip firewall filter add chain=forward action=fasttrack-connection connection-state=established,related hw-offload=yes comment=\"FWD: FastTrack established/related\""
    echo "/ip firewall filter add chain=forward action=drop in-interface-list=LAN out-interface-list=LAN comment=\"FWD: block inter-VLAN traffic\""
    echo "/ip firewall filter add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment=\"FWD: allow VLAN clients -> WAN\""
    echo "/ip firewall filter add chain=forward action=drop in-interface-list=WAN comment=\"FWD: drop unsolicited WAN -> LAN\""
    echo

    # IPv6 baseline
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=::/128 comment=\"bad_ipv6: unspecified\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=::1 comment=\"bad_ipv6: loopback\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=fec0::/10 comment=\"bad_ipv6: site-local\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=::ffff:0:0/96 comment=\"bad_ipv6: ipv4-mapped\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=::/96 comment=\"bad_ipv6: ipv4-compat\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=100::/64 comment=\"bad_ipv6: discard\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=2001:db8::/32 comment=\"bad_ipv6: documentation\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=2001:10::/28 comment=\"bad_ipv6: ORCHID\""
    echo "/ipv6 firewall address-list add list=bad_ipv6 address=3ffe::/16 comment=\"bad_ipv6: 6bone\""
    echo
    echo "/ipv6 firewall filter add chain=input action=accept connection-state=established,related,untracked comment=\"IPv6 INPUT: accept established\""
    echo "/ipv6 firewall filter add chain=input action=drop connection-state=invalid comment=\"IPv6 INPUT: drop invalid\""
    echo "/ipv6 firewall filter add chain=input action=accept protocol=icmpv6 comment=\"IPv6 INPUT: accept ICMPv6\""
    echo "/ipv6 firewall filter add chain=input action=accept protocol=udp dst-port=33434-33534 comment=\"IPv6 INPUT: accept UDP traceroute\""
    echo "/ipv6 firewall filter add chain=input action=accept protocol=udp dst-port=546 src-address=fe80::/10 comment=\"IPv6 INPUT: DHCPv6 prefix delegation\""
    echo "/ipv6 firewall filter add chain=input action=drop in-interface-list=!LAN comment=\"IPv6 INPUT: drop not from LAN\""
    echo "/ipv6 firewall filter add chain=forward action=fasttrack-connection connection-state=established,related comment=\"IPv6 FWD: fasttrack\""
    echo "/ipv6 firewall filter add chain=forward action=accept connection-state=established,related,untracked comment=\"IPv6 FWD: accept established\""
    echo "/ipv6 firewall filter add chain=forward action=drop connection-state=invalid comment=\"IPv6 FWD: drop invalid\""
    echo "/ipv6 firewall filter add chain=forward action=drop src-address-list=bad_ipv6 comment=\"IPv6 FWD: drop bad src\""
    echo "/ipv6 firewall filter add chain=forward action=drop dst-address-list=bad_ipv6 comment=\"IPv6 FWD: drop bad dst\""
    echo "/ipv6 firewall filter add chain=forward action=drop protocol=icmpv6 hop-limit=equal:1 comment=\"IPv6 FWD: drop hop-limit=1\""
    echo "/ipv6 firewall filter add chain=forward action=accept protocol=icmpv6 comment=\"IPv6 FWD: accept ICMPv6\""
    echo "/ipv6 firewall filter add chain=forward action=drop in-interface-list=!LAN comment=\"IPv6 FWD: drop not from LAN\""
    echo

    # Services
    echo "/ip service set telnet disabled=yes"
    echo "/ip service set ftp disabled=yes"
    echo "/ip service set www disabled=yes"
    echo "/ip service set www-ssl disabled=yes"
    echo "/ip service set api disabled=yes"
    echo "/ip service set api-ssl disabled=yes"
    echo "/ip service set winbox address=\"$MGMT_SUBNET\""
    echo "/ip service set ssh address=\"$MGMT_SUBNET\""
    echo

    # MAC server / discovery
    echo "/tool mac-server set allowed-interface-list=LAN"
    echo "/tool mac-server mac-winbox set allowed-interface-list=LAN"
    echo "/ip neighbor discovery-settings set discover-interface-list=LAN"
    echo

    # Logging
    echo "/system logging add topics=firewall action=memory comment=\"Firewall events (short-term memory buffer)\""
    echo

    # Final enable vlan-filtering
    echo ":delay 1s"
    echo "/interface bridge set br-lan vlan-filtering=yes"
    echo
    echo ":log info \"=== Deployment Import Finished ===\";"
} > "$TMP_RSC"

# ----------------------------
# Save output
# ----------------------------
OUTPUT_FILE="./mikrotik_deploy_${ROUTER_NAME// /_}.rsc"
cp "$TMP_RSC" "$OUTPUT_FILE"

echo
echo "Generated RouterOS config file:"
echo "  $OUTPUT_FILE"
echo

# ----------------------------
# Optional apply
# ----------------------------
if [[ "$APPLY_NOW" == "yes" ]]; then
    ssh_apply "$TARGET_IP" "$SSH_USER" "$SSH_PASS" "$TMP_RSC"
fi

echo
echo "Done."
echo "Next steps:"
echo "  1. Review the generated .rsc file"
echo "  2. Import manually with: /import file-name=$(basename "$OUTPUT_FILE")"
echo "  3. Change admin password after first login"
