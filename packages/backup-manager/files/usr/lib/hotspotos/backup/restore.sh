#!/bin/sh
# Restore Manager for HotspotOS

BACKUP_DIR=/etc/hotspotos/backups
LOG_FILE=/var/log/backup-manager.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Restore from backup
restore_backup() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        if [ -f "${BACKUP_DIR}/${backup_file}" ]; then
            backup_file="${BACKUP_DIR}/${backup_file}"
        else
            echo "ERROR: Backup file not found: $backup_file"
            return 1
        fi
    fi

    log_msg "Restoring from: $backup_file"

    # Create restore point before restoring
    /usr/lib/hotspotos/backup/backup.sh create > /dev/null 2>&1

    # Extract backup
    tar -xzf "$backup_file" -C /

    # Commit UCI changes
    uci commit

    log_msg "Restore completed successfully"
    echo "Restore completed. Please reboot the router."
}

# Show backup info
backup_info() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        echo "Backup file not found"
        return 1
    fi

    echo "Backup Information:"
    echo "==================="
    tar -xzf "$backup_file" -O backup.info 2>/dev/null || echo "No info available"
}

case "$1" in
    restore)
        restore_backup "$2"
        ;;
    info)
        backup_info "$2"
        ;;
    *)
        echo "Usage: restore.sh {restore <backup_file>|info <backup_file>}"
        ;;
esac
