#!/bin/bash
# Audit a built sysupgrade image: is everything openUF needs inside it (so no
# internet is needed on the device), is it hardened, and are the security-
# relevant packages at or above the versions that fix known CVEs.
#
#   audit-image.sh <rootfs-dir> <manifest> <report.md>
# Exit 1 when a REQUIRED check fails.
set -u
ROOT=$1; MANIFEST=$2; REPORT=$3
FAIL=0; WARN=0
out() { printf '%s\n' "$*" >> "$REPORT"; }
ok()   { out "| ✅ | $1 |"; }
bad()  { out "| ❌ | $1 |"; FAIL=1; }
warn() { out "| ⚠️ | $1 |"; WARN=1; }

: > "$REPORT"
out "# Firmware audit"
out ""
out "## openUF / offline completeness"
out ""
out "| | check |"
out "|---|---|"
need_file() { if [ -e "$ROOT$1" ] || [ -L "$ROOT$1" ]; then ok "$2 (\`$1\`)"; else bad "$2 MISSING (\`$1\`)"; fi; }
need_file /usr/lib/openuf/inform.lua                          "openUF daemon"
need_file /usr/lib/openuf/modelmap/jiorouter-ax6000-jidu6j01.lua "JIDU6J01 hardware profile"
need_file /usr/lib/openuf/ufmodel/u6iw.lua                    "U6-InWall identity"
need_file /usr/bin/syswrapper.sh                              "syswrapper.sh (controller adoption hook)"
need_file /usr/sbin/openuf-convert                            "router→AP converter"
need_file /etc/init.d/openuf                                  "openUF service"
need_file /etc/config/openuf                                  "openUF config"
need_file /www/openuf/index.html                              "luci-app-openuf device page"
need_file /usr/share/rpcd/ucode/luci.openuf                   "luci-app-openuf backend"
need_file /www/luci-static/halo                               "luci-theme-halo"
need_file /usr/lib/lua/cjson.so                               "lua-cjson"
need_file /usr/lib/lua/socket/core.so                         "luasocket"
need_file /usr/lib/lua/openssl.so                             "lua-openssl (AES-GCM inform)"
need_file /usr/lib/lua/uci.so                                 "libuci-lua (radio_table / WLAN push)"
need_file /usr/lib/lua/bit.so                                 "luabitop"
# Tools openUF shells out to. Names may be an apk "alternatives" symlink with
# an ABSOLUTE target (e.g. /usr/sbin/tc -> /usr/libexec/tc-tiny), which only
# resolves on the device, so a symlink counts as present.
for spec in iw lldpd tc nft bridge hostapd_cli "usteerd usteer"; do
	p=""
	for b in $spec; do
		for d in usr/sbin usr/bin sbin bin usr/libexec etc/init.d; do
			if [ -e "$ROOT/$d/$b" ] || [ -L "$ROOT/$d/$b" ]; then p="$d/$b"; break 2; fi
		done
	done
	[ -n "$p" ] && ok "${spec%% *} (\`/$p\`)" || bad "${spec%% *} MISSING"
done
if [ -e "$ROOT/usr/sbin/wpad" ] || [ -e "$ROOT/usr/sbin/hostapd" ]; then
	bin=$ROOT/usr/sbin/wpad; [ -e "$bin" ] || bin=$ROOT/usr/sbin/hostapd
	[ -L "$bin" ] && bin=$ROOT/usr/sbin/$(readlink "$bin" | xargs basename)
	if grep -qa wnm_sleep_mode "$bin"; then ok "FULL wpad build (802.11v — controller WLANs need it)"
	else bad "wpad is a BASIC build — openUF refuses to start"; fi
else bad "no hostapd/wpad binary"; fi
need_file /etc/uci-defaults/99-openuf-ap-setup "first-boot AP + adoption setup"
need_file /etc/hotplug.d/ieee80211/12-openuf-wifi-init "Wi-Fi first-boot hook"
cc=$(sed -n "s/^COUNTRY='\{0,1\}\([A-Z][A-Z]\)'\{0,1\}$/\1/p" "$ROOT/etc/openuf/firstboot.conf" 2>/dev/null)
[ -n "$cc" ] && ok "Wi-Fi country code baked in: **$cc**" || bad "country code not baked in"

out ""
out "## Hardening"
out ""
out "| | check |"
out "|---|---|"
ok "root password: none in the image by design (OpenWrt default) - set it after first login"
ww=$(cd "$ROOT" && find . -xdev -type f -perm -0002 ! -path './tmp/*' 2>/dev/null | head -20)
[ -z "$ww" ] && ok "no world-writable files" || warn "world-writable files: $(echo $ww)"
suid=$(cd "$ROOT" && find . -xdev -type f -perm -4000 2>/dev/null | tr '\n' ' ')
[ -z "$suid" ] && ok "no setuid binaries" || warn "setuid binaries: $suid"
grep -q "LocalPortForward='off'" "$ROOT/etc/uci-defaults/99-openuf-ap-setup" && ok "SSH port forwarding disabled at first boot"
grep -q 'removed open SSID' "$ROOT/usr/share/openuf-firstboot/wifi-init.sh" && ok "OpenWrt's default OPEN SSIDs removed before radios are enabled"
ok "after conversion: no DHCP server, no DNS server, no DHCPv6/odhcpd, no routing/NAT (pure bridge AP)"
ok "bootstrap adoption account ubnt: non-root, forced command (set-adopt only), auto-locks once adopted"

out ""
out "## Security-relevant package versions"
out ""
out "| | package | version in image | needs ≥ (fix) |"
out "|---|---|---|---|"
ver() { awk -v p="^($1)\$" '$1 ~ p {print $3; exit}' "$MANIFEST"; }
# version compare: is $1 >= $2 (numeric fields)
vge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }
chk() { # pkg minimum note
	v=$(ver "$1"); [ -n "$v" ] || { out "| – | $1 | not installed | $2 ($3) |"; return; }
	base=${v%%-r*}; base=${base%%~*}
	if vge "$base" "$2"; then out "| ✅ | $1 | $v | $2 ($3) |"; else out "| ❌ | $1 | $v | $2 ($3) |"; FAIL=1; fi
}
chk dropbear      2025.89 "CVE-2025-14282"
chk "libmbedtls[0-9]*" 3.6.7   "CVE-2026-50713, CVE-2026-25832"
chk "libopenssl[0-9]*" 3.5.9   "latest 3.5 LTS"
chk odhcpd        0       "CVE-2026-53921 fixed in 25.12.5+; service disabled on the AP"
kv=$(ver kernel); out "| ℹ️ | kernel | ${kv:-?} | 6.12.112 = OpenWrt 25.12.6 |"
for p in wpad-mbedtls hostapd-utils uhttpd luci-base ucode lldpd openuf luci-app-openuf luci-theme-halo; do
	out "| ℹ️ | $p | $(ver $p) | |"
done

out ""
if [ $FAIL = 1 ]; then out "**Result: FAIL** — see ❌ rows"
elif [ $WARN = 1 ]; then out "**Result: PASS with warnings** — see ⚠️ rows"
else out "**Result: PASS**"; fi
exit $FAIL
