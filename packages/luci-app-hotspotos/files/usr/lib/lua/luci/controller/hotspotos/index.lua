module("luci.controller.hotspotos.index", package.seeall)

function index()
    entry({"admin", "hotspotos"}, firstchild(), _("HotspotOS"), 60).dependent = false
    entry({"admin", "hotspotos", "dashboard"}, template("hotspotos/dashboard"), _("Dashboard"), 1)
    entry({"admin", "hotspotos", "setup"}, cbi("hotspotos/setup"), _("Quick Setup"), 2)
    entry({"admin", "hotspotos", "status"}, call("action_status"), _("Status"), 3)
    entry({"admin", "hotspotos", "api"}, call("action_api"), nil).leaf = true
end

function action_status()
    local sys = require "luci.sys"
    local http = require "luci.http"

    local status = {
        system = {
            uptime = sys.exec("cat /proc/uptime | awk '{print $1}'"),
            load = sys.exec("cat /proc/loadavg | awk '{print $1}'"),
            memory = sys.exec("free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'")
        },
        network = {
            wan = sys.exec("cat /sys/class/net/eth0/operstate 2>/dev/null || echo 'unknown'"),
            lan = sys.exec("cat /sys/class/net/br-lan/operstate 2>/dev/null || echo 'unknown'")
        }
    }

    http.prepare_content("application/json")
    http.write_json(status)
end

function action_api()
    local http = require "luci.http"
    local cmd = http.formvalue("cmd") or ""

    local result = sys.exec("/usr/lib/hotspotos/api.sh " .. cmd)

    http.prepare_content("application/json")
    http.write(result)
end
