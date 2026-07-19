#!/bin/sh
# HotspotOS Service Controller
# Manages all HotspotOS services

SERVICES="external-hotspot-client ttl-manager internal-hotspot captive-portal-manager free-trial-manager"

start_all() {
    echo "Starting HotspotOS services..."
    for service in $SERVICES; do
        if [ -f /etc/init.d/$service ]; then
            /etc/init.d/$service enable
            /etc/init.d/$service start
            echo "  + $service started"
        fi
    done

    # Start monitor
    /usr/lib/hotspotos/monitor.sh start

    echo "All services started"
}

stop_all() {
    echo "Stopping HotspotOS services..."

    # Stop monitor first
    /usr/lib/hotspotos/monitor.sh stop

    for service in $SERVICES; do
        if [ -f /etc/init.d/$service ]; then
            /etc/init.d/$service stop
            echo "  - $service stopped"
        fi
    done

    echo "All services stopped"
}

restart_all() {
    stop_all
    sleep 2
    start_all
}

reload_all() {
    for service in $SERVICES; do
        if [ -f /etc/init.d/$service ]; then
            /etc/init.d/$service reload
        fi
    done
}

status_all() {
    echo "HotspotOS Service Status:"
    echo "========================"
    for service in $SERVICES; do
        if [ -f /etc/init.d/$service ]; then
            local status=$(/etc/init.d/$service running 2>/dev/null && echo "running" || echo "stopped")
            local enabled=$(/etc/init.d/$service enabled 2>/dev/null && echo "enabled" || echo "disabled")
            printf "  %-30s [%s] (%s)\n" "$service" "$status" "$enabled"
        fi
    done
}

case "$1" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    reload)
        reload_all
        ;;
    status)
        status_all
        ;;
    *)
        echo "Usage: service.sh {start|stop|restart|reload|status}"
        ;;
esac
