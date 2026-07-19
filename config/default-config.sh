# HotspotOS Default Configuration
# This file is used during first boot to set default values

# System
uci set hotspotos.system.version='1.0.0'
uci set hotspotos.system.device='KolakTek Vetch-NB403'
uci set hotspotos.system.platform='lantiq/xrx200'
uci set hotspotos.system.kernel='5.10.156'
uci set hotspotos.system.openwrt='22.03'
uci set hotspotos.system.web_port='8080'
uci set hotspotos.system.https_port='443'
uci set hotspotos.system.lan_ip='192.168.1.20'
uci set hotspotos.system.status='active'

# External Hotspot
uci set hotspotos.external.enabled='1'
uci set hotspotos.external.type='hotspot'
uci set hotspotos.external.gateway='192.168.88.1'
uci set hotspotos.external.auto_reconnect='1'
uci set hotspotos.external.save_password='1'
uci set hotspotos.external.status='disconnected'

# TTL
uci set hotspotos.ttl.enabled='1'
uci set hotspotos.ttl.mode='increase'
uci set hotspotos.ttl.value='1'
uci set hotspotos.ttl.interface='wan'

# Internal Hotspot
uci set hotspotos.hotspot.enabled='1'
uci set hotspotos.hotspot.ssid='KolakTek WiFi'
uci set hotspotos.hotspot.domain='hotspot.local'
uci set hotspotos.hotspot.gateway='192.168.10.1'
uci set hotspotos.hotspot.pool_start='192.168.10.100'
uci set hotspotos.hotspot.pool_end='192.168.10.250'
uci set hotspotos.hotspot.netmask='255.255.255.0'
uci set hotspotos.hotspot.dhcp_lease='12h'
uci set hotspotos.hotspot.security='wpa2'
uci set hotspotos.hotspot.channel='auto'

# Free Trial
uci set hotspotos.trial.enabled='1'
uci set hotspotos.trial.duration='10'
uci set hotspotos.trial.identification='mac'
uci set hotspotos.trial.allow_once='1'

# Captive Portal
uci set hotspotos.portal.enabled='1'
uci set hotspotos.portal.name='KolakTek Hotspot'
uci set hotspotos.portal.logo='/www/hotspotos/logo.png'
uci set hotspotos.portal.welcome_msg='Welcome to KolakTek Hotspot'
uci set hotspotos.portal.login_type='voucher'
uci set hotspotos.portal.theme='default'

uci commit hotspotos
