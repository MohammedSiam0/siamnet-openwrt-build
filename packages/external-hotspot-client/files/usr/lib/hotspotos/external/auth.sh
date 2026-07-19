#!/bin/sh
# Authentication script for MikroTik Hotspot

LOGIN_URL="$1"
USERNAME="$2"
PASSWORD="$3"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/external-hotspot.log
}

# Attempt login
attempt_login() {
    local login_url="$1"
    local username="$2"
    local password="$3"

    log_msg "Attempting login with username: $username"

    # Standard MikroTik login
    local response=$(curl -s -L -m 10         -d "username=$username"         -d "password=$password"         "$login_url" 2>/dev/null)

    # Check response for success indicators
    if echo "$response" | grep -qi "success\|authenticated\|logged in\|radvertisement"; then
        log_msg "Authentication successful"
        return 0
    fi

    # Try alternative login method
    response=$(curl -s -L -m 10         -d "dst="         -d "popup=true"         -d "username=$username"         -d "password=$password"         "${login_url}/login" 2>/dev/null)

    if echo "$response" | grep -qi "success\|authenticated\|logged in"; then
        log_msg "Authentication successful (alternative method)"
        return 0
    fi

    log_msg "Authentication failed"
    return 1
}

# Main
if [ -z "$LOGIN_URL" ] || [ -z "$USERNAME" ]; then
    echo "Usage: auth.sh <login_url> <username> [password]"
    exit 1
fi

attempt_login "$LOGIN_URL" "$USERNAME" "$PASSWORD"
