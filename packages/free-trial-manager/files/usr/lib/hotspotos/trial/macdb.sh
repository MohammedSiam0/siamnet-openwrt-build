#!/bin/sh
# MAC Address Database Manager
# Manages MAC address entries for free trial

DB_FILE=/etc/hotspotos/trial.db

# Add MAC entry
add_mac() {
    local mac="$1"
    local ip="$2"

    local current_time=$(date +%s)
    local expire_time=$((current_time + 600))  # 10 minutes default

    echo "${mac}|${current_time}|${current_time}|${expire_time}|active|1|${ip}" >> "$DB_FILE"
}

# Get MAC entry
get_mac() {
    local mac="$1"
    grep "^${mac}|" "$DB_FILE" 2>/dev/null
}

# Update MAC entry
update_mac() {
    local mac="$1"
    local field="$2"
    local value="$3"

    case "$field" in
        status)
            sed -i "s/^${mac}|\([^|]*|\)\{4\}[^|]*/${mac}|\1${value}/" "$DB_FILE"
            ;;
        expire)
            sed -i "s/^${mac}|\([^|]*|\)\{3\}[^|]*/${mac}|\1${value}/" "$DB_FILE"
            ;;
        count)
            sed -i "s/^${mac}|\([^|]*|\)\{5\}[^|]*/${mac}|\1${value}/" "$DB_FILE"
            ;;
    esac
}

# Delete MAC entry
delete_mac() {
    local mac="$1"
    sed -i "/^${mac}|/d" "$DB_FILE"
}

# List all MACs
list_macs() {
    grep -v "^#" "$DB_FILE" 2>/dev/null | while IFS='|' read -r mac first start expire status count ip; do
        echo "MAC: $mac | Status: $status | Used: $count | IP: $ip"
    done
}

# Clean old entries
clean_old() {
    local days="${1:-30}"
    local cutoff=$(date -d "${days} days ago" +%s 2>/dev/null || echo "0")

    sed -i "/^[^#].*|${cutoff}/d" "$DB_FILE" 2>/dev/null
}

case "$1" in
    add)
        add_mac "$2" "$3"
        ;;
    get)
        get_mac "$2"
        ;;
    update)
        update_mac "$2" "$3" "$4"
        ;;
    delete)
        delete_mac "$2"
        ;;
    list)
        list_macs
        ;;
    clean)
        clean_old "$2"
        ;;
    *)
        echo "Usage: macdb.sh {add|get|update|delete|list|clean}"
        ;;
esac
