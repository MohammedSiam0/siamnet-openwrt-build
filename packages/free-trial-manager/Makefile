include $(TOPDIR)/rules.mk

PKG_NAME:=free-trial-manager
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/free-trial-manager
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=Free Trial Manager
  DEPENDS:=+hotspotos-core +sqlite3-cli
  URL:=https://hotspotos.kolaktek.com
endef

define Package/free-trial-manager/description
  Free Trial Manager for HotspotOS.
  Manages MAC address database, trial timers, and blocking after expiration.
endef

define Build/Compile
endef

define Package/free-trial-manager/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/trial
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotspotos

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/trial/trial.sh $(1)/usr/lib/hotspotos/trial/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/trial/macdb.sh $(1)/usr/lib/hotspotos/trial/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/trial/timer.sh $(1)/usr/lib/hotspotos/trial/
	$(INSTALL_BIN) ./files/etc/init.d/free-trial-manager $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,free-trial-manager))
