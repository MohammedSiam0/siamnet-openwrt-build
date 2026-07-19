include $(TOPDIR)/rules.mk

PKG_NAME:=internal-hotspot
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/internal-hotspot
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=Internal Hotspot Manager
  DEPENDS:=+hotspotos-core +hostapd +dnsmasq +iptables-nft +kmod-nft-nat +kmod-nft-core
  URL:=https://hotspotos.kolaktek.com
endef

define Package/internal-hotspot/description
  Internal Hotspot Manager for HotspotOS.
  Manages WiFi, DHCP, NAT, and Firewall for user network.
endef

define Build/Compile
endef

define Package/internal-hotspot/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/internal
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotspotos

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/internal/wifi.sh $(1)/usr/lib/hotspotos/internal/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/internal/dhcp.sh $(1)/usr/lib/hotspotos/internal/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/internal/nat.sh $(1)/usr/lib/hotspotos/internal/
	$(INSTALL_BIN) ./files/etc/init.d/internal-hotspot $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,internal-hotspot))
