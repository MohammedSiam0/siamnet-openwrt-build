include $(TOPDIR)/rules.mk

PKG_NAME:=hotspotos-core
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/hotspotos-core
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=HotspotOS Core Framework
  DEPENDS:=+libuci +libubus +libblobmsg-json +jshn +uhttpd +uhttpd-mod-ubus +rpcd +rpcd-mod-file
  URL:=https://hotspotos.kolaktek.com
endef

define Package/hotspotos-core/description
  HotspotOS Core Framework - Configuration Manager, Service Controller, API Manager
  and System Monitor for KolakTek Vetch-NB403 routers.
  Provides the central management system for all HotspotOS components.
endef

define Build/Compile
endef

define Package/hotspotos-core/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos
	$(INSTALL_DIR) $(1)/etc/hotspotos
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/uci-defaults

	$(INSTALL_CONF) ./files/etc/config/hotspotos $(1)/etc/config/
	$(INSTALL_BIN) ./files/etc/init.d/hotspotos $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/api.sh $(1)/usr/lib/hotspotos/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/config.sh $(1)/usr/lib/hotspotos/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/monitor.sh $(1)/usr/lib/hotspotos/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/service.sh $(1)/usr/lib/hotspotos/
	$(INSTALL_BIN) ./files/usr/sbin/hotspotos $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-hotspotos $(1)/etc/uci-defaults/
endef

define Package/hotspotos-core/conffiles
/etc/config/hotspotos
/etc/hotspotos/
endef

$(eval $(call BuildPackage,hotspotos-core))
