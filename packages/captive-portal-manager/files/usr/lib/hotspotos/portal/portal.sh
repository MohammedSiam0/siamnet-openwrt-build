#!/bin/sh
# Captive Portal Manager
# Manages CoovaChilli and portal configuration

. /lib/functions.sh

LOG_FILE=/var/log/captive-portal.log
CHILLI_CONF=/etc/chilli.conf

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get portal configuration
get_portal_config() {
    config_load hotspotos
    config_get PORTAL_ENABLED portal enabled "0"
    config_get PORTAL_NAME portal name "KolakTek Hotspot"
    config_get PORTAL_LOGO portal logo "/www/hotspotos/logo.png"
    config_get PORTAL_MSG portal welcome_msg "Welcome to KolakTek Hotspot"
    config_get PORTAL_TYPE portal login_type "voucher"
    config_get PORTAL_THEME portal theme "default"
    config_get PORTAL_REDIRECT portal redirect_url ""
}

# Generate chilli configuration
generate_chilli_conf() {
    get_portal_config

    local gateway=$(uci -q get hotspotos.hotspot.gateway)
    local netmask=$(uci -q get hotspotos.hotspot.netmask)
    local pool_start=$(uci -q get hotspotos.hotspot.pool_start)
    local pool_end=$(uci -q get hotspotos.hotspot.pool_end)

    cat > $CHILLI_CONF <<EOF
# HotspotOS CoovaChilli Configuration
# Generated: $(date)

tundev tun0
net $gateway/$netmask
uamlisten $gateway
uamport 3990
uamallowed www.google.com,www.apple.com,captive.apple.com,clients3.google.com
uamanydns
dns1 8.8.8.8
dns2 8.8.4.4

# DHCP Range
dhcpif wlan0
dhcpstart $(echo $pool_start | cut -d. -f4)
dhcpend $(echo $pool_end | cut -d. -f4)

# UAM (User Authentication Module)
uamserver http://$gateway:8080/hotspotos/portal/login.html
uamhomepage http://$gateway:8080/hotspotos/portal/

# Session settings
interval 60

# Enable MAC authentication for trial
macauth
macpasswd macauth

# Radius settings (if using external radius)
# radiusserver1 localhost
# radiussecret testing123

# WISPr settings
wisprlogin http://$gateway:8080/hotspotos/portal/login.html
EOF

    log_msg "Chilli configuration generated"
}

# Start captive portal
start_portal() {
    get_portal_config

    if [ "$PORTAL_ENABLED" != "1" ]; then
        log_msg "Captive portal disabled"
        return 0
    fi

    log_msg "Starting captive portal..."

    generate_chilli_conf

    # Start CoovaChilli
    /etc/init.d/chilli start 2>/dev/null || chilli --conf=$CHILLI_CONF --daemon --pidfile /var/run/chilli.pid

    # Configure iptables redirect
    configure_redirect

    log_msg "Captive portal started"
}

# Stop captive portal
stop_portal() {
    log_msg "Stopping captive portal..."

    /etc/init.d/chilli stop 2>/dev/null
    killall chilli 2>/dev/null

    # Remove redirect rules
    remove_redirect

    log_msg "Captive portal stopped"
}

# Configure HTTP redirect
configure_redirect() {
    local gateway=$(uci -q get hotspotos.hotspot.gateway)

    # Redirect HTTP traffic to portal
    nft add rule inet fw4 prerouting iif "wlan0" tcp dport 80 redirect to :8080 2>/dev/null
    nft add rule inet fw4 prerouting iif "wlan0" tcp dport 443 redirect to :8443 2>/dev/null

    log_msg "Redirect rules applied"
}

# Remove redirect rules
remove_redirect() {
    nft flush chain inet fw4 prerouting 2>/dev/null
    log_msg "Redirect rules removed"
}

# Show portal status
portal_status() {
    echo "Captive Portal Status:"
    echo "======================="
    echo "Enabled: $(uci -q get hotspotos.portal.enabled)"
    echo "Name: $(uci -q get hotspotos.portal.name)"
    echo "Login Type: $(uci -q get hotspotos.portal.login_type)"
    echo ""
    if pgrep -x "chilli" > /dev/null; then
        echo "CoovaChilli: Running"
    else
        echo "CoovaChilli: Stopped"
    fi
}

case "$1" in
    start)
        start_portal
        ;;
    stop)
        stop_portal
        ;;
    restart)
        stop_portal
        start_portal
        ;;
    status)
        portal_status
        ;;
    *)
        echo "Usage: portal.sh {start|stop|restart|status}"
        ;;
esac
