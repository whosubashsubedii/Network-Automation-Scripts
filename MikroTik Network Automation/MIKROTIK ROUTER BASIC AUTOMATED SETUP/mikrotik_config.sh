#!/bin/bash

# ============================================================
#  MikroTik Basic Configuration Generator
#  Author: Based on Subash Subedi's MikroTik Guide (2025)
#  Features: Bridge, IP, DNS, DHCP, Route, NAT,
#            NTP (Nepal UTC+5:45), SSH, Graphing
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║     MIKROTIK BASIC CONFIGURATION GENERATOR      ║"
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

ask_yn() {
    # ask_yn "Question" VAR "y"   →  stores "y" or "n"
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
#  SECTION 2 — Bridge
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── Bridge Configuration ─────────────────────────────${NC}"
ask "Bridge name" BRIDGE "bridge1"
ask "Number of LAN ports to add (ether2 onward)" NUM_PORTS "7"

LAN_PORTS=()
for (( i=1; i<=NUM_PORTS; i++ )); do
    ask "  LAN port $i" port "ether$(( i+1 ))"
    LAN_PORTS+=("$port")
done

# ══════════════════════════════════════════════════════════════
#  SECTION 3 — WAN / IP
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── WAN & IP Configuration ───────────────────────────${NC}"
echo -e "  ${YELLOW}WAN IP accepts any prefix: /30, /29, /28, /25, /24 …${NC}"
ask "WAN interface (ISP uplink)" WAN "ether1"
ask_cidr "Public/WAN IP (as given by your ISP)" PUBLIC_IP ""
derive_network_info "$PUBLIC_IP"
WAN_NET_CIDR="$NET_CIDR"
echo -e "  ${GREEN}→ WAN subnet detected  : $WAN_NET_CIDR${NC}"
echo -e "  ${GREEN}→ Suggested ISP gateway: $SUGGESTED_GW${NC}"
ask_ip "ISP Gateway (default route)" GW "$SUGGESTED_GW"
echo ""
ask_cidr "Local/LAN IP (this router's LAN gateway)" LOCAL_IP "192.168.1.1/24"

# ══════════════════════════════════════════════════════════════
#  SECTION 4 — DNS
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── DNS Configuration ────────────────────────────────${NC}"
ask "Primary DNS"   DNS1 "8.8.8.8"
ask "Secondary DNS" DNS2 "8.8.4.4"

# ══════════════════════════════════════════════════════════════
#  SECTION 5 — DHCP
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── DHCP Names ───────────────────────────────────────${NC}"
ask "DHCP pool name"   DHCP_POOL   "dhcp_pool"
ask "DHCP server name" DHCP_SERVER "dhcp1"

derive_network_info "$LOCAL_IP"
LAN_NET_CIDR="$NET_CIDR"
LAN_GW="$GW_ADDR"
LAN_DHCP_START="$DHCP_START"
LAN_DHCP_END="$DHCP_END"

# ══════════════════════════════════════════════════════════════
#  SECTION 6 — NTP  (Nepal Standard Time UTC+5:45)
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── NTP Configuration (Nepal Time UTC+5:45) ──────────${NC}"
echo -e "  ${YELLOW}Nepal uses UTC+5:45 — timezone set to: Asia/Kathmandu${NC}"
echo -e "  ${YELLOW}Recommended NTP servers for Nepal:${NC}"
echo -e "    ${GREEN}1)${NC} 0.asia.pool.ntp.org  +  1.asia.pool.ntp.org  (Asia NTP pool)"
echo -e "    ${GREEN}2)${NC} time.google.com       +  time.cloudflare.com  (Global)"
echo -e "    ${GREEN}3)${NC} Custom — enter your own"
ask "Select NTP option" NTP_CHOICE "1"

case "$NTP_CHOICE" in
    2)
        NTP1="time.google.com"
        NTP2="time.cloudflare.com"
        ;;
    3)
        ask "Primary NTP server"   NTP1 "0.asia.pool.ntp.org"
        ask "Secondary NTP server" NTP2 "1.asia.pool.ntp.org"
        ;;
    *)
        NTP1="0.asia.pool.ntp.org"
        NTP2="1.asia.pool.ntp.org"
        ;;
esac
echo -e "  ${GREEN}→ NTP: $NTP1  $NTP2${NC}"
echo -e "  ${GREEN}→ Timezone: Asia/Kathmandu (UTC+5:45)${NC}"

