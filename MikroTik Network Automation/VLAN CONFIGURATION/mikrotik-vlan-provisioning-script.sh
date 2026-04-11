#!/bin/bash

# ============================================================
#  MikroTik VLAN Configuration Generator
#  Author: Based on Subash Subedi's VLAN Guide (2025)
#  Features: Bridge+VLAN, IP, DHCP, DNS, Route, NAT,
#            NTP (Nepal UTC+5:45), SSH, Graphing, Firewall
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║      MIKROTIK VLAN CONFIGURATION GENERATOR      ║"
echo "║         Based on Subash Subedi  (2025)           ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Validators ───────────────────────────────────────────────
validate_cidr() {
    echo "$1" | grep -Eq \
        '^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$' \
        && return 0 || return 1
}
validate_ip() {
    echo "$1" | grep -Eq \
        '^([0-9]{1,3}\.){3}[0-9]{1,3}$' \
        && return 0 || return 1
}
validate_vlan_id() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 4094 ))
}
validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 ))
}

# ── Derive full network info from ANY CIDR prefix ────────────
derive_network_info() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
    local ip_int=$(( (o1<<24)+(o2<<16)+(o3<<8)+o4 ))
    local mask=$(( 0xFFFFFFFF << (32-prefix) & 0xFFFFFFFF ))
    local net_int=$(( ip_int & mask ))
    local bcast_int=$(( net_int | (~mask & 0xFFFFFFFF) ))
    NET_ADDR="$(( (net_int>>24)&255 )).$(( (net_int>>16)&255 )).$(( (net_int>>8)&255 )).$(( net_int&255 ))"
    NET_CIDR="${NET_ADDR}/${prefix}"
    GW_ADDR="$ip"
    local usable=$(( bcast_int - net_int - 1 ))
    if (( usable == 2 )); then
        local peer_int
        if (( ip_int == net_int+1 )); then peer_int=$(( net_int+2 ))
        else                               peer_int=$(( net_int+1 )); fi
        SUGGESTED_GW="$(( (peer_int>>24)&255 )).$(( (peer_int>>16)&255 )).$(( (peer_int>>8)&255 )).$(( peer_int&255 ))"
    else
        local gw_int=$(( net_int+1 ))
        SUGGESTED_GW="$(( (gw_int>>24)&255 )).$(( (gw_int>>16)&255 )).$(( (gw_int>>8)&255 )).$(( gw_int&255 ))"
    fi
    local s=$(( net_int+2 )) e=$(( bcast_int-1 ))
    DHCP_START="$(( (s>>24)&255 )).$(( (s>>16)&255 )).$(( (s>>8)&255 )).$(( s&255 ))"
    DHCP_END="$(( (e>>24)&255 )).$(( (e>>16)&255 )).$(( (e>>8)&255 )).$(( e&255 ))"
}

# ── Prompt helpers ────────────────────────────────────────────
ask() {
    local prompt="$1" var="$2" default="$3"
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$(echo -e ${YELLOW})${prompt} [${default}]: $(echo -e ${NC})" input
            input="${input:-$default}"
        else
            read -p "$(echo -e ${YELLOW})${prompt}: $(echo -e ${NC})" input
        fi
        [[ -n "$input" ]] && { eval "$var='$input'"; break; }
        echo -e "${RED}  ✖ Required.${NC}"
    done
}

ask_cidr() {
    local prompt="$1" var="$2" default="$3"
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$(echo -e ${YELLOW})${prompt} [${default}]: $(echo -e ${NC})" input
            input="${input:-$default}"
        else
            read -p "$(echo -e ${YELLOW})${prompt} (e.g. 103.166.100.238/30  or  124.166.10.20/25  or  100.166.100.100/24): $(echo -e ${NC})" input
        fi
        if validate_cidr "$input"; then eval "$var='$input'"; break; fi
        echo -e "${RED}  ✖ Invalid. Use x.x.x.x/prefix  (any prefix: /30 /29 /25 /24 etc.)${NC}"
    done
}

