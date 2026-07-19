include $(TOPDIR)/rules.mk

PKG_NAME:=backup-manager
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/backup-manager
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=Backup Manager for HotspotOS
  DEPENDS:=+hotspotos-core +tar +gzip
  URL:=https://hotspotos.kolaktek.com
endef

define Package/backup-manager/description
  Backup and restore manager for HotspotOS configuration.
  Handles automated backups, remote storage, and system recovery.
endef

define Build/Compile
endef

define Package/backup-manager/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/backup
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/backup/backup.sh $(1)/usr/lib/hotspotos/backup/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/backup/restore.sh $(1)/usr/lib/hotspotos/backup/
	$(INSTALL_BIN) ./files/etc/init.d/backup-manager $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,backup-manager))
