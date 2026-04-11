#!/bin/bash

# Define encryption password (REMOVED - use env variable instead)
ENCRYPTION_PASSWORD="${ENCRYPTION_PASSWORD}"

# Decrypt the password (kept structure, but no real file/key)
DECRYPTED_PASSWORD=$(openssl enc -aes-256-cbc -d -pbkdf2 -in yourfile.enc -pass pass:$ENCRYPTION_PASSWORD)

USER="${SSH_USER}"
td=$(date "+%b %e")

sshpass -v -p "$DECRYPTED_PASSWORD" ssh -T ${USER}@YOUR_SERVER_IP <<-END
show bgp summary | match XXXXX
show bgp summary | match XXXXX
show interfaces aeX | match flap
show interfaces aeY | match flap
show log updown | match "${td}" | except \.
show log updown | except "\." | match "${td}" | match down | count
show log updown | except "\." | match "${td}" | match down
show interface description | match LOCATION1
show interface description | match LOCATION2
show interface description | match LOCATION3
show interface description | match aeX | except \.
show interface description | match aeY | except \.
show interface description | match SERVICE | except \.
ping X.X.X.X source X.X.X.X count 1000 rapid
ping X.X.X.X source X.X.X.X count 1000 rapid
END