#!/bin/sh
# HotspotOS API Manager
# Provides JSON-RPC API for web interface

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

API_VERSION="1.0.0"
CONFIG=/etc/config/hotspotos

# Initialize JSON response
api_init() {
    json_init
    json_add_string "version" "$API_VERSION"
    json_add_string "status" "ok"
}

# Get system status
api_get_status() {
    local lan_ip web_port version device

    config_load hotspotos
    config_get lan_ip system lan_ip "192.168.1.20"
    config_get web_port system web_port "8080"
    config_get version system version "1.0.0"
    config_get device system device "KolakTek Vetch-NB403"

    json_init
    json_add_object "system"
    json_add_string "device" "$device"
    json_add_string "version" "$version"
    json_add_string "lan_ip" "$lan_ip"
    json_add_string "web_port" "$web_port"
    json_add_string "uptime" "$(cat /proc/uptime | awk '{print $1}')"
    json_add_string "load" "$(cat /proc/loadavg | awk '{print $1}')"
    json_add_string "memory" "$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')"
    json_close_object

    json_add_object "network"
    json_add_string "wan_status" "$(cat /sys/class/net/eth0/operstate 2>/dev/null || echo 'unknown')"
    json_add_string "lan_status" "$(cat /sys/class/net/br-lan/operstate 2>/dev/null || echo 'unknown')"
    json_add_string "wifi_status" "$(iw dev wlan0 info 2>/dev/null | grep type | awk '{print $2}' || echo 'down')"
    json_close_object

    json_add_object "hotspot"
    config_get external_status external status "disconnected"
    config_get ttl_enabled ttl enabled "0"
    config_get trial_enabled trial enabled "0"
    config_get portal_enabled portal enabled "0"

    json_add_string "external_status" "$external_status"
    json_add_boolean "ttl_enabled" "$ttl_enabled"
    json_add_boolean "trial_enabled" "$trial_enabled"
    json_add_boolean "portal_enabled" "$portal_enabled"
    json_close_object

    json_dump
}

# Get active users
api_get_users() {
    json_init
    json_add_array "users"

    # Get from chilli or internal hotspot
    if [ -f /var/run/chilli.sock ]; then
        chilli_query list 2>/dev/null | while read line; do
            json_add_object
            json_add_string "mac" "$(echo $line | awk '{print $1}')"
            json_add_string "ip" "$(echo $line | awk '{print $2}')"
            json_add_string "status" "$(echo $line | awk '{print $3}')"
            json_close_object
        done
    fi

    json_close_array
    json_dump
}

# Quick Setup Wizard API
api_quick_setup() {
    local step="$1"
    local data="$2"

    case "$step" in
        1)
            # Internet Source
            json_load "$data"
            json_get_var source_type type
            json_get_var gateway gateway
            json_get_var username username
            json_get_var password password
            json_get_var auto_reconnect auto_reconnect
            json_get_var save_password save_password

            uci set hotspotos.external.enabled='1'
            uci set hotspotos.external.type="$source_type"
            uci set hotspotos.external.gateway="$gateway"
            uci set hotspotos.external.username="$username"
            [ "$save_password" = "1" ] && uci set hotspotos.external.password="$password"
            uci set hotspotos.external.auto_reconnect="$auto_reconnect"
            uci commit hotspotos

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Internet source configured"
            ;;
        2)
            # Wireless Setup
            json_load "$data"
            json_get_var ssid ssid
            json_get_var password password
            json_get_var security security
            json_get_var channel channel

            uci set hotspotos.hotspot.ssid="$ssid"
            uci set hotspotos.hotspot.password="$password"
            uci set hotspotos.hotspot.security="$security"
            uci set hotspotos.hotspot.channel="$channel"
            uci commit hotspotos

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Wireless configured"
            ;;
        3)
            # Internal Hotspot
            json_load "$data"
            json_get_var hotspot_name name
            json_get_var domain domain
            json_get_var gateway gateway
            json_get_var pool_start pool_start
            json_get_var pool_end pool_end

            uci set hotspotos.hotspot.enabled='1'
            uci set hotspotos.hotspot.ssid="$hotspot_name"
            uci set hotspotos.hotspot.domain="$domain"
            uci set hotspotos.hotspot.gateway="$gateway"
            uci set hotspotos.hotspot.pool_start="$pool_start"
            uci set hotspotos.hotspot.pool_end="$pool_end"
            uci commit hotspotos

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Internal hotspot configured"
            ;;
        5)
            # TTL Manager
            json_load "$data"
            json_get_var enabled enabled
            json_get_var mode mode
            json_get_var value value

            uci set hotspotos.ttl.enabled="$enabled"
            uci set hotspotos.ttl.mode="$mode"
            uci set hotspotos.ttl.value="$value"
            uci commit hotspotos

            /etc/init.d/ttl-manager restart

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "TTL manager configured"
            ;;
        6)
            # Free Trial
            json_load "$data"
            json_get_var enabled enabled
            json_get_var duration duration
            json_get_var allow_once allow_once

            uci set hotspotos.trial.enabled="$enabled"
            uci set hotspotos.trial.duration="$duration"
            uci set hotspotos.trial.allow_once="$allow_once"
            uci commit hotspotos

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Free trial configured"
            ;;
        7)
            # Captive Portal
            json_load "$data"
            json_get_var enabled enabled
            json_get_var portal_name name
            json_get_var welcome_msg welcome_msg
            json_get_var login_type login_type

            uci set hotspotos.portal.enabled="$enabled"
            uci set hotspotos.portal.name="$portal_name"
            uci set hotspotos.portal.welcome_msg="$welcome_msg"
            uci set hotspotos.portal.login_type="$login_type"
            uci commit hotspotos

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Captive portal configured"
            ;;
        8)
            # Finish - Apply all
            /usr/lib/hotspotos/service.sh restart

            json_init
            json_add_string "status" "ok"
            json_add_string "message" "Configuration applied successfully"
            json_add_boolean "reboot_required" "1"
            ;;
        *)
            json_init
            json_add_string "status" "error"
            json_add_string "message" "Invalid step"
            ;;
    esac

    json_dump
}

# Main API dispatcher
case "$1" in
    status)
        api_get_status
        ;;
    users)
        api_get_users
        ;;
    setup)
        api_quick_setup "$2" "$3"
        ;;
    *)
        api_init
        json_dump
        ;;
esac
