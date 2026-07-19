#!/bin/sh
# Redirect Manager for Captive Portal
# Handles HTTP/HTTPS redirects to portal page

LOG_FILE=/var/log/captive-portal.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get redirect URL
get_redirect_url() {
    local redirect_url=$(uci -q get hotspotos.portal.redirect_url)
    local gateway=$(uci -q get hotspotos.hotspot.gateway)

    if [ -n "$redirect_url" ]; then
        echo "$redirect_url"
    else
        echo "http://${gateway}:8080/hotspotos/portal/login.html"
    fi
}

# Apply redirect rules
apply_redirect() {
    local gateway=$(uci -q get hotspotos.hotspot.gateway)

    log_msg "Applying redirect rules"

    # Create redirect chain
    nft add chain inet fw4 hotspot_redirect { type nat hook prerouting priority 0 \; } 2>/dev/null

    # Redirect unauthenticated HTTP to portal
    nft add rule inet fw4 hotspot_redirect iif "wlan0" tcp dport 80 dnat to ${gateway}:8080 2>/dev/null

    # Redirect HTTPS to portal (optional, may cause cert warnings)
    # nft add rule inet fw4 hotspot_redirect iif "wlan0" tcp dport 443 dnat to ${gateway}:8443 2>/dev/null

    log_msg "Redirect rules applied"
}

# Remove redirect rules
remove_redirect() {
    log_msg "Removing redirect rules"
    nft delete chain inet fw4 hotspot_redirect 2>/dev/null
}

# Check if URL should be allowed (whitelist)
is_allowed() {
    local url="$1"

    # Common captive portal detection URLs
    local whitelist="captive.apple.com|www.apple.com|www.google.com|clients3.google.com|connectivitycheck.gstatic.com|detectportal.firefox.com"

    if echo "$url" | grep -qiE "$whitelist"; then
        return 0
    fi

    return 1
}

case "$1" in
    apply)
        apply_redirect
        ;;
    remove)
        remove_redirect
        ;;
    url)
        get_redirect_url
        ;;
    check)
        is_allowed "$2" && echo "allowed" || echo "blocked"
        ;;
    *)
        echo "Usage: redirect.sh {apply|remove|url|check}"
        ;;
esac
