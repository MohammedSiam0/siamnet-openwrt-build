include $(TOPDIR)/rules.mk

PKG_NAME:=ttl-manager
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=KolakTek <support@kolaktek.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/ttl-manager
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=HotspotOS
  TITLE:=TTL Manager
  DEPENDS:=+hotspotos-core +nftables +kmod-nft-core +firewall4
  URL:=https://hotspotos.kolaktek.com
endef

define Package/ttl-manager/description
  TTL Manager for HotspotOS.
  Rewrites TTL values on LAN traffic before WAN exit.
  Uses nftables/fw4 for packet manipulation.
endef

define Build/Compile
endef

define Package/ttl-manager/install
	$(INSTALL_DIR) $(1)/usr/lib/hotspotos/ttl
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/share/nftables.d/ruleset-post

	$(INSTALL_BIN) ./files/usr/lib/hotspotos/ttl/ttl.sh $(1)/usr/lib/hotspotos/ttl/
	$(INSTALL_BIN) ./files/usr/lib/hotspotos/ttl/nft-rules.sh $(1)/usr/lib/hotspotos/ttl/
	$(INSTALL_BIN) ./files/etc/init.d/ttl-manager $(1)/etc/init.d/
	$(INSTALL_DATA) ./files/usr/share/nftables.d/ruleset-post/99-ttl.nft $(1)/usr/share/nftables.d/ruleset-post/
endef

$(eval $(call BuildPackage,ttl-manager))