ask_ip() {
    local prompt="$1" var="$2" default="$3"
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$(echo -e ${YELLOW})${prompt} [${default}]: $(echo -e ${NC})" input
            input="${input:-$default}"
        else
            read -p "$(echo -e ${YELLOW})${prompt}: $(echo -e ${NC})" input
        fi
        if validate_ip "$input"; then eval "$var='$input'"; break; fi
        echo -e "${RED}  ✖ Invalid IP address.${NC}"
    done
}

ask_vlan_id() {
    local prompt="$1" var="$2" default="$3"
    while true; do
        ask "$prompt (1-4094)" "$var" "$default"
        validate_vlan_id "${!var}" && break
        echo -e "${RED}  ✖ VLAN ID must be 1–4094.${NC}"
    done
}

ask_yn() {
    local prompt="$1" var="$2" default="${3:-y}"
    local label="Y/n"; [[ "$default" == "n" ]] && label="y/N"
    read -p "$(echo -e ${YELLOW})${prompt} [${label}]: $(echo -e ${NC})" input
    input="${input:-$default}"
    [[ "$input" =~ ^[Yy] ]] && eval "$var='y'" || eval "$var='n'"
}

ask_port() {
    local prompt="$1" var="$2" default="$3"
    while true; do
        ask "$prompt" "$var" "$default"
        validate_port "${!var}" && break
        echo -e "${RED}  ✖ Port must be 1–65535.${NC}"
    done
}

# ══════════════════════════════════════════════════════════════
#  SECTION 1 — Identity
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}── Router Identity ──────────────────────────────────${NC}"
ask "Router identity/hostname" ROUTER_NAME "MikroTik-Nepal"

# ══════════════════════════════════════════════════════════════
#  SECTION 2 — Bridge & WAN
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── Bridge & WAN ─────────────────────────────────────${NC}"
ask "Bridge name" BRIDGE "bridge1"
ask "WAN interface (uplink to ISP)" WAN "ether1"
echo ""
echo -e "  ${YELLOW}WAN IP accepts any prefix: /30, /29, /28, /25, /24 …${NC}"
ask_cidr "Public/WAN IP (as given by your ISP)" PUBLIC_IP ""
derive_network_info "$PUBLIC_IP"
WAN_NET_CIDR="$NET_CIDR"
echo -e "  ${GREEN}→ WAN subnet detected  : $WAN_NET_CIDR${NC}"
echo -e "  ${GREEN}→ Suggested ISP gateway: $SUGGESTED_GW${NC}"
ask_ip "ISP Gateway (default route)" ISP_GW "$SUGGESTED_GW"

# ── DNS ──────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}── DNS ──────────────────────────────────────────────${NC}"
ask "Primary DNS"   DNS1 "8.8.8.8"
ask "Secondary DNS" DNS2 "8.8.4.4"

# ══════════════════════════════════════════════════════════════
#  SECTION 3 — VLAN definitions
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── VLAN Definitions ─────────────────────────────────${NC}"
ask "How many VLANs to configure?" NUM_VLANS "4"

declare -a VLAN_NAMES VLAN_IDS VLAN_IPS VLAN_PORTS
declare -a VLAN_NET_CIDRS VLAN_GWS VLAN_STARTS VLAN_ENDS

for (( i=0; i<NUM_VLANS; i++ )); do
    n=$(( i+1 ))
    echo ""
    echo -e "${BOLD}  ── VLAN $n ──────────────────────────────────────${NC}"
    ask         "  Name (e.g. vlan${n} or Management)"  VLAN_NAMES[$i]  "vlan${n}"
    ask_vlan_id "  VLAN ID"                              VLAN_IDS[$i]    "$n"
    ask_cidr    "  Gateway IP for this VLAN"             VLAN_IPS[$i]    "192.168.${n}.1/24"
    ask         "  Physical port (untagged access)"      VLAN_PORTS[$i]  "ether$(( n+1 ))"
    derive_network_info "${VLAN_IPS[$i]}"
    VLAN_NET_CIDRS[$i]="$NET_CIDR"
    VLAN_GWS[$i]="$GW_ADDR"
    VLAN_STARTS[$i]="$DHCP_START"
    VLAN_ENDS[$i]="$DHCP_END"
