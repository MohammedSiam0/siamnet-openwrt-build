#!/bin/sh
# Free Trial Manager
# Main controller for free trial functionality

. /lib/functions.sh

LOG_FILE=/var/log/free-trial.log
DB_FILE=/etc/hotspotos/trial.db

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get trial configuration
get_trial_config() {
    config_load hotspotos
    config_get TRIAL_ENABLED trial enabled "0"
    config_get TRIAL_DURATION trial duration "10"
    config_get TRIAL_IDENT trial identification "mac"
    config_get TRIAL_ONCE trial allow_once "1"
}

# Initialize trial database
init_trial_db() {
    if [ ! -f "$DB_FILE" ]; then
        cat > "$DB_FILE" <<EOF
# HotspotOS Free Trial Database
# Format: MAC|FirstSeen|StartTime|ExpireTime|Status|UsedCount
EOF
        chmod 600 "$DB_FILE"
        log_msg "Trial database initialized"
    fi
}

# Check if device is eligible for trial
is_eligible() {
    local mac="$1"

    get_trial_config

    if [ "$TRIAL_ENABLED" != "1" ]; then
        echo "disabled"
        return 1
    fi

    init_trial_db

    local entry=$(grep "^${mac}|" "$DB_FILE" 2>/dev/null)

    if [ -z "$entry" ]; then
        # New device, eligible
        echo "eligible"
        return 0
    fi

    local used_count=$(echo "$entry" | cut -d'|' -f6)
    local status=$(echo "$entry" | cut -d'|' -f5)

    if [ "$TRIAL_ONCE" = "1" ] && [ "$used_count" -gt 0 ]; then
        echo "used"
        return 1
    fi

    if [ "$status" = "active" ]; then
        echo "active"
        return 0
    fi

    if [ "$status" = "expired" ]; then
        if [ "$TRIAL_ONCE" = "1" ]; then
            echo "expired"
            return 1
        else
            echo "eligible"
            return 0
        fi
    fi

    echo "eligible"
    return 0
}

# Start trial for device
start_trial() {
    local mac="$1"
    local ip="$2"

    get_trial_config

    local eligibility=$(is_eligible "$mac")

    if [ "$eligibility" != "eligible" ] && [ "$eligibility" != "active" ]; then
        log_msg "Device $mac not eligible for trial: $eligibility"
        return 1
    fi

    init_trial_db

    local current_time=$(date +%s)
    local expire_time=$((current_time + TRIAL_DURATION * 60))

    if [ "$eligibility" = "active" ]; then
        # Already has active trial, extend it
        log_msg "Extending trial for $mac"
        sed -i "s/^${mac}|\([^|]*|\)\{3\}[^|]*/${mac}|\1${expire_time}|active/" "$DB_FILE"
    else
        # New trial
        local first_seen=$current_time
        local used_count=1

        # Remove old entry if exists
        sed -i "/^${mac}|/d" "$DB_FILE"

        echo "${mac}|${first_seen}|${current_time}|${expire_time}|active|${used_count}|${ip}" >> "$DB_FILE"
        log_msg "Trial started for $mac, expires at $(date -d @$expire_time)"
    fi

    # Add to firewall allow list
    allow_device "$mac" "$ip"

    return 0
}

# Stop trial for device
stop_trial() {
    local mac="$1"

    init_trial_db

    # Update status to expired
    sed -i "s/^${mac}|\([^|]*|\)\{4\}active/${mac}|\1expired/" "$DB_FILE"

    # Block device
    block_device "$mac"

    log_msg "Trial stopped for $mac"
}

# Allow device through firewall
allow_device() {
    local mac="$1"
    local ip="$2"

    # Add nftables rule to allow this MAC
    nft add rule inet fw4 input ether saddr $mac accept 2>/dev/null
    nft add rule inet fw4 forward ether saddr $mac accept 2>/dev/null

    log_msg "Device allowed: $mac"
}

# Block device
block_device() {
    local mac="$1"

    # Remove allow rules
    nft delete rule inet fw4 input ether saddr $mac accept 2>/dev/null
    nft delete rule inet fw4 forward ether saddr $mac accept 2>/dev/null

    # Add drop rule
    nft add rule inet fw4 input ether saddr $mac drop 2>/dev/null
    nft add rule inet fw4 forward ether saddr $mac drop 2>/dev/null

    log_msg "Device blocked: $mac"
}

# Check and expire trials
check_expired() {
    local current_time=$(date +%s)

    init_trial_db

    while IFS='|' read -r mac first_seen start expire status used_count ip; do
        [ -z "$mac" ] && continue
        [ "$mac" = "#" ] && continue

        if [ "$status" = "active" ] && [ "$current_time" -gt "$expire" ]; then
            stop_trial "$mac"
            log_msg "Trial expired for $mac"
        fi
    done < "$DB_FILE"
}

# Show trial status
show_status() {
    init_trial_db

    echo "Free Trial Status:"
    echo "=================="
    echo "Enabled: $(uci -q get hotspotos.trial.enabled)"
    echo "Duration: $(uci -q get hotspotos.trial.duration) minutes"
    echo "Allow Once: $(uci -q get hotspotos.trial.allow_once)"
    echo ""
    echo "Active Trials:"
    echo "MAC | First Seen | Start | Expire | Status | Used | IP"
    echo "--- | ---------- | ----- | ------ | ------ | ---- | --"

    while IFS='|' read -r mac first_seen start expire status used_count ip; do
        [ -z "$mac" ] && continue
        [ "$mac" = "#" ] && continue

        if [ "$status" = "active" ]; then
            local start_fmt=$(date -d "@$start" "+%H:%M" 2>/dev/null || echo "$start")
            local expire_fmt=$(date -d "@$expire" "+%H:%M" 2>/dev/null || echo "$expire")
            echo "$mac | $start_fmt | $expire_fmt | $status | $used_count | $ip"
        fi
    done < "$DB_FILE"
}

# Main trial loop
trial_loop() {
    log_msg "Free Trial Manager started"

    while true; do
        check_expired
        sleep 30
    done
}

start_trial_manager() {
    trial_loop &
    echo "Free Trial Manager started"
}

stop_trial_manager() {
    killall -f "trial.sh" 2>/dev/null
    echo "Free Trial Manager stopped"
}

case "$1" in
    start)
        start_trial_manager
        ;;
    stop)
        stop_trial_manager
        ;;
    check)
        check_expired
        ;;
    eligible)
        is_eligible "$2"
        ;;
    start-trial)
        start_trial "$2" "$3"
        ;;
    stop-trial)
        stop_trial "$2"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: trial.sh {start|stop|check|eligible|start-trial|stop-trial|status}"
        ;;
esac
