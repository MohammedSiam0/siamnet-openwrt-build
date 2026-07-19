#!/bin/sh
# External Hotspot Client
# Detects MikroTik portal and manages connection

. /lib/functions.sh

CONFIG=/etc/config/hotspotos
LOG_FILE=/var/log/external-hotspot.log
PID_FILE=/var/run/external-hotspot-client.pid

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Detect MikroTik portal
detect_portal() {
    local gateway=$(uci -q get hotspotos.external.gateway)

    if [ -z "$gateway" ]; then
        log_msg "No gateway configured"
        return 1
    fi

    # Try to detect portal by checking redirect
    local response=$(curl -s -I -m 5 "http://$gateway" 2>/dev/null | head -1)

    if echo "$response" | grep -q "302\|redirect\|login"; then
        log_msg "MikroTik portal detected at $gateway"
        echo "$gateway"
        return 0
    fi

    # Try common MikroTik paths
    for path in "/login" "/hotspot" "/status"; do
        response=$(curl -s -I -m 5 "http://${gateway}${path}" 2>/dev/null | head -1)
        if echo "$response" | grep -q "200\|302"; then
            log_msg "Portal found at ${gateway}${path}"
            echo "${gateway}${path}"
            return 0
        fi
    done

    log_msg "No portal detected"
    return 1
}

# Get login URL from portal
get_login_url() {
    local gateway=$(uci -q get hotspotos.external.gateway)
    local response=$(curl -s -m 5 "http://$gateway/login" 2>/dev/null)

    # Extract login URL from HTML form
    local login_url=$(echo "$response" | grep -o 'action="[^"]*"' | head -1 | sed 's/action="//;s/"//')

    if [ -n "$login_url" ]; then
        echo "http://${gateway}${login_url}"
    else
        echo "http://${gateway}/login"
    fi
}

# Check if already authenticated
check_auth() {
    local gateway=$(uci -q get hotspotos.external.gateway)
    local response=$(curl -s -m 5 "http://$gateway/status" 2>/dev/null)

    if echo "$response" | grep -q "status\|authenticated\|logged in"; then
        return 0
    fi

    return 1
}

# Main connection loop
connection_loop() {
    echo $$ > "$PID_FILE"
    log_msg "External Hotspot Client started"

    while true; do
        local gateway=$(uci -q get hotspotos.external.gateway)
        local username=$(uci -q get hotspotos.external.username)
        local password=$(uci -q get hotspotos.external.password)

        if [ -z "$gateway" ] || [ -z "$username" ]; then
            log_msg "Configuration incomplete"
            sleep 30
            continue
        fi

        # Check if already authenticated
        if check_auth; then
            uci set hotspotos.external.status='connected'
            uci commit hotspotos

            # Run keep-alive
            /usr/lib/hotspotos/external/keepalive.sh
        else
            uci set hotspotos.external.status='authenticating'
            uci commit hotspotos

            # Detect portal and login
            local login_url=$(get_login_url)
            log_msg "Attempting login to $login_url"

            if /usr/lib/hotspotos/external/auth.sh "$login_url" "$username" "$password"; then
                uci set hotspotos.external.status='connected'
                uci set hotspotos.external.last_login="$(date +%s)"
                uci commit hotspotos
                log_msg "Login successful"
            else
                uci set hotspotos.external.status='disconnected'
                uci commit hotspotos
                log_msg "Login failed"
            fi
        fi

        # Check every 10 seconds
        sleep 10
    done
}

start_client() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Client already running"
        return 1
    fi

    connection_loop &
    echo "External Hotspot Client started"
}

stop_client() {
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null
        rm -f "$PID_FILE"
        uci set hotspotos.external.status='disconnected'
        uci commit hotspotos
        echo "External Hotspot Client stopped"
    fi
}

case "$1" in
    start)
        start_client
        ;;
    stop)
        stop_client
        ;;
    detect)
        detect_portal
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Running"
        else
            echo "Stopped"
        fi
        ;;
    *)
        echo "Usage: client.sh {start|stop|detect|status}"
        ;;
esac
