#!/bin/bash

BLOCKED_FILE="/tmp/blocked_ips.txt"
PERM_BLOCK_FILE="/etc/permanent_block_ips.txt"

if [ -f "$BLOCKED_FILE" ]; then
    while read ip
    do
        # Skip permanent IPs
        grep -w "$ip" $PERM_BLOCK_FILE > /dev/null
        if [ $? -ne 0 ]; then
            
            echo "Unblocking IP: $ip"
            iptables -D INPUT -s $ip -j DROP
            
        else
            echo "Skipping permanent IP: $ip"
        fi

    done < $BLOCKED_FILE

    # Clear temp file
    > $BLOCKED_FILE
fi
