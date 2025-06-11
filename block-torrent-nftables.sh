#!/bin/bash

# Credit to original author: sam
# Converted to nftables by: <your_name>
# GitHub: https://github.com/nikzad-avasam/block-torrent-on-server

echo "Blocking all torrent traffic using nftables. Please wait..."

# Download tracker domains list
wget -q -O /etc/trackers https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/domains

# Create nftables table and set if not already present
nft list tables | grep -q '^table inet torrentblock$' || nft add table inet torrentblock
nft list chains inet torrentblock | grep -q '^chain trackerblock$' || nft add chain inet torrentblock trackerblock { type filter hook output priority 0 \; }

# Clean old rules
nft flush chain inet torrentblock trackerblock

# Add new blocking rules
while read -r domain; do
    ip=$(getent ahosts "$domain" | awk '{print $1}' | head -n 1)
    if [[ -n "$ip" ]]; then
        nft add rule inet torrentblock trackerblock ip daddr "$ip" drop
    fi
done < <(sort -u /etc/trackers)

# Setup daily cron job to refresh tracker IPs
cat >/etc/cron.daily/nft-torrent-block<<'EOF'
#!/bin/bash
wget -q -O /etc/trackers https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/domains
nft flush chain inet torrentblock trackerblock
while read -r domain; do
    ip=$(getent ahosts "$domain" | awk '{print $1}' | head -n 1)
    if [[ -n "$ip" ]]; then
        nft add rule inet torrentblock trackerblock ip daddr "$ip" drop
    fi
done < <(sort -u /etc/trackers)
EOF

chmod +x /etc/cron.daily/nft-torrent-block

# Optional: Update /etc/hosts to block domains at resolution level
curl -s -LO https://raw.githubusercontent.com/nikzad-avasam/block-torrent-on-server/main/Thosts
cat Thosts >> /etc/hosts
sort -uf /etc/hosts > /etc/hosts.uniq && mv /etc/hosts{.uniq,}

echo "✅ Torrent traffic blocking via nftables is now active."
