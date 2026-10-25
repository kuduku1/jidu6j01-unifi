# Sourced by the first-boot uci-defaults script and the ieee80211 hotplug hook.
# Sets country US, configures channel widths (5GHz @ 160MHz HE160, 2.4GHz @ 20MHz HE20 Wi-Fi 6),
# enables radios, and removes OpenWrt's default OPEN SSIDs.

OPENUF_WIFI_FLAG=/etc/openuf/.wifi-init-done

openuf_wifi_init() {
	cc=${1:-US}
	[ -f "$OPENUF_WIFI_FLAG" ] && return 0
	devs=$(uci -q show wireless | sed -n "s/^wireless\.\([^.=]*\)=wifi-device$/\1/p")
	[ -n "$devs" ] || return 1

	for d in $devs; do
		uci set "wireless.$d.country=$cc"
		uci -q delete "wireless.$d.disabled"

		band=$(uci -q get "wireless.$d.band")
		htmode=$(uci -q get "wireless.$d.htmode")

		# 5GHz radio: set 160MHz bandwidth (HE160)
		if [ "$band" = "5g" ] || [ "$band" = "6g" ] || echo "$htmode" | grep -qi "vht\|he80\|he160"; then
			uci set "wireless.$d.htmode=HE160"
			echo "wifi: configured $d (5GHz) to HE160 (160 MHz Wi-Fi 6)"
		else
			# 2.4GHz radio: locked strictly to 20 MHz Wi-Fi 6 (HE20)
			uci set "wireless.$d.htmode=HE20"
			echo "wifi: configured $d (2.4GHz) to HE20 (20 MHz Wi-Fi 6 802.11ax)"
		fi
	done

	for i in $(uci -q show wireless | sed -n "s/^wireless\.\([^.=]*\)=wifi-iface$/\1/p"); do
		case "$(uci -q get "wireless.$i.encryption")" in
			''|none) uci delete "wireless.$i"; echo "removed open SSID section $i" ;;
		esac
	done

	uci commit wireless
	mkdir -p /etc/openuf
	touch "$OPENUF_WIFI_FLAG"
	echo "wifi: country $cc on$(printf ' %s' $devs), radios enabled with 160MHz (5G HE160) / 20MHz (2.4G HE20 Wi-Fi 6)"
	return 0
}
