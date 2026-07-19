#!/bin/sh
# HotspotOS System Monitor
# Monitors system health, network status, and services

. /lib/functions.sh

LOG_FILE=/var/log/hotspotos-monitor.log
PID_FILE=/var/run/hotspotos-monitor.pid

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Monitor WAN connection
monitor_wan() {
    local gateway=$(uci -q get hotspotos.external.gateway)
    local auto_reconnect=$(uci -q get hotspotos.external.auto_reconnect)

    if [ -n "$gateway" ] && [ "$auto_reconnect" = "1" ]; then
        if ! ping -c 1 -W 3 "$gateway" >/dev/null 2>&1; then
            log_msg "WAN gateway unreachable: $gateway"
            # Trigger reconnect
            /etc/init.d/external-hotspot-client restart
        fi
    fi
}

# Monitor services
monitor_services() {
    local services="external-hotspot-client ttl-manager internal-hotspot captive-portal-manager free-trial-manager"

    for service in $services; do
        if /etc/init.d/$service enabled; then
            if ! pgrep -f "$service" >/dev/null 2>&1; then
                log_msg "Service $service not running, restarting..."
                /etc/init.d/$service restart
            fi
        fi
    done
}

# Monitor memory usage
monitor_memory() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

    if [ "$mem_usage" -gt 90 ]; then
        log_msg "WARNING: High memory usage: ${mem_usage}%"
        # Clear caches
        echo 3 > /proc/sys/vm/drop_caches
    fi
}

# Monitor disk space
monitor_disk() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

    if [ "$disk_usage" -gt 85 ]; then
        log_msg "WARNING: High disk usage: ${disk_usage}%"
        # Clean old logs
        find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null
    fi
}

# Main monitor loop
monitor_loop() {
    echo $$ > "$PID_FILE"

    while true; do
        monitor_wan
        monitor_services
        monitor_memory
        monitor_disk

        # Run every 30 seconds
        sleep 30
    done
}

# Start monitor
start_monitor() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Monitor already running"
        return 1
    fi

    monitor_loop &
    echo "Monitor started"
}

# Stop monitor
stop_monitor() {
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null
        rm -f "$PID_FILE"
        echo "Monitor stopped"
    fi
}

case "$1" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Monitor running (PID: $(cat $PID_FILE))"
        else
            echo "Monitor not running"
        fi
        ;;
    *)
        echo "Usage: monitor.sh {start|stop|status}"
        ;;
esac