# ══════════════════════════════════════════════════════════════
#  SECTION 7 — SSH
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── SSH Configuration ────────────────────────────────${NC}"
ask_yn "Enable SSH access?" ENABLE_SSH "y"
if [[ "$ENABLE_SSH" == "y" ]]; then
    ask_port "SSH port (22=standard, use non-standard to reduce attacks)" SSH_PORT "22"
    echo -e "  ${YELLOW}Tip: Changing from port 22 reduces brute-force attempts.${NC}"
    ask_yn "Restrict SSH to LAN only? (recommended — blocks WAN SSH)" SSH_LAN_ONLY "y"
fi

# ══════════════════════════════════════════════════════════════
#  SECTION 8 — Graphing
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}── Graphing / Traffic Monitor ───────────────────────${NC}"
echo -e "  ${YELLOW}MikroTik graphing shows real-time traffic graphs in Winbox${NC}"
echo -e "  ${YELLOW}and at http://<router-ip>/graphs/ in a browser.${NC}"
ask_yn "Enable interface graphing?" ENABLE_GRAPH "y"
if [[ "$ENABLE_GRAPH" == "y" ]]; then
    ask_yn "  Graph WAN interface ($WAN)?"    GRAPH_WAN   "y"
    ask_yn "  Graph LAN bridge ($BRIDGE)?"   GRAPH_LAN   "y"
    ask_yn "Enable resource graphing (CPU/Memory/Disk)?" ENABLE_RES_GRAPH "y"
    echo -e "  ${YELLOW}Allow graphs from which IP? (0.0.0.0/0 = anyone, or restrict to LAN)${NC}"
    ask "  Allow graph access from" GRAPH_ALLOW "0.0.0.0/0"
fi

# ══════════════════════════════════════════════════════════════
#  SUMMARY
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗"
echo -e "║               CONFIGURATION SUMMARY             ║"
echo -e "╚══════════════════════════════════════════════════╝${NC}"
echo -e "  Router name   : ${GREEN}$ROUTER_NAME${NC}"
echo -e "  Bridge        : ${GREEN}$BRIDGE${NC}   LAN ports: ${GREEN}${LAN_PORTS[*]}${NC}"
echo -e "  WAN           : ${GREEN}$WAN${NC}  IP: ${GREEN}$PUBLIC_IP${NC}  Subnet: ${GREEN}$WAN_NET_CIDR${NC}"
echo -e "  ISP Gateway   : ${GREEN}$GW${NC}"
echo -e "  Local IP      : ${GREEN}$LOCAL_IP${NC}  Network: ${GREEN}$LAN_NET_CIDR${NC}"
echo -e "  DHCP range    : ${GREEN}$LAN_DHCP_START - $LAN_DHCP_END${NC}"
echo -e "  DNS           : ${GREEN}$DNS1, $DNS2${NC}"
echo -e "  NTP           : ${GREEN}$NTP1, $NTP2${NC}  TZ: ${GREEN}Asia/Kathmandu (UTC+5:45)${NC}"
if [[ "$ENABLE_SSH" == "y" ]]; then
    local_flag=""; [[ "$SSH_LAN_ONLY" == "y" ]] && local_flag=" (LAN only)"
    echo -e "  SSH           : ${GREEN}enabled  port=$SSH_PORT${local_flag}${NC}"
else
    echo -e "  SSH           : ${RED}disabled${NC}"
fi
if [[ "$ENABLE_GRAPH" == "y" ]]; then
    echo -e "  Graphing      : ${GREEN}enabled  allow=$GRAPH_ALLOW${NC}"
else
    echo -e "  Graphing      : ${RED}disabled${NC}"
fi
echo ""
read -p "$(echo -e ${YELLOW})Looks good? Generate config? [Y/n]: $(echo -e ${NC})" confirm
confirm="${confirm:-Y}"
[[ "$confirm" =~ ^[Nn] ]] && echo "Aborted." && exit 0

# ══════════════════════════════════════════════════════════════
#  WRITE .RSC FILE
# ══════════════════════════════════════════════════════════════
OUTFILE="mikrotik_basic_$(date +%Y%m%d_%H%M%S).rsc"

