# HotspotOS Router Modification Project v1.0

## نظرة عامة

نظام HotspotOS هو إطار عمل متكامل لإدارة نقاط الوصول اللاسلكية (Hotspot) على أجهزة راوتر KolakTek Vetch-NB403 المبنية على OpenWrt 22.03.

## الهيكل العام

```
External Internet
       |
MikroTik Hotspot (TTL=1)
       |
   WAN Port
       |
+---------------------------+
|    OpenWrt Base           |
|    KolakTek Vetch-NB403   |
|    Linux Kernel 5.10.156  |
|    OpenWrt 22.03          |
|    lantiq/xrx200          |
+---------------------------+
       |
  HotspotOS Framework
       |
+---------------------------+
|  hotspotos-core           |
|  - Configuration Manager  |
|  - Service Controller     |
|  - API Manager            |
|  - System Monitor         |
+---------------------------+
       |
   ---------------------
   |      |      |     |
External  TTL   Internal Free
Hotspot  Manager Hotspot Trial
```

## البكجات (8 IPK)

| البكج | الوظيفة |
|-------|---------|
| `hotspotos-core.ipk` | العقل الرئيسي - إدارة الإعدادات والخدمات والـ API |
| `external-hotspot-client.ipk` | الاتصال بـ MikroTik Hotspot الخارجي |
| `ttl-manager.ipk` | إدارة TTL باستخدام nftables/fw4 |
| `internal-hotspot.ipk` | إدارة WiFi و DHCP و NAT |
| `captive-portal-manager.ipk` | بوابة الدخول باستخدام CoovaChilli |
| `free-trial-manager.ipk` | نظام التجربة المجانية مع MAC database |
| `luci-app-hotspotos.ipk` | واجهة الويب الرسومية (LuCI) |
| `backup-manager.ipk` | النسخ الاحتياطي والاستعادة |

## Quick Setup Wizard (8 خطوات)

### الخطوة 1: Configure Internet Source
- **External Hotspot** (افتراضي): Gateway, Username, Password, Auto Reconnect
- **PPPoE**: Username, Password, VLAN ID, MTU
- **DHCP**: Automatic IP
- **Static IP**: IP, Subnet, Gateway, DNS

### الخطوة 2: Wireless Setup
- SSID, Password, Security (WPA2/WPA3), Channel

### الخطوة 3: Internal Hotspot Setup
- Hotspot Name, Domain, Gateway (192.168.10.1), DHCP Pool (192.168.10.100-250)

### الخطوة 4: External Hotspot Login
- Status: Connected/Disconnected/Authenticating
- Session monitoring

### الخطوة 5: TTL Manager (إجباري)
- Mode: Increase/Decrease/Set
- Value: 1 (افتراضي)
- يحفظ في: `/etc/config/hotspotos`

### الخطوة 6: Free Trial Setup
- Enable/Disable
- Duration: 10 minutes (افتراضي)
- Identification: MAC Address
- Allow Once: Yes/No

### الخطوة 7: Captive Portal
- Portal Name, Logo, Welcome Message
- Login Type: Voucher/Username/Free Trial

### الخطوة 8: Finish
- Apply Configuration
- Restart Services
- Reboot if required

## ملفات الإعداد (UCI)

```
/etc/config/hotspotos

config system 'system'
config external 'external'
config ttl 'ttl'
config hotspot 'hotspot'
config trial 'trial'
config portal 'portal'
```

## بناء السوفتوير

### المتطلبات
- Ubuntu/Debian Linux
- 2GB+ RAM
- 10GB+ مساحة قرص
- اتصال إنترنت

### خطوات البناء

```bash
# 1. تثبيت المتطلبات
sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev gawk git \
    subversion libssl-dev gettext zlib1g-dev swig unzip time rsync wget curl

# 2. تشغيل سكربت البناء
chmod +x build.sh
./build.sh

# 3. النتيجة
# - IPK packages: build/ipk-packages/
# - Firmware: build/firmware/
# - Final package: build/HotspotOS-v1.0/
```

## التثبيت

### طريقة 1: تثبيت البكجات
```bash
opkg install *.ipk
/etc/init.d/hotspotos enable
/etc/init.d/hotspotos start
```

### طريقة 2: فلاش السوفتوير
```bash
sysupgrade -F HotspotOS-*.bin
```

## الوصول

- **Web Interface**: http://192.168.1.20:8080
- **Default LAN IP**: 192.168.1.20
- **HTTPS**: 443 (اختياري)

## الأوامر

```bash
# عرض الحالة
hotspotos status

# إدارة الإعدادات
hotspotos config get <section> <option>
hotspotos config set <section> <option> <value>

# إدارة الخدمات
hotspotos service start
hotspotos service stop
hotspotos service restart
hotspotos service status

# المراقبة
hotspotos monitor start
hotspotos monitor stop
```

## المواصفات التقنية

| المكون | القيمة |
|--------|--------|
| Target Device | KolakTek Vetch-NB403 |
| CPU | MIPS 34Kc Dual Core 500MHz |
| RAM | 128MB |
| Platform | lantiq/xrx200 |
| Kernel | 5.10.156 |
| OpenWrt | 22.03 |
| Filesystem | UBI/UBIFS |
| Web | uhttpd |
| Process | procd |
| Config | UCI |
| Network | netifd |
| Firewall | nftables |
| Portal | CoovaChilli |

## الترخيص

GPL-2.0

## الدعم

KolakTek <support@kolaktek.com>
https://hotspotos.kolaktek.com
