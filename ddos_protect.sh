#!/bin/bash

# ==============================
# CONFIG
# ==============================
LOG_FILE="/var/log/nginx/access.log"    
THRESHOLD=20
BLOCKED_FILE="/tmp/blocked_ips.txt"
PERM_BLOCK_FILE="/etc/permanent_block_ips.txt"
TMP_IP_COUNT="/tmp/ip_count.txt"

# ==============================
# STEP 1: GET CURRENT MINUTE LOGS
# ==============================

CURRENT_MIN=$(date +"%d/%b/%Y:%H:%M")

grep "$CURRENT_MIN" $LOG_FILE | awk '{print $1}' | sort | uniq -c > $TMP_IP_COUNT

# ==============================
# STEP 2: PROCESS EACH IP
# ==============================

while read count ip
do
    if [ "$count" -gt "$THRESHOLD" ]; then
        
        # Check if already blocked
        iptables -L INPUT -n | grep "$ip" > /dev/null
        if [ $? -ne 0 ]; then
            
            echo "Blocking IP: $ip (Requests: $count)"
            
            # Block IP
            iptables -A INPUT -s $ip -j DROP
            
            # Save in temp block list
            echo $ip >> $BLOCKED_FILE
        fi
    fi

done < $TMP_IP_COUNT

# ==============================
# STEP 3: APPLY PERMANENT BLOCKS
# ==============================

if [ -f "$PERM_BLOCK_FILE" ]; then
    while read ip
    do
        iptables -L INPUT -n | grep "$ip" > /dev/null
        if [ $? -ne 0 ]; then
            echo "Applying permanent block: $ip"
            iptables -A INPUT -s $ip -j DROP
        fi
    done < $PERM_BLOCK_FILE
fi
