#!/bin/bash
#
# Rollback script for undoing torrent traffic block
# Removes iptables rules, cleans /etc/hosts, and deletes the cron job
# Author: sam nikzad (rollback version)

echo "Starting rollback of torrent traffic block..."

# STEP 1: Remove iptables rules
if [ -f /etc/trackers ]; then
    echo "Removing iptables rules..."
    IFS=$'\n'
    TRACKERS=$(sort /etc/trackers | uniq)
    for ip in $TRACKERS; do
        iptables -D INPUT -d $ip -j DROP 2>/dev/null
        iptables -D FORWARD -d $ip -j DROP 2>/dev/null
        iptables -D OUTPUT -d $ip -j DROP 2>/dev/null
    done
    echo "iptables rules removed."
else
    echo "No /etc/trackers file found. Skipping iptables cleanup."
fi

# STEP 2: Clean /etc/hosts
echo "Cleaning /etc/hosts from tracker entries..."
cp /etc/hosts /etc/hosts.backup.$(date +%F_%H-%M-%S)
sed -i '/127\.0\.0\.1.*tracker\|0\.0\.0\.0.*tracker/d' /etc/hosts
echo "/etc/hosts cleaned."

# STEP 3: Remove cron job
if [ -f /etc/cron.daily/denypublic ]; then
    echo "Removing cron job..."
    rm -f /etc/cron.daily/denypublic
    echo "Cron job removed."
else
    echo "No cron job found at /etc/cron.daily/denypublic."
fi

# STEP 4: Optional - Clean up /etc/trackers file
echo "Removing /etc/trackers file..."
rm -f /etc/trackers

echo "Rollback completed successfully."
