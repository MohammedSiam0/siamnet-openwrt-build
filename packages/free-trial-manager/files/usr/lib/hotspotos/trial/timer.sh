#!/bin/sh
# Trial Timer Manager
# Manages countdown timers for free trials

DB_FILE=/etc/hotspotos/trial.db
LOG_FILE=/var/log/free-trial.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get remaining time for MAC
get_remaining() {
    local mac="$1"
    local current_time=$(date +%s)

    local entry=$(grep "^${mac}|" "$DB_FILE" 2>/dev/null)

    if [ -z "$entry" ]; then
        echo "0"
        return 1
    fi

    local expire=$(echo "$entry" | cut -d'|' -f4)
    local remaining=$((expire - current_time))

    if [ "$remaining" -lt 0 ]; then
        echo "0"
        return 1
    fi

    echo "$remaining"
}

# Format remaining time
format_time() {
    local seconds="$1"
    local minutes=$((seconds / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d" "$minutes" "$secs"
}

# Check if trial is active
is_active() {
    local mac="$1"
    local remaining=$(get_remaining "$mac")

    if [ "$remaining" -gt 0 ]; then
        return 0
    fi

    return 1
}

# Send warning before expiration
send_warning() {
    local mac="$1"
    local remaining=$(get_remaining "$mac")

    # Warn at 5 minutes, 2 minutes, 1 minute
    if [ "$remaining" -eq 300 ] || [ "$remaining" -eq 120 ] || [ "$remaining" -eq 60 ]; then
        log_msg "Trial warning: $mac has $(format_time $remaining) remaining"
    fi
}

# Timer loop
timer_loop() {
    while true; do
        local current_time=$(date +%s)

        while IFS='|' read -r mac first start expire status used_count ip; do
            [ -z "$mac" ] && continue
            [ "$mac" = "#" ] && continue

            if [ "$status" = "active" ]; then
                local remaining=$((expire - current_time))

                if [ "$remaining" -le 0 ]; then
                    # Trial expired
                    /usr/lib/hotspotos/trial/trial.sh stop-trial "$mac"
                else
                    send_warning "$mac"
                fi
            fi
        done < "$DB_FILE"

        sleep 10
    done
}

case "$1" in
    remaining)
        get_remaining "$2"
        ;;
    format)
        format_time "$2"
        ;;
    active)
        is_active "$2" && echo "yes" || echo "no"
        ;;
    loop)
        timer_loop
        ;;
    *)
        echo "Usage: timer.sh {remaining|format|active|loop}"
        ;;
esac
