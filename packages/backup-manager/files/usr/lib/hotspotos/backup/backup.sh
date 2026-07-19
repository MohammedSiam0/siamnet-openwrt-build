#!/bin/sh
# Backup Manager for HotspotOS

BACKUP_DIR=/etc/hotspotos/backups
CONFIG_FILES="/etc/config/hotspotos /etc/config/network /etc/config/wireless /etc/config/firewall /etc/config/dhcp /etc/config/uhttpd"
LOG_FILE=/var/log/backup-manager.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Initialize backup directory
init_backup() {
    mkdir -p "$BACKUP_DIR"
    log_msg "Backup directory initialized: $BACKUP_DIR"
}

# Create backup
create_backup() {
    init_backup

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="hotspotos_backup_${timestamp}"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    local temp_dir=$(mktemp -d)

    log_msg "Creating backup: $backup_name"

    # Copy configuration files
    for file in $CONFIG_FILES; do
        if [ -f "$file" ]; then
            mkdir -p "${temp_dir}/$(dirname $file)"
            cp "$file" "${temp_dir}${file}"
        fi
    done

    # Copy custom files
    cp -r /www/hotspotos "${temp_dir}/www/" 2>/dev/null
    cp -r /etc/hotspotos "${temp_dir}/etc/" 2>/dev/null

    # Create backup info
    cat > "${temp_dir}/backup.info" <<EOF
HotspotOS Backup
=================
Date: $(date)
Version: $(uci -q get hotspotos.system.version)
Device: $(uci -q get hotspotos.system.device)
EOF

    # Create archive
    tar -czf "$backup_file" -C "$temp_dir" .
    rm -rf "$temp_dir"

    log_msg "Backup created: $backup_file ($(du -h "$backup_file" | cut -f1))"
    echo "$backup_file"
}

# List backups
list_backups() {
    init_backup

    echo "Available Backups:"
    echo "=================="
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read line; do
        echo "$line"
    done
}

# Delete old backups (keep last N)
cleanup_backups() {
    local keep="${1:-10}"

    ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +$((keep + 1)) | while read file; do
        rm -f "$file"
        log_msg "Deleted old backup: $file"
    done
}

case "$1" in
    create)
        create_backup
        ;;
    list)
        list_backups
        ;;
    cleanup)
        cleanup_backups "$2"
        ;;
    *)
        echo "Usage: backup.sh {create|list|cleanup [keep_count]}"
        ;;
esac
