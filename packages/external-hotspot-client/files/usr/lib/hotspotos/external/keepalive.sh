#!/bin/sh
# Keep-alive script for MikroTik Hotspot

GATEWAY=$(uci -q get hotspotos.external.gateway)
INTERVAL=60

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/external-hotspot.log
}

keep_alive() {
    while true; do
        # Send keep-alive request
        local response=$(curl -s -m 5 "http://$GATEWAY/status" 2>/dev/null)

        if ! echo "$response" | grep -qi "authenticated\|status"; then
            log_msg "Keep-alive failed, connection may be lost"
            return 1
        fi

        # Update session time
        local session_time=$(uci -q get hotspotos.external.session_time)
        session_time=$((session_time + INTERVAL))
        uci set hotspotos.external.session_time="$session_time"
        uci commit hotspotos

        sleep $INTERVAL
    done
}

if [ -n "$GATEWAY" ]; then
    keep_alive
fi