done

# ══════════════════════════════════════════════════════════════
#  SECTION 4 — Inter-VLAN traffic policy
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── Inter-VLAN Traffic Policy ────────────────────────${NC}"
echo -e "  ${YELLOW}1${NC}) Allow all inter-VLAN traffic"
echo -e "  ${YELLOW}2${NC}) Block ALL inter-VLAN traffic (full isolation)"
echo -e "  ${YELLOW}3${NC}) Custom — choose per pair"
ask "Select policy" VLAN_POLICY "2"

declare -A BLOCK_PAIR
if [[ "$VLAN_POLICY" == "2" ]]; then
    for (( i=0; i<NUM_VLANS; i++ )); do
        for (( j=0; j<NUM_VLANS; j++ )); do
            [[ $i -ne $j ]] && BLOCK_PAIR[$i,$j]=1
        done
    done
elif [[ "$VLAN_POLICY" == "3" ]]; then
    echo ""
    for (( i=0; i<NUM_VLANS; i++ )); do
        for (( j=0; j<NUM_VLANS; j++ )); do
            [[ $i -ge $j ]] && continue
            read -p "$(echo -e ${YELLOW})  Block ${VLAN_NAMES[$i]} ↔ ${VLAN_NAMES[$j]}? [y/N]: $(echo -e ${NC})" ans
            if [[ "$ans" =~ ^[Yy] ]]; then
                BLOCK_PAIR[$i,$j]=1; BLOCK_PAIR[$j,$i]=1
            fi
        done
    done
fi

# ══════════════════════════════════════════════════════════════
#  SECTION 5 — NTP  (Nepal Standard Time UTC+5:45)
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── NTP Configuration (Nepal Time UTC+5:45) ──────────${NC}"
echo -e "  ${YELLOW}Nepal uses UTC+5:45 — timezone will be set to: Asia/Kathmandu${NC}"
echo -e "  ${YELLOW}Recommended NTP servers:${NC}"
echo -e "    ${GREEN}1)${NC} 0.asia.pool.ntp.org  +  1.asia.pool.ntp.org  (Asia NTP pool)"
echo -e "    ${GREEN}2)${NC} time.google.com       +  time.cloudflare.com  (Global)"
echo -e "    ${GREEN}3)${NC} Custom — enter your own"
ask "Select NTP option" NTP_CHOICE "1"
case "$NTP_CHOICE" in
    2) NTP1="time.google.com";    NTP2="time.cloudflare.com" ;;
    3) ask "Primary NTP"   NTP1 "0.asia.pool.ntp.org"
       ask "Secondary NTP" NTP2 "1.asia.pool.ntp.org" ;;
    *) NTP1="0.asia.pool.ntp.org"; NTP2="1.asia.pool.ntp.org" ;;
esac
echo -e "  ${GREEN}→ NTP: $NTP1  $NTP2${NC}"
echo -e "  ${GREEN}→ Timezone: Asia/Kathmandu (UTC+5:45)${NC}"

