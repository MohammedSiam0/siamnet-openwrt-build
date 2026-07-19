#!/bin/bash
# ============================================================================
# HotspotOS Router Modification Project v1.0
# Complete Build Script for OpenWrt 22.03 - lantiq/xrx200
# Target Device: KolakTek Vetch-NB403
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
OPENWRT_VERSION="22.03.6"
TARGET="lantiq"
SUBTARGET="xrx200"
DEVICE_PROFILE="kolaktek_vetch-nb403"
BUILD_DIR="${HOME}/hotspotos-build"
SDK_DIR="${BUILD_DIR}/openwrt-sdk"
IB_DIR="${BUILD_DIR}/openwrt-imagebuilder"
IPK_OUTPUT="${BUILD_DIR}/ipk-packages"
FIRMWARE_OUTPUT="${BUILD_DIR}/firmware"
FINAL_DIR="${BUILD_DIR}/HotspotOS-v1.0"

# SDK & ImageBuilder URLs
SDK_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/openwrt-sdk-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
IB_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.xz"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_DIR="${SCRIPT_DIR}/packages"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  HotspotOS Build System v1.0${NC}"
echo -e "${GREEN}  KolakTek Vetch-NB403${NC}"
echo -e "${GREEN}  OpenWrt ${OPENWRT_VERSION} - ${TARGET}/${SUBTARGET}${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# ============================================================================
# Step 1: Check dependencies
# ============================================================================
check_deps() {
    echo -e "${YELLOW}[1/8] Checking build dependencies...${NC}"

    local deps="build-essential libncurses5-dev gawk git subversion libssl-dev gettext zlib1g-dev swig unzip time rsync wget curl python3"
    local missing=""

    for dep in $deps; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            missing="$missing $dep"
        fi
    done

    if [ -n "$missing" ]; then
        echo -e "${RED}Missing dependencies:$missing${NC}"
        echo "Install with: sudo apt-get install -y$missing"
        exit 1
    fi

    echo -e "${GREEN}  All dependencies satisfied${NC}"
}

# ============================================================================
# Step 2: Prepare build directory
# ============================================================================
prepare_dirs() {
    echo -e "${YELLOW}[2/8] Preparing build directories...${NC}"

    mkdir -p "$BUILD_DIR"
    mkdir -p "$IPK_OUTPUT"
    mkdir -p "$FIRMWARE_OUTPUT"
    mkdir -p "$FINAL_DIR"

    echo -e "${GREEN}  Build directory: $BUILD_DIR${NC}"
}

# ============================================================================
# Step 3: Download SDK
# ============================================================================
download_sdk() {
    echo -e "${YELLOW}[3/8] Downloading OpenWrt SDK...${NC}"

    if [ ! -d "$SDK_DIR" ]; then
        cd "$BUILD_DIR"

        if [ ! -f "sdk.tar.xz" ]; then
            echo "  Downloading from: $SDK_URL"
            wget -q --show-progress "$SDK_URL" -O sdk.tar.xz
        fi

        echo "  Extracting SDK..."
        tar -xf sdk.tar.xz
        mv openwrt-sdk-* "$SDK_DIR"
        rm -f sdk.tar.xz

        echo -e "${GREEN}  SDK ready at: $SDK_DIR${NC}"
    else
        echo -e "${GREEN}  SDK already exists${NC}"
    fi
}

# ============================================================================
# Step 4: Download ImageBuilder
# ============================================================================
download_ib() {
    echo -e "${YELLOW}[4/8] Downloading ImageBuilder...${NC}"

    if [ ! -d "$IB_DIR" ]; then
        cd "$BUILD_DIR"

        if [ ! -f "imagebuilder.tar.xz" ]; then
            echo "  Downloading from: $IB_URL"
            wget -q --show-progress "$IB_URL" -O imagebuilder.tar.xz
        fi

        echo "  Extracting ImageBuilder..."
        tar -xf imagebuilder.tar.xz
        mv openwrt-imagebuilder-* "$IB_DIR"
        rm -f imagebuilder.tar.xz

        echo -e "${GREEN}  ImageBuilder ready at: $IB_DIR${NC}"
    else
        echo -e "${GREEN}  ImageBuilder already exists${NC}"
    fi
}

