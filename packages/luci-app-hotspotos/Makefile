include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-hotspotos
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-hotspotos
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI HotspotOS App
  DEPENDS:=+luci-base +hotspotos-core +luci-lib-jsonc
  URL:=https://hotspotos.kolaktek.com
endef

define Package/luci-app-hotspotos/description
  LuCI web interface for HotspotOS Router Modification Project.
  Provides Quick Setup Wizard, Status Dashboard, and Configuration Management.
endef

define Build/Compile
endef

define Package/luci-app-hotspotos/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/hotspotos
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/hotspotos
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/hotspotos
	$(INSTALL_DIR) $(1)/www/hotspotos

	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/hotspotos/index.lua $(1)/usr/lib/lua/luci/controller/hotspotos/
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/hotspotos/setup.lua $(1)/usr/lib/lua/luci/model/cbi/hotspotos/
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/hotspotos/dashboard.htm $(1)/usr/lib/lua/luci/view/hotspotos/
	$(INSTALL_DATA) ./files/www/hotspotos/index.html $(1)/www/hotspotos/
endef

$(eval $(call BuildPackage,luci-app-hotspotos))