# ══════════════════════════════════════════════════════════════
#  SECTION 6 — SSH
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── SSH Configuration ────────────────────────────────${NC}"
ask_yn "Enable SSH access?" ENABLE_SSH "y"
if [[ "$ENABLE_SSH" == "y" ]]; then
    ask_port "SSH port (22=standard, non-standard reduces attacks)" SSH_PORT "22"
    ask_yn "Restrict SSH to LAN/VLAN only? (blocks WAN SSH — recommended)" SSH_LAN_ONLY "y"

    # Build comma-separated list of all VLAN networks for SSH allow
    SSH_ALLOW_NETS=""
    if [[ "$SSH_LAN_ONLY" == "y" ]]; then
        for (( i=0; i<NUM_VLANS; i++ )); do
            [[ -n "$SSH_ALLOW_NETS" ]] && SSH_ALLOW_NETS+=","
            SSH_ALLOW_NETS+="${VLAN_NET_CIDRS[$i]}"
        done
    fi
fi

# ══════════════════════════════════════════════════════════════
#  SECTION 7 — Graphing
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── Graphing / Traffic Monitor ───────────────────────${NC}"
echo -e "  ${YELLOW}Graphs viewable in Winbox and at http://<router-ip>/graphs/${NC}"
ask_yn "Enable interface graphing?" ENABLE_GRAPH "y"
if [[ "$ENABLE_GRAPH" == "y" ]]; then
    ask_yn "  Graph WAN interface ($WAN)?"           GRAPH_WAN      "y"
    ask_yn "  Graph each VLAN interface?"            GRAPH_VLANS    "y"
    ask_yn "Enable resource graphing (CPU/Mem/Disk)?" ENABLE_RES_GRAPH "y"
    echo -e "  ${YELLOW}Allow graphs from which IP? (0.0.0.0/0 = anyone on LAN)${NC}"
    ask "  Allow graph access from" GRAPH_ALLOW "0.0.0.0/0"
fi

# ══════════════════════════════════════════════════════════════
#  SUMMARY
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗"
echo -e "║               CONFIGURATION SUMMARY             ║"
echo -e "╚══════════════════════════════════════════════════╝${NC}"
echo -e "  Router      : ${GREEN}$ROUTER_NAME${NC}"
echo -e "  Bridge      : ${GREEN}$BRIDGE${NC}   WAN: ${GREEN}$WAN${NC}"
echo -e "  Public IP   : ${GREEN}$PUBLIC_IP${NC}  Subnet: ${GREEN}$WAN_NET_CIDR${NC}  GW: ${GREEN}$ISP_GW${NC}"
echo -e "  DNS         : ${GREEN}$DNS1, $DNS2${NC}"
echo -e "  NTP         : ${GREEN}$NTP1, $NTP2${NC}  TZ: ${GREEN}Asia/Kathmandu (UTC+5:45)${NC}"
if [[ "$ENABLE_SSH" == "y" ]]; then
    lan_flag=""; [[ "$SSH_LAN_ONLY" == "y" ]] && lan_flag=" (LAN/VLAN only)"
    echo -e "  SSH         : ${GREEN}enabled port=$SSH_PORT${lan_flag}${NC}"
else
    echo -e "  SSH         : ${RED}disabled${NC}"
fi
[[ "$ENABLE_GRAPH" == "y" ]] \
    && echo -e "  Graphing    : ${GREEN}enabled  allow=$GRAPH_ALLOW${NC}" \
    || echo -e "  Graphing    : ${RED}disabled${NC}"
echo ""
printf "  %-14s %-6s %-8s %-20s %s\n" "VLAN" "ID" "Port" "Gateway" "Network / DHCP range"
printf "  %-14s %-6s %-8s %-20s %s\n" "────" "──" "────" "───────" "────────────────────"
for (( i=0; i<NUM_VLANS; i++ )); do
    printf "  ${GREEN}%-14s${NC} %-6s %-8s %-20s %s  (%s - %s)\n" \
        "${VLAN_NAMES[$i]}" "${VLAN_IDS[$i]}" "${VLAN_PORTS[$i]}" \
        "${VLAN_GWS[$i]}" "${VLAN_NET_CIDRS[$i]}" "${VLAN_STARTS[$i]}" "${VLAN_ENDS[$i]}"
