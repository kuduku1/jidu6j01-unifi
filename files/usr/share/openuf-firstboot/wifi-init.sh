# Sourced by the first-boot uci-defaults script and the ieee80211 hotplug hook.
# Sets the regulatory country on every radio, enables the radios, and removes
# OpenWrt's default OPEN "OpenWrt" SSIDs (they would bridge anyone straight
# into the LAN before the controller pushes the real WLANs). Runs once.

OPENUF_WIFI_FLAG=/etc/openuf/.wifi-init-done

openuf_wifi_init() {
	cc=${1:-US}
	[ -f "$OPENUF_WIFI_FLAG" ] && return 0
	devs=$(uci -q show wireless | sed -n "s/^wireless\.\([^.=]*\)=wifi-device$/\1/p")
	[ -n "$devs" ] || return 1
	for d in $devs; do
		uci set "wireless.$d.country=$cc"
		uci -q delete "wireless.$d.disabled"
	done
	for i in $(uci -q show wireless | sed -n "s/^wireless\.\([^.=]*\)=wifi-iface$/\1/p"); do
		case "$(uci -q get "wireless.$i.encryption")" in
			''|none) uci delete "wireless.$i"; echo "removed open SSID section $i" ;;
		esac
	done
	uci commit wireless
	mkdir -p /etc/openuf
	touch "$OPENUF_WIFI_FLAG"
	echo "wifi: country $cc on$(printf ' %s' $devs), radios enabled"
	return 0
}
