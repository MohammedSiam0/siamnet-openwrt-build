include $(TOPDIR)/rules.mk

PKG_NAME:=external-hotspot-client
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/external-hotspot-client
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=External Hotspot Client
  DEPENDS:=+hotspotos-core +curl +libopenssl
  URL:=https://hotspotos.kolaktek.com
endef

define Package/external-hotspot-client/description
  External Hotspot Client for MikroTik Hotspot authentication.
  Handles WAN detection, portal login, keep-alive, and auto-reconnect.
endef

define Build/Compile
endef

define Package/external-hotspot-client/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/external
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotspotos

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/external/client.sh $(1)/usr/lib/hotspotos/external/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/external/auth.sh $(1)/usr/lib/hotspotos/external/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/external/keepalive.sh $(1)/usr/lib/hotspotos/external/
	$(INSTALL_BIN) ./files/etc/init.d/external-hotspot-client $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,external-hotspot-client))