# ============================================================================
# Step 5: Setup packages in SDK
# ============================================================================
setup_packages() {
    echo -e "${YELLOW}[5/8] Setting up HotspotOS packages...${NC}"

    local sdk_pkg_dir="${SDK_DIR}/package"

    # Clean old packages
    rm -rf "${sdk_pkg_dir}"/hotspotos-*
    rm -rf "${sdk_pkg_dir}"/luci-app-hotspotos

    # Copy new packages
    cp -r "${PACKAGES_DIR}"/* "$sdk_pkg_dir/"

    echo -e "${GREEN}  Packages copied to SDK${NC}"

    # Update feeds
    cd "$SDK_DIR"
    echo "  Updating feeds..."
    ./scripts/feeds update -a >/dev/null 2>&1
    ./scripts/feeds install -a >/dev/null 2>&1

    echo -e "${GREEN}  Feeds updated${NC}"
}

# ============================================================================
# Step 6: Build IPK packages
# ============================================================================
build_ipks() {
    echo -e "${YELLOW}[6/8] Building IPK packages...${NC}"

    cd "$SDK_DIR"

    # Configure
    make defconfig >/dev/null 2>&1

    # Build packages
    local packages="hotspotos-core external-hotspot-client ttl-manager internal-hotspot captive-portal-manager free-trial-manager luci-app-hotspotos backup-manager"

    for pkg in $packages; do
        echo "  Building: $pkg"
        make "package/${pkg}/compile" V=s -j$(nproc) 2>&1 | tail -5
    done

    # Collect IPK files
    echo "  Collecting IPK files..."
    find "${SDK_DIR}/bin" -name "*.ipk" -exec cp {} "$IPK_OUTPUT/" \;

    local ipk_count=$(ls -1 "$IPK_OUTPUT"/*.ipk 2>/dev/null | wc -l)
    echo -e "${GREEN}  Built $ipk_count IPK packages${NC}"
}

# ============================================================================
# Step 7: Build firmware with ImageBuilder
# ============================================================================
build_firmware() {
    echo -e "${YELLOW}[7/8] Building firmware image...${NC}"

    cd "$IB_DIR"

    # Create custom files directory
    local files_dir="${IB_DIR}/files"
    mkdir -p "$files_dir"

    # Copy custom configuration files
    cp -r "${PACKAGES_DIR}/hotspotos-core/files/etc" "$files_dir/" 2>/dev/null || true
    cp -r "${PACKAGES_DIR}/hotspotos-core/files/usr" "$files_dir/" 2>/dev/null || true
    cp -r "${PACKAGES_DIR}/captive-portal-manager/files/www" "$files_dir/" 2>/dev/null || true

    # Package list
    local packages="hotspotos-core external-hotspot-client ttl-manager internal-hotspot captive-portal-manager free-trial-manager luci-app-hotspotos backup-manager"
    local base_packages="luci luci-ssl uhttpd uhttpd-mod-ubus rpcd rpcd-mod-file hostapd dnsmasq firewall4 nftables kmod-nft-core kmod-nft-nat coova-chilli sqlite3-cli curl libopenssl"

    # Build image
    make image \
        PROFILE="$DEVICE_PROFILE" \
        PACKAGES="$packages $base_packages" \
        FILES="$files_dir" \
        BIN_DIR="$FIRMWARE_OUTPUT" \
        2>&1 | tail -20

    echo -e "${GREEN}  Firmware built successfully${NC}"
}

# ============================================================================
# Step 8: Create final package
# ============================================================================
create_final() {
    echo -e "${YELLOW}[8/8] Creating final package...${NC}"

    # Copy files to final directory
    cp -r "$IPK_OUTPUT" "$FINAL_DIR/packages"
    cp "$FIRMWARE_OUTPUT"/*.bin "$FINAL_DIR/" 2>/dev/null || true

    # Create README
    cat > "$FINAL_DIR/README.txt" <<'EOF'
================================================================================
HotspotOS Router Modification Project v1.0
================================================================================

Target Device: KolakTek Vetch-NB403
Platform: lantiq/xrx200
OpenWrt Version: 22.03.6
Kernel: 5.10.156

SYSTEM REQUIREMENTS:
------------------
- CPU: MIPS 34Kc Dual Core 500MHz
- RAM: 128MB
- Flash: 16MB+ recommended
- Filesystem: UBI/UBIFS

PACKAGE LIST:
-------------
1. hotspotos-core.ipk          - Core framework & API
2. external-hotspot-client.ipk - MikroTik hotspot client
3. ttl-manager.ipk             - TTL rewrite manager
4. internal-hotspot.ipk         - WiFi/DHCP/NAT manager
5. captive-portal-manager.ipk  - CoovaChilli portal
6. free-trial-manager.ipk      - Free trial system
7. luci-app-hotspotos.ipk      - Web interface
8. backup-manager.ipk          - Backup/restore

INSTALLATION:
-------------
Method 1 - Flash firmware:
  sysupgrade -F HotspotOS-*.bin

Method 2 - Install packages:
  opkg install *.ipk
  /etc/init.d/hotspotos enable
  /etc/init.d/hotspotos start

ACCESS:
-------
- Web Interface: http://192.168.1.20:8080
- Default LAN IP: 192.168.1.20
- HTTPS: 443 (optional)

QUICK SETUP WIZARD (8 Steps):
-----------------------------
1. Configure Internet Source (External Hotspot/PPPoE/DHCP/Static)
2. Wireless Setup (SSID, Password, Security)
3. Internal Hotspot Setup (Gateway, DHCP Range)
4. External Hotspot Login (Status monitoring)
5. TTL Manager (TTL rewrite rules)
6. Free Trial Setup (Duration, MAC identification)
7. Captive Portal (Login page, vouchers)
8. Finish & Apply

CONFIGURATION:
--------------
All settings stored in UCI:
  /etc/config/hotspotos

Sections:
  - system    : General system settings
  - external  : External hotspot connection
  - ttl       : TTL management
  - hotspot   : Internal WiFi hotspot
  - trial     : Free trial settings
  - portal    : Captive portal settings

SERVICES:
---------
  /etc/init.d/hotspotos              start|stop|restart
  /etc/init.d/external-hotspot-client start|stop|restart
  /etc/init.d/ttl-manager            start|stop|restart
  /etc/init.d/internal-hotspot       start|stop|restart
  /etc/init.d/captive-portal-manager start|stop|restart
  /etc/init.d/free-trial-manager     start|stop|restart
  /etc/init.d/backup-manager         start|stop|restart

COMMANDS:
---------
  hotspotos status          - Show system status
  hotspotos config get      - Get configuration
  hotspotos config set      - Set configuration
  hotspotos service start   - Start all services
  hotspotos monitor start   - Start monitoring

NETWORK FLOW:
-------------
External Internet
       |
MikroTik Hotspot (TTL=1)
       |
   WAN Port
       |
OpenWrt HotspotOS Router
       |
   TTL Fix (+1)
       |
Internal Hotspot
       |
   Users (WiFi/DHCP/NAT)

SUPPORT:
--------
KolakTek <support@kolaktek.com>
https://hotspotos.kolaktek.com

LICENSE: GPL-2.0
================================================================================
EOF

    # Create build info
    cat > "$FINAL_DIR/BUILD_INFO.txt" <<EOF
Build Date: $(date)
OpenWrt Version: $OPENWRT_VERSION
Target: $TARGET/$SUBTARGET
Device Profile: $DEVICE_PROFILE
SDK URL: $SDK_URL
ImageBuilder URL: $IB_URL

Packages Built:
$(ls -1 "$IPK_OUTPUT"/*.ipk 2>/dev/null)

Firmware Files:
$(ls -1 "$FIRMWARE_OUTPUT"/*.bin 2>/dev/null || echo "See firmware/ directory")
EOF

    # Create install script
    cat > "$FINAL_DIR/install.sh" <<'EOF'
#!/bin/sh
# HotspotOS Package Installation Script

echo "=================================="
echo "  HotspotOS Installation"
echo "=================================="
echo ""

# Check if running on OpenWrt
if [ ! -f /etc/openwrt_release ]; then
    echo "ERROR: This script must run on OpenWrt"
    exit 1
fi

# Install packages
echo "Installing packages..."
for pkg in packages/*.ipk; do
    if [ -f "$pkg" ]; then
        echo "  Installing: $(basename $pkg)"
        opkg install "$pkg"
    fi
done

# Enable services
echo ""
echo "Enabling services..."
for service in hotspotos external-hotspot-client ttl-manager internal-hotspot captive-portal-manager free-trial-manager backup-manager; do
    /etc/init.d/$service enable 2>/dev/null
    echo "  + $service enabled"
done

# Start core service
echo ""
echo "Starting HotspotOS..."
/etc/init.d/hotspotos start

echo ""
echo "=================================="
echo "  Installation Complete!"
echo "=================================="
echo ""
echo "Access: http://192.168.1.20:8080"
echo ""
EOF
    chmod +x "$FINAL_DIR/install.sh"

    echo -e "${GREEN}  Final package created at: $FINAL_DIR${NC}"
}

# ============================================================================
# Main build process
# ============================================================================
main() {
    check_deps
    prepare_dirs
    download_sdk
    download_ib
    setup_packages
    build_ipks
    build_firmware
    create_final

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  BUILD COMPLETE!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "Output: ${BLUE}$FINAL_DIR${NC}"
    echo -e "Packages: ${BLUE}$IPK_OUTPUT${NC}"
    echo -e "Firmware: ${BLUE}$FIRMWARE_OUTPUT${NC}"
    echo ""
    echo "To install on router:"
    echo "  1. Copy $FINAL_DIR to router"
    echo "  2. Run: cd /path/to/HotspotOS-v1.0 && sh install.sh"
    echo "  3. Or flash: sysupgrade -F HotspotOS-*.bin"
    echo ""
}

# Run main
main "$@"
