#!/bin/sh
# Internal Hotspot NAT Manager
# Configures NAT for user network

. /lib/functions.sh

LOG_FILE=/var/log/internal-hotspot.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Configure NAT rules
configure_nat() {
    log_msg "Configuring NAT for hotspot network"

    # Enable NAT masquerading via nftables
    nft add table inet hotspotos_nat 2>/dev/null
    nft add chain inet hotspotos_nat postrouting { type nat hook postrouting priority 100 \; } 2>/dev/null
    nft add rule inet hotspotos_nat postrouting oif "eth0" masquerade 2>/dev/null

    log_msg "NAT rules applied"
}

# Remove NAT rules
remove_nat() {
    log_msg "Removing NAT rules"
    nft delete table inet hotspotos_nat 2>/dev/null
}

# Configure firewall rules
configure_firewall() {
    log_msg "Configuring firewall for hotspot"

    # Allow DNS
    nft add rule inet fw4 input iif "wlan0" udp dport 53 accept 2>/dev/null
    nft add rule inet fw4 input iif "wlan0" tcp dport 53 accept 2>/dev/null

    # Allow DHCP
    nft add rule inet fw4 input iif "wlan0" udp dport 67 accept 2>/dev/null

    # Allow HTTP/HTTPS for captive portal
    nft add rule inet fw4 input iif "wlan0" tcp dport 80 accept 2>/dev/null
    nft add rule inet fw4 input iif "wlan0" tcp dport 443 accept 2>/dev/null
    nft add rule inet fw4 input iif "wlan0" tcp dport 8080 accept 2>/dev/null

    log_msg "Firewall rules applied"
}

# Start NAT
start_nat() {
    configure_nat
    configure_firewall
    log_msg "NAT started"
}

# Stop NAT
stop_nat() {
    remove_nat
    log_msg "NAT stopped"
}

case "$1" in
    start)
        start_nat
        ;;
    stop)
        stop_nat
        ;;
    restart)
        stop_nat
        start_nat
        ;;
    *)
        echo "Usage: nat.sh {start|stop|restart}"
        ;;
esac