{
cat << EOF
# ============================================================
#  MikroTik Basic Configuration Script
#  Generated : $(date)
#  Router    : $ROUTER_NAME
#  WAN       : $WAN  IP=$PUBLIC_IP  Subnet=$WAN_NET_CIDR  GW=$GW
#  LAN       : $BRIDGE  IP=$LOCAL_IP  Network=$LAN_NET_CIDR
# ============================================================

# ── 0. Router Identity ───────────────────────────────────────
/system identity set name="$ROUTER_NAME"

# ── 1. Bridge ────────────────────────────────────────────────
/interface bridge add name=$BRIDGE

EOF

for port in "${LAN_PORTS[@]}"; do
    echo "/interface bridge port add bridge=$BRIDGE interface=$port"
done

cat << EOF
/interface bridge port print brief

# ── 2. IP Addresses ──────────────────────────────────────────
/ip address add address=$PUBLIC_IP interface=$WAN
/ip address add address=$LOCAL_IP  interface=$BRIDGE
/ip address print

# ── 3. DNS ───────────────────────────────────────────────────
/ip dns set servers=$DNS1,$DNS2 allow-remote-requests=yes
/ip dns print

# ── 4. DHCP Pool & Server (LAN only) ─────────────────────────
/ip pool add name=$DHCP_POOL ranges=$LAN_DHCP_START-$LAN_DHCP_END
/ip dhcp-server add name=$DHCP_SERVER interface=$BRIDGE address-pool=$DHCP_POOL disabled=no
/ip dhcp-server network add address=$LAN_NET_CIDR gateway=$LAN_GW dns-server=$DNS1,$DNS2
/ip dhcp-server enable $DHCP_SERVER
/ip dhcp-server print

# ── 5. Default Route ─────────────────────────────────────────
/ip route add dst-address=0.0.0.0/0 gateway=$GW
/ip route print

# ── 6. NAT (Masquerade) ──────────────────────────────────────
/ip firewall nat add chain=srcnat action=masquerade
/ip firewall nat print

# ── 7. NTP Client — Nepal Standard Time (UTC+5:45) ───────────
# Asia/Kathmandu = UTC+5:45 (no DST)
/system clock set time-zone-name=Asia/Kathmandu
/ip cloud set update-time=no
/system ntp client set enabled=yes
/system ntp client servers
add address=$NTP1
add address=$NTP2
/system ntp client print
# Verify time sync (run after a few seconds):
# /system clock print

EOF

# ── 8. SSH ───────────────────────────────────────────────────
if [[ "$ENABLE_SSH" == "y" ]]; then
cat << EOF
# ── 8. SSH ───────────────────────────────────────────────────
/ip service enable ssh
/ip service set ssh port=$SSH_PORT
EOF
    if [[ "$SSH_LAN_ONLY" == "y" ]]; then
        # Restrict SSH to LAN subnet only
        cat << EOF
/ip service set ssh address=$LAN_NET_CIDR
# SSH is restricted to LAN ($LAN_NET_CIDR) only — WAN access blocked
EOF
    else
        echo "# SSH is open on all interfaces — consider restricting later"
    fi
    cat << EOF
/ip service print
EOF
else
cat << EOF
# ── 8. SSH ───────────────────────────────────────────────────
/ip service disable ssh
EOF
fi

# ── 9. Graphing ──────────────────────────────────────────────
if [[ "$ENABLE_GRAPH" == "y" ]]; then
cat << EOF

# ── 9. Graphing (Traffic & Resource Monitoring) ──────────────
# Access graphs at: http://$LAN_GW/graphs/  in your browser
# or via Winbox → Tools → Graphing
/tool graphing set store-every=5min
EOF
    if [[ "$GRAPH_WAN" == "y" ]]; then
        echo "/tool graphing interface add interface=$WAN allow-address=$GRAPH_ALLOW"
    fi
    if [[ "$GRAPH_LAN" == "y" ]]; then
        echo "/tool graphing interface add interface=$BRIDGE allow-address=$GRAPH_ALLOW"
    fi
    if [[ "$ENABLE_RES_GRAPH" == "y" ]]; then
        echo "/tool graphing resource add allow-address=$GRAPH_ALLOW"
    fi
    cat << EOF
/tool graphing print
# View at: http://$LAN_GW/graphs/
EOF
fi

cat << EOF

# ── Done ─────────────────────────────────────────────────────
# Paste into MikroTik terminal or load via:
# Winbox → New Terminal → /import file=$(basename $OUTFILE)
#
# After import, verify:
#   /system clock print          ← confirm Nepal time
#   /system ntp client print     ← confirm NTP sync
#   /ip service print            ← confirm SSH port
#   http://$LAN_GW/graphs/       ← view traffic graphs
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
echo -e "${GREEN}Then browse to http://${LAN_GW}/graphs/ for traffic graphs.${NC}"