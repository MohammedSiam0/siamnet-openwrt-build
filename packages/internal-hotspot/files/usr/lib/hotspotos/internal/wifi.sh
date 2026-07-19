#!/bin/sh
# Internal Hotspot WiFi Manager
# Configures wireless interface for hotspot

. /lib/functions.sh
. /lib/functions/system.sh

LOG_FILE=/var/log/internal-hotspot.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get wireless configuration
get_wifi_config() {
    config_load hotspotos
    config_get SSID hotspot ssid "KolakTek WiFi"
    config_get PASSWORD hotspot password ""
    config_get SECURITY hotspot security "wpa2"
    config_get CHANNEL hotspot channel "auto"
    config_get BAND hotspot band "2g"
}

# Configure wireless interface
configure_wifi() {
    get_wifi_config

    log_msg "Configuring WiFi: SSID=$SSID, Security=$SECURITY, Channel=$CHANNEL"

    # Find wireless device
    local wifi_device=$(uci show wireless | grep "wifi-device" | head -1 | cut -d. -f2 | cut -d= -f1)

    if [ -z "$wifi_device" ]; then
        log_msg "ERROR: No wireless device found"
        return 1
    fi

    # Configure wireless device
    uci set wireless.${wifi_device}.disabled='0'
    uci set wireless.${wifi_device}.channel="$CHANNEL"

    # Set band
    case "$BAND" in
        2g)
            uci set wireless.${wifi_device}.band='2g'
            ;;
        5g)
            uci set wireless.${wifi_device}.band='5g'
            ;;
    esac

    # Create or update wireless interface
    local wifi_iface=$(uci show wireless | grep "wifi-iface" | grep "network='hotspot'" | head -1 | cut -d. -f2 | cut -d= -f1)

    if [ -z "$wifi_iface" ]; then
        wifi_iface=$(uci add wireless wifi-iface)
    fi

    uci set wireless.${wifi_iface}.device="$wifi_device"
    uci set wireless.${wifi_iface}.mode='ap'
    uci set wireless.${wifi_iface}.network='hotspot'
    uci set wireless.${wifi_iface}.ssid="$SSID"
    uci set wireless.${wifi_iface}.encryption="$SECURITY"

    if [ -n "$PASSWORD" ] && [ "$SECURITY" != "none" ]; then
        uci set wireless.${wifi_iface}.key="$PASSWORD"
    fi

    # Additional security options
    case "$SECURITY" in
        wpa2)
            uci set wireless.${wifi_iface}.encryption='psk2'
            ;;
        wpa3)
            uci set wireless.${wifi_iface}.encryption='sae'
            ;;
        wpa2+wpa3)
            uci set wireless.${wifi_iface}.encryption='psk2+ccmp'
            ;;
    esac

    uci commit wireless

    log_msg "WiFi configuration applied"
    return 0
}

# Start wireless
start_wifi() {
    configure_wifi
    wifi reload
    log_msg "WiFi started"
}

# Stop wireless
stop_wifi() {
    wifi down
    log_msg "WiFi stopped"
}

# Restart wireless
restart_wifi() {
    stop_wifi
    sleep 2
    start_wifi
}

# Show WiFi status
wifi_status() {
    echo "WiFi Status:"
    echo "============"
    iw dev 2>/dev/null | grep -E "Interface|ssid|type|channel" || echo "No wireless interfaces"
    echo ""
    echo "Configuration:"
    echo "  SSID: $(uci -q get hotspotos.hotspot.ssid)"
    echo "  Security: $(uci -q get hotspotos.hotspot.security)"
    echo "  Channel: $(uci -q get hotspotos.hotspot.channel)"
}

case "$1" in
    start)
        start_wifi
        ;;
    stop)
        stop_wifi
        ;;
    restart)
        restart_wifi
        ;;
    configure)
        configure_wifi
        ;;
    status)
        wifi_status
        ;;
    *)
        echo "Usage: wifi.sh {start|stop|restart|configure|status}"
        ;;
esac
