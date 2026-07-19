#!/bin/sh
# Session Manager for Captive Portal
# Manages user sessions and authentication

SESSION_DB=/etc/hotspotos/sessions.db
LOG_FILE=/var/log/captive-portal.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Initialize session database
init_db() {
    if [ ! -f "$SESSION_DB" ]; then
        cat > "$SESSION_DB" <<EOF
# HotspotOS Session Database
# Format: MAC|IP|Username|StartTime|ExpireTime|Status|DataUsage
EOF
        chmod 600 "$SESSION_DB"
    fi
}

# Add new session
add_session() {
    local mac="$1"
    local ip="$2"
    local username="$3"
    local duration="$4"

    init_db

    local start_time=$(date +%s)
    local expire_time=$((start_time + duration * 60))

    # Remove existing session for this MAC
    sed -i "/^${mac}|/d" "$SESSION_DB"

    # Add new session
    echo "${mac}|${ip}|${username}|${start_time}|${expire_time}|active|0" >> "$SESSION_DB"

    log_msg "Session added: MAC=$mac, IP=$ip, User=$username, Duration=${duration}min"
}

# Remove session
remove_session() {
    local mac="$1"
    sed -i "/^${mac}|/d" "$SESSION_DB"
    log_msg "Session removed: MAC=$mac"
}

# Check session status
check_session() {
    local mac="$1"
    local current_time=$(date +%s)

    init_db

    local session=$(grep "^${mac}|" "$SESSION_DB" 2>/dev/null)

    if [ -z "$session" ]; then
        echo "not_found"
        return 1
    fi

    local expire_time=$(echo "$session" | cut -d'|' -f5)
    local status=$(echo "$session" | cut -d'|' -f6)

    if [ "$current_time" -gt "$expire_time" ]; then
        echo "expired"
        # Update status
        sed -i "s/^${mac}|.*/${session%|*}|expired/" "$SESSION_DB"
        return 1
    fi

    if [ "$status" = "active" ]; then
        echo "active"
        return 0
    else
        echo "$status"
        return 1
    fi
}

# List active sessions
list_sessions() {
    init_db

    echo "Active Sessions:"
    echo "MAC | IP | Username | Start | Expire | Status | Data"
    echo "--- | -- | -------- | ----- | ------ | ------ | ----"

    while IFS='|' read -r mac ip username start expire status data; do
        [ -z "$mac" ] && continue
        [ "$mac" = "#" ] && continue

        if [ "$status" = "active" ]; then
            local start_fmt=$(date -d "@$start" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$start")
            local expire_fmt=$(date -d "@$expire" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$expire")
            echo "$mac | $ip | $username | $start_fmt | $expire_fmt | $status | ${data}MB"
        fi
    done < "$SESSION_DB"
}

# Update data usage
update_data() {
    local mac="$1"
    local data_mb="$2"

    sed -i "s/^${mac}|\([^|]*|\)\{6\}[^|]*/${mac}|\1${data_mb}/" "$SESSION_DB"
}

# Clean expired sessions
clean_sessions() {
    local current_time=$(date +%s)

    while IFS='|' read -r mac ip username start expire status data; do
        [ -z "$mac" ] && continue
        [ "$mac" = "#" ] && continue

        if [ "$current_time" -gt "$expire" ] && [ "$status" = "active" ]; then
            sed -i "s/^${mac}|.*/${mac}|${ip}|${username}|${start}|${expire}|expired|${data}/" "$SESSION_DB"
            log_msg "Session expired: MAC=$mac"
        fi
    done < "$SESSION_DB"
}

case "$1" in
    add)
        add_session "$2" "$3" "$4" "$5"
        ;;
    remove)
        remove_session "$2"
        ;;
    check)
        check_session "$2"
        ;;
    list)
        list_sessions
        ;;
    update)
        update_data "$2" "$3"
        ;;
    clean)
        clean_sessions
        ;;
    *)
        echo "Usage: session.sh {add|remove|check|list|update|clean} [args...]"
        ;;
esac