done
echo ""
read -p "$(echo -e ${YELLOW})Generate config? [Y/n]: $(echo -e ${NC})" confirm
confirm="${confirm:-Y}"
[[ "$confirm" =~ ^[Nn] ]] && echo "Aborted." && exit 0

# ══════════════════════════════════════════════════════════════
#  WRITE .RSC FILE
# ══════════════════════════════════════════════════════════════
OUTFILE="mikrotik_vlan_${BRIDGE}_$(date +%Y%m%d_%H%M%S).rsc"

{
cat << EOF
# ============================================================
#  MikroTik VLAN Configuration Script
#  Generated : $(date)
#  Router    : $ROUTER_NAME
#  WAN       : $WAN  IP=$PUBLIC_IP  Subnet=$WAN_NET_CIDR  GW=$ISP_GW
#  VLANs     : $NUM_VLANS
# ============================================================

# ── 0. Router Identity ───────────────────────────────────────
/system identity set name="$ROUTER_NAME"

# ── 1. Bridge (VLAN filtering enabled) ──────────────────────
/interface bridge add name=$BRIDGE vlan-filtering=yes

/interface bridge port
EOF

for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add bridge=$BRIDGE interface=${VLAN_PORTS[$i]}"
done

cat << EOF

# ── 2. VLAN Interfaces ──────────────────────────────────────
/interface vlan
EOF
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add interface=$BRIDGE name=${VLAN_NAMES[$i]} vlan-id=${VLAN_IDS[$i]}"
done

cat << EOF

# ── 3. IP Addresses ─────────────────────────────────────────
/ip address
add address=$PUBLIC_IP interface=$WAN
EOF
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add address=${VLAN_IPS[$i]} interface=${VLAN_NAMES[$i]}"
done

cat << EOF

# ── 4. Bridge VLAN Filtering ────────────────────────────────
/interface bridge vlan
EOF
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add bridge=$BRIDGE vlan-ids=${VLAN_IDS[$i]} tagged=$BRIDGE untagged=${VLAN_PORTS[$i]}"
done

cat << EOF

# ── 5. Port PVIDs ───────────────────────────────────────────
/interface bridge port
EOF
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "set [find interface=${VLAN_PORTS[$i]}] pvid=${VLAN_IDS[$i]}"
done

cat << EOF

# ── 6. DHCP Pools ───────────────────────────────────────────
/ip pool
EOF
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add name=pool_${VLAN_NAMES[$i]} ranges=${VLAN_STARTS[$i]}-${VLAN_ENDS[$i]}"
done

echo ""
echo "/ip dhcp-server"
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add interface=${VLAN_NAMES[$i]} address-pool=pool_${VLAN_NAMES[$i]} name=dhcp_${VLAN_NAMES[$i]} disabled=no"
done

echo ""
echo "/ip dhcp-server network"
for (( i=0; i<NUM_VLANS; i++ )); do
    echo "add address=${VLAN_NET_CIDRS[$i]} gateway=${VLAN_GWS[$i]} dns-server=$DNS1,$DNS2"
done

cat << EOF

# ── 7. DNS ──────────────────────────────────────────────────
/ip dns set servers=$DNS1,$DNS2 allow-remote-requests=yes

# ── 8. Default Route ────────────────────────────────────────
/ip route add dst-address=0.0.0.0/0 gateway=$ISP_GW

# ── 9. NAT (Masquerade) ─────────────────────────────────────
/ip firewall nat
add chain=srcnat out-interface=$WAN action=masquerade

# ── 10. Base Firewall (allow internet, block raw cross-VLAN) ─
/ip firewall filter
add chain=forward in-interface=!$WAN out-interface=!$WAN action=drop comment="Block non-WAN to non-WAN (base)"

EOF

# Inter-VLAN block rules
HAS_BLOCKS=0
for key in "${!BLOCK_PAIR[@]}"; do [[ "${BLOCK_PAIR[$key]}" == "1" ]] && HAS_BLOCKS=1 && break; done
if [[ $HAS_BLOCKS -eq 1 ]]; then
cat << EOF
# ── 10b. Inter-VLAN Blocking Rules ──────────────────────────
/ip firewall filter
EOF
    for (( i=0; i<NUM_VLANS; i++ )); do
        for (( j=0; j<NUM_VLANS; j++ )); do
            [[ $i -eq $j ]] && continue
            if [[ "${BLOCK_PAIR[$i,$j]}" == "1" ]]; then
                echo "add chain=forward in-interface=${VLAN_NAMES[$i]} out-interface=${VLAN_NAMES[$j]} action=drop comment=\"Drop ${VLAN_NAMES[$i]} -> ${VLAN_NAMES[$j]}\""
            fi
        done
    done
fi

# NTP
cat << EOF

# ── 11. NTP Client — Nepal Standard Time (UTC+5:45) ─────────
# Asia/Kathmandu = UTC+5:45  (Nepal does NOT observe DST)
/system clock set time-zone-name=Asia/Kathmandu
/ip cloud set update-time=no
/system ntp client set enabled=yes
/system ntp client servers
add address=$NTP1
add address=$NTP2
/system ntp client print
# Verify after a few seconds:  /system clock print
EOF

# SSH
if [[ "$ENABLE_SSH" == "y" ]]; then
cat << EOF

# ── 12. SSH ─────────────────────────────────────────────────
/ip service enable ssh
/ip service set ssh port=$SSH_PORT
EOF
    if [[ "$SSH_LAN_ONLY" == "y" && -n "$SSH_ALLOW_NETS" ]]; then
        echo "/ip service set ssh address=$SSH_ALLOW_NETS"
        echo "# SSH restricted to VLAN networks: $SSH_ALLOW_NETS"
    else
        echo "# SSH open on all interfaces — consider restricting address= later"
    fi
    echo "/ip service print"
else
cat << EOF

# ── 12. SSH ─────────────────────────────────────────────────
/ip service disable ssh
EOF
fi

# Graphing
if [[ "$ENABLE_GRAPH" == "y" ]]; then
cat << EOF

# ── 13. Graphing (Traffic & Resource Monitoring) ────────────
# Access: http://<any-vlan-gateway-ip>/graphs/  in browser
#         Winbox → Tools → Graphing
/tool graphing set store-every=5min
EOF
    [[ "$GRAPH_WAN" == "y" ]] && \
        echo "/tool graphing interface add interface=$WAN allow-address=$GRAPH_ALLOW"
    if [[ "$GRAPH_VLANS" == "y" ]]; then
        for (( i=0; i<NUM_VLANS; i++ )); do
            echo "/tool graphing interface add interface=${VLAN_NAMES[$i]} allow-address=$GRAPH_ALLOW"
        done
    fi
    [[ "$ENABLE_RES_GRAPH" == "y" ]] && \
        echo "/tool graphing resource add allow-address=$GRAPH_ALLOW"
    cat << EOF
/tool graphing print
# View at: http://${VLAN_GWS[0]}/graphs/
EOF
fi

cat << EOF

# ── Done ────────────────────────────────────────────────────
# Import via: Winbox → New Terminal → /import file=$(basename $OUTFILE)
#
# Post-import verify:
#   /system clock print              ← confirm Nepal time (UTC+5:45)
#   /system ntp client print         ← confirm NTP sync
#   /ip service print                ← confirm SSH port $SSH_PORT
#   http://${VLAN_GWS[0]}/graphs/    ← traffic graphs
EOF

} > "$OUTFILE"

echo ""
echo -e "${GREEN}✔ Saved to: ${OUTFILE}${NC}"
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
cat "$OUTFILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Import via Winbox → New Terminal → /import file=${OUTFILE}${NC}"
echo -e "${GREEN}Then browse to http://${VLAN_GWS[0]}/graphs/ for traffic graphs.${NC}"