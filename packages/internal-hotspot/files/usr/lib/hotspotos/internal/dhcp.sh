#!/bin/sh
# Internal Hotspot DHCP Manager
# Configures DHCP for user network

. /lib/functions.sh

LOG_FILE=/var/log/internal-hotspot.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get DHCP configuration
get_dhcp_config() {
    config_load hotspotos
    config_get GATEWAY hotspot gateway "192.168.10.1"
    config_get POOL_START hotspot pool_start "192.168.10.100"
    config_get POOL_END hotspot pool_end "192.168.10.250"
    config_get NETMASK hotspot netmask "255.255.255.0"
    config_get LEASE hotspot dhcp_lease "12h"
}

# Configure network interface
configure_network() {
    get_dhcp_config

    log_msg "Configuring network: Gateway=$GATEWAY, Pool=$POOL_START-$POOL_END"

    # Create hotspot network interface
    uci -q batch <<-EOF
        set network.hotspot=interface
        set network.hotspot.proto=static
        set network.hotspot.ipaddr=$GATEWAY
        set network.hotspot.netmask=$NETMASK
        set network.hotspot.device='wlan0'
        commit network
EOF

    # Create hotspot firewall zone
    uci -q batch <<-EOF
        set firewall.hotspot=zone
        set firewall.hotspot.name='hotspot'
        set firewall.hotspot.input='ACCEPT'
        set firewall.hotspot.output='ACCEPT'
        set firewall.hotspot.forward='REJECT'
        set firewall.hotspot.network='hotspot'
        commit firewall
EOF

    # Add forwarding from hotspot to wan
    uci -q batch <<-EOF
        set firewall.hotspot_wan=forwarding
        set firewall.hotspot_wan.src='hotspot'
        set firewall.hotspot_wan.dest='wan'
        commit firewall
EOF

    log_msg "Network interface configured"
}

# Configure DHCP server
configure_dhcp() {
    get_dhcp_config

    log_msg "Configuring DHCP: Range=$POOL_START-$POOL_END, Lease=$LEASE"

    uci -q batch <<-EOF
        set dhcp.hotspot=dhcp
        set dhcp.hotspot.interface='hotspot'
        set dhcp.hotspot.start=$(echo $POOL_START | cut -d. -f4)
        set dhcp.hotspot.limit=$(($(echo $POOL_END | cut -d. -f4) - $(echo $POOL_START | cut -d. -f4)))
        set dhcp.hotspot.leasetime='$LEASE'
        set dhcp.hotspot.dhcpv4='server'
        commit dhcp
EOF

    log_msg "DHCP server configured"
}

# Start DHCP
start_dhcp() {
    configure_network
    configure_dhcp

    /etc/init.d/network reload
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart

    log_msg "DHCP service started"
}

# Stop DHCP
stop_dhcp() {
    uci -q delete dhcp.hotspot
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    log_msg "DHCP service stopped"
}

# Show DHCP status
dhcp_status() {
    echo "DHCP Status:"
    echo "============"
    echo "Gateway: $(uci -q get hotspotos.hotspot.gateway)"
    echo "Pool: $(uci -q get hotspotos.hotspot.pool_start) - $(uci -q get hotspotos.hotspot.pool_end)"
    echo "Lease Time: $(uci -q get hotspotos.hotspot.dhcp_lease)"
    echo ""
    echo "Active Leases:"
    cat /tmp/dhcp.leases 2>/dev/null | grep "hotspot" || echo "No active leases"
}

case "$1" in
    start)
        start_dhcp
        ;;
    stop)
        stop_dhcp
        ;;
    restart)
        stop_dhcp
        start_dhcp
        ;;
    status)
        dhcp_status
        ;;
    *)
        echo "Usage: dhcp.sh {start|stop|restart|status}"
        ;;
esac
