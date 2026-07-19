local m = Map("hotspotos", translate("HotspotOS Quick Setup Wizard"),
    translate("Configure your HotspotOS router in 8 simple steps"))

-- Step 1: Internet Source
s = m:section(TypedSection, "external", translate("Step 1: Internet Source"))
s.addremove = false
s.anonymous = true

o = s:option(ListValue, "type", translate("Connection Type"))
o:value("hotspot", "External Hotspot")
o:value("pppoe", "PPPoE")
o:value("dhcp", "DHCP")
o:value("static", "Static IP")

o = s:option(Value, "gateway", translate("Gateway"))
o:depends("type", "hotspot")

o = s:option(Value, "username", translate("Username"))
o:depends("type", "hotspot")
o:depends("type", "pppoe")

o = s:option(Value, "password", translate("Password"), translate("Password for hotspot/PPPoE"))
o.password = true
o:depends("type", "hotspot")
o:depends("type", "pppoe")

o = s:option(Flag, "auto_reconnect", translate("Auto Reconnect"))
o.default = 1

o = s:option(Flag, "save_password", translate("Save Password"))
o.default = 1

-- Step 2: Wireless
s = m:section(TypedSection, "hotspot", translate("Step 2: Wireless Setup"))
s.addremove = false
s.anonymous = true

o = s:option(Value, "ssid", translate("SSID"))
o.default = "KolakTek WiFi"

o = s:option(Value, "password", translate("Password"))
o.password = true

o = s:option(ListValue, "security", translate("Security"))
o:value("wpa2", "WPA2")
o:value("wpa3", "WPA3")

o = s:option(ListValue, "channel", translate("Channel"))
o:value("auto", "Auto")
for i=1,14 do
    o:value(tostring(i), "Channel " .. i)
end

-- Step 3: Internal Hotspot
s = m:section(TypedSection, "hotspot", translate("Step 3: Internal Hotspot"))
s.addremove = false
s.anonymous = true

o = s:option(Value, "gateway", translate("Gateway IP"))
o.default = "192.168.10.1"

o = s:option(Value, "pool_start", translate("DHCP Start"))
o.default = "192.168.10.100"

o = s:option(Value, "pool_end", translate("DHCP End"))
o.default = "192.168.10.250"

-- Step 5: TTL
s = m:section(TypedSection, "ttl", translate("Step 5: TTL Manager"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable TTL Management"))
o.default = 1

o = s:option(ListValue, "mode", translate("Mode"))
o:value("increase", "Increase TTL")
o:value("decrease", "Decrease TTL")
o:value("set", "Set Fixed TTL")

o = s:option(Value, "value", translate("Value"))
o.default = "1"

-- Step 6: Free Trial
s = m:section(TypedSection, "trial", translate("Step 6: Free Trial"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable Free Trial"))
o.default = 1

o = s:option(Value, "duration", translate("Trial Duration (minutes)"))
o.default = "10"

o = s:option(Flag, "allow_once", translate("Allow Once Per Device"))
o.default = 1

-- Step 7: Captive Portal
s = m:section(TypedSection, "portal", translate("Step 7: Captive Portal"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable Captive Portal"))
o.default = 1

o = s:option(Value, "name", translate("Portal Name"))
o.default = "KolakTek Hotspot"

o = s:option(Value, "welcome_msg", translate("Welcome Message"))
o.default = "Welcome to KolakTek Hotspot"

o = s:option(ListValue, "login_type", translate("Login Type"))
o:value("voucher", "Voucher")
o:value("username", "Username/Password")
o:value("trial", "Free Trial")

return m
