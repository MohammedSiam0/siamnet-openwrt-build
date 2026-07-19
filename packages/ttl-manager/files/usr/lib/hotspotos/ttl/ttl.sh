#!/bin/sh
# TTL Manager for HotspotOS
# Manages TTL rewrite rules using nftables

. /lib/functions.sh

LOG_FILE=/var/log/ttl-manager.log
NFT_TABLE="hotspotos_ttl"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get TTL configuration
get_ttl_config() {
    config_load hotspotos
    config_get TTL_ENABLED ttl enabled "0"
    config_get TTL_MODE ttl mode "increase"
    config_get TTL_VALUE ttl value "1"
    config_get TTL_INTERFACE ttl interface "wan"
}

# Apply TTL rules using nftables
apply_ttl_rules() {
    get_ttl_config

    if [ "$TTL_ENABLED" != "1" ]; then
        log_msg "TTL Manager disabled"
        remove_ttl_rules
        return 0
    fi

    log_msg "Applying TTL rules - Mode: $TTL_MODE, Value: $TTL_VALUE"

    # Remove existing rules first
    remove_ttl_rules

    # Create nftables table and chain
    nft add table inet $NFT_TABLE 2>/dev/null
    nft add chain inet $NFT_TABLE postrouting { type filter hook postrouting priority 0 \; } 2>/dev/null

    case "$TTL_MODE" in
        increase)
            # Increase TTL by value
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip ttl set ttl + $TTL_VALUE 2>/dev/null
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip6 hoplimit set hoplimit + $TTL_VALUE 2>/dev/null
            log_msg "TTL increase rule applied: +$TTL_VALUE"
            ;;
        decrease)
            # Decrease TTL by value
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip ttl set ttl - $TTL_VALUE 2>/dev/null
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip6 hoplimit set hoplimit - $TTL_VALUE 2>/dev/null
            log_msg "TTL decrease rule applied: -$TTL_VALUE"
            ;;
        set)
            # Set TTL to fixed value
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip ttl set $TTL_VALUE 2>/dev/null
            nft add rule inet $NFT_TABLE postrouting oif "$TTL_INTERFACE" ip6 hoplimit set $TTL_VALUE 2>/dev/null
            log_msg "TTL set rule applied: =$TTL_VALUE"
            ;;
        *)
            log_msg "Unknown TTL mode: $TTL_MODE"
            return 1
            ;;
    esac

    # Save rules for persistence
    nft list ruleset > /etc/hotspotos/ttl-rules.nft

    return 0
}

# Remove TTL rules
remove_ttl_rules() {
    log_msg "Removing TTL rules"

    # Delete table if exists
    nft delete table inet $NFT_TABLE 2>/dev/null

    # Also try to flush any existing rules
    nft flush ruleset 2>/dev/null

    return 0
}

# Show current TTL rules
show_ttl_rules() {
    echo "Current TTL Rules:"
    echo "=================="
    nft list table inet $NFT_TABLE 2>/dev/null || echo "No TTL rules active"
    echo ""
    echo "Configuration:"
    echo "  Enabled: $(uci -q get hotspotos.ttl.enabled)"
    echo "  Mode: $(uci -q get hotspotos.ttl.mode)"
    echo "  Value: $(uci -q get hotspotos.ttl.value)"
    echo "  Interface: $(uci -q get hotspotos.ttl.interface)"
}

# Main
case "$1" in
    start|apply)
        apply_ttl_rules
        ;;
    stop|remove)
        remove_ttl_rules
        ;;
    restart)
        remove_ttl_rules
        apply_ttl_rules
        ;;
    status)
        show_ttl_rules
        ;;
    *)
        echo "Usage: ttl.sh {start|stop|restart|status}"
        ;;
esac
