include $(TOPDIR)/rules.mk

PKG_NAME:=captive-portal-manager
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/captive-portal-manager
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=Captive Portal Manager
  DEPENDS:=+hotspotos-core +coova-chilli +coova-chilli-mod-miniportal +libjson-c
  URL:=https://hotspotos.kolaktek.com
endef

define Package/captive-portal-manager/description
  Captive Portal Manager for HotspotOS.
  Manages CoovaChilli, login pages, sessions, and redirects.
endef

define Build/Compile
endef

define Package/captive-portal-manager/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/portal
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/chilli
	$(INSTALL_DIR) $(1)/www/hotspotos/portal

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/portal/portal.sh $(1)/usr/lib/hotspotos/portal/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/portal/session.sh $(1)/usr/lib/hotspotos/portal/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/portal/redirect.sh $(1)/usr/lib/hotspotos/portal/
	$(INSTALL_BIN) ./files/etc/init.d/captive-portal-manager $(1)/etc/init.d/
	$(INSTALL_DATA) ./files/etc/chilli/defaults $(1)/etc/chilli/
	$(INSTALL_DATA) ./files/www/hotspotos/portal/login.html $(1)/www/hotspotos/portal/
	$(INSTALL_DATA) ./files/www/hotspotos/portal/style.css $(1)/www/hotspotos/portal/
endef

$(eval $(call BuildPackage,captive-portal-manager))
