#!/bin/bash

# Define encryption password
ENCRYPTION_PASSWORD="#ENTER YOUR ENCRYPT PASSWORD NAME"
ENCRYPTION_PASSWORD_Moninfra="#ENTER YOUR ENCRYPT PASSWORD NAME"

# Decrypt the password
DECRYPTED_PASSWORD=$(openssl enc -aes-256-cbc -pbkdf2 -d -in password.enc -pass pass:$ENCRYPTION_PASSWORD)
DECRYPTED_PASSWORD_Moninfra=$(openssl enc -aes-256-cbc -pbkdf2 -d -in moninfra.enc -pass pass:$ENCRYPTION_PASSWORD_Moninfra)

#ENTER YOUR USERNAME
USER="#ENTER YOUR USERNAME"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m' # Reset to default color

echo "-------------------------- "
echo "-------------------------- "

echo -e "${GREEN}!!!!!  You are going to Log in to Remote Device without password. Please use this with proper Caution  !!!!!${RESET}"

read -p "---------Enter Name of Remote Address/ Host Name (e.g. amar, dnkt, etc.)-------- " HOST
echo -e "${GREEN}You entered: ${RESET}${RED}${HOST}${RESET}"

# Define mapping for the short names to the router names
declare -A ROUTERS
ROUTERS=(
  ["amar"]="jnpr-amar-01"
  ["dnkt"]="jnpr-brt-dnkt-01"
  ["attr"]="jnpr-attr-01"
  ["bktp"]="jnpr-bktp-01"
  ["grdh"]="jnpr-brt-grdh-01"
  ["grgj"]="jnpr-brt-grgj-01"
  ["rgli"]="jnpr-brt-rgli-01"
  ["rtwm"]="jnpr-brt-rtwm-01"
  ["rpur"]="jnpr-btw-rpur-01"
  ["btwl"]="jnpr-btwl-01"
  ["chau"]="jnpr-chau-01"
  ["chbl"]="jnpr-chbl-01"
  ["ctwn"]="jnpr-ctwn-01"
  ["ddli"]="jnpr-ddli-01"
  ["ddlr"]="jnpr-ddlr-01"
  ["dhap"]="jnpr-dhap-01"
  ["dhbi"]="jnpr-dhbi-01"
  ["dhti"]="jnpr-dhti-01"
  ["dhub"]="jnpr-dhub-01"
  ["dkbr"]="jnpr-dkbr-01"
  ["dmak"]="jnpr-dmak-01"
  ["dppl"]="jnpr-dml-dppl-01"
  ["rish"]="jnpr-dml-rish-01"
  ["gjri"]="jnpr-gjri-01"
  ["grda"]="jnpr-grda-01"
  ["grkh"]="jnpr-grkh-01"
  ["htda"]="jnpr-htda-01"
  ["ithr"]="jnpr-ithr-01"
  ["jawl"]="jnpr-jawl-01"
  ["klmt"]="jnpr-klmt-01"
  ["klpr"]="jnpr-klpr-01"
  ["kltr"]="jnpr-kltr-01"
  ["kolb"]="jnpr-kolb-01"
  ["lahn"]="jnpr-lahn-01"
  ["lknt"]="jnpr-lknt-01"
  ["lmhi"]="jnpr-lmhi-01"
  ["mhjg"]="jnpr-mhjg-01"
  ["mlpr"]="jnpr-mlpr-01"
  ["nbns"]="jnpr-nbns-01"
  ["ndc"]="jnpr-ndc-01"
  ["rupa"]="jnpr-pkr-rupa-01"
  ["pkra"]="jnpr-pkra-01"
  ["plwa"]="jnpr-plwa-01"
  ["prera"]="jnpr-prera-01"
  ["sbnk"]="jnpr-sbnk-01"
  ["sctr"]="jnpr-sctr-01"
  ["slvr"]="jnpr-slvr-01"
  ["stdb"]="jnpr-stdb-01"
  ["thml"]="jnpr-thml-01"
)

# Check if the short name exists in the mapping
if [[ -z "${ROUTERS[$HOST]}" ]]; then
  echo -e "${RED}Error: Host '$HOST' not recognized. Please enter a valid short name.${RESET}"
  exit 1
fi

# Assign the corresponding full router name
ROUTER=${ROUTERS[$HOST]}
echo -e "${GREEN}Full router name is: ${RESET}${RED}${ROUTER}${RESET}"

# SSH login
echo -e "${GREEN}Logging in to ${ROUTER}...${RESET}"

sshpass -v -p "$DECRYPTED_PASSWORD" ssh -o StrictHostKeyChecking=no "${ROUTER}" -l "${USER}" << EOF
  # Commands to run after login
  show chassis alarms
  show chassis location
EOF

echo -e "${GREEN}Commands executed on ${ROUTER}.${RESET}"
