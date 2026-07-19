#!/bin/sh
# HotspotOS Configuration Manager
# Handles UCI configuration read/write

. /lib/functions.sh

CONFIG_FILE=/etc/config/hotspotos

# Get configuration value
hs_get() {
    local section="$1"
    local option="$2"
    local default="$3"
    local value

    config_load hotspotos
    config_get value "$section" "$option" "$default"
    echo "$value"
}

# Set configuration value
hs_set() {
    local section="$1"
    local option="$2"
    local value="$3"

    uci set hotspotos.${section}.${option}="$value"
}

# Commit changes
hs_commit() {
    uci commit hotspotos
}

# Reset to defaults
hs_reset() {
    cp /rom/etc/config/hotspotos /etc/config/hotspotos
}

# Export configuration
hs_export() {
    uci export hotspotos
}

# Import configuration
hs_import() {
    local file="$1"
    if [ -f "$file" ]; then
        uci import hotspotos < "$file"
        uci commit hotspotos
        return 0
    fi
    return 1
}

# Validate configuration
hs_validate() {
    local errors=0

    # Check required sections
    for section in system external ttl hotspot trial portal; do
        if ! uci -q get hotspotos.${section} >/dev/null 2>&1; then
            echo "Missing section: $section"
            errors=$((errors + 1))
        fi
    done

    # Validate IP addresses
    local lan_ip=$(hs_get system lan_ip "")
    if [ -z "$lan_ip" ]; then
        echo "LAN IP not configured"
        errors=$((errors + 1))
    fi

    return $errors
}

# Backup configuration
hs_backup() {
    local backup_file="/tmp/hotspotos-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$backup_file" /etc/config/hotspotos /etc/hotspotos/ /www/hotspotos/ 2>/dev/null
    echo "$backup_file"
}

# Restore configuration
hs_restore() {
    local backup_file="$1"
    if [ -f "$backup_file" ]; then
        tar -xzf "$backup_file" -C /
        uci commit hotspotos
        return 0
    fi
    return 1
}

# Execute command
case "$1" in
    get)
        hs_get "$2" "$3" "$4"
        ;;
    set)
        hs_set "$2" "$3" "$4"
        ;;
    commit)
        hs_commit
        ;;
    reset)
        hs_reset
        ;;
    export)
        hs_export
        ;;
    import)
        hs_import "$2"
        ;;
    validate)
        hs_validate
        ;;
    backup)
        hs_backup
        ;;
    restore)
        hs_restore "$2"
        ;;
    *)
        echo "Usage: config.sh {get|set|commit|reset|export|import|validate|backup|restore}"
        ;;
esac
