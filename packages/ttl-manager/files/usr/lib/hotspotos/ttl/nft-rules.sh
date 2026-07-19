#!/bin/sh
# nftables rules generator for TTL Manager

NFT_TABLE="hotspotos_ttl"

# Generate nftables rules file
generate_rules() {
    local enabled=$(uci -q get hotspotos.ttl.enabled)
    local mode=$(uci -q get hotspotos.ttl.mode)
    local value=$(uci -q get hotspotos.ttl.value)
    local interface=$(uci -q get hotspotos.ttl.interface)

    if [ "$enabled" != "1" ]; then
        echo "# TTL Manager disabled"
        return
    fi

    cat <<EOF
# HotspotOS TTL Rules
# Generated: $(date)

table inet $NFT_TABLE {
    chain postrouting {
        type filter hook postrouting priority 0;
EOF

    case "$mode" in
        increase)
        echo "        ip ttl set ttl + $value"
        echo "        ip6 hoplimit set hoplimit + $value"
        ;;
        decrease)
        echo "        ip ttl set ttl - $value"
        echo "        ip6 hoplimit set hoplimit - $value"
        ;;
        set)
        echo "        ip ttl set $value"
        echo "        ip6 hoplimit set $value"
        ;;
    esac

    cat <<EOF
    }
}
EOF
}

generate_rules
