# JIDU6J01 + openUF firmware (OpenWrt 25.12.6)

Custom OpenWrt image for the **JioRouter AX6000 JIDU6J01 family**
(JIDU6J01 / JIDU6201 / JIDU6401 / JIDU6601 / JIDU6701 — one image, board name
`jiorouter,ax6000-jidu6j01`) with **openUF** baked in, so after flashing the box
becomes a UniFi-adoptable access point with **no internet needed**.

> Not for the **JIDU6101** — that is a different OpenWrt profile and image.

## What the image does on first boot (once, no reboot needed)

| | |
|---|---|
| Model profile | openUF `jiorouter-ax6000-jidu6j01`, presents as **U6-InWall** |
| Wi-Fi country | **US** on both radios, plus openUF `country_override=US` |
| Router → AP | WAN port joins the LAN bridge (any of the 5 ports is uplink), LAN takes **DHCP**, DHCP server / DNS / firewall / odhcpd off |
| Adoption | L2 discovery on, restricted `ubnt`/`ubnt` bootstrap login (only `set-adopt`, locks itself once adopted) |
| Security | root password from `ROOT_PASSWORD` secret (hash only), default **open** "OpenWrt" SSIDs removed, SSH port-forwarding off, LuCI on HTTPS |
| Packages | full `wpad-mbedtls` (802.11v needed by UniFi WLANs), openuf + luci-app-openuf + luci-theme-halo, lua-openssl, libuci-lua, lldpd, usteer, nftables, tc… |
| Log | `/root/openuf-firstboot.log` |

## Build (GitHub Actions, ~30–40 min)

1. Create a **private** GitHub repo and upload this folder (keep `.github/`).
2. Settings → Secrets and variables → Actions → **New secret** `ROOT_PASSWORD`.
3. Actions → **Build JIDU6J01 openUF firmware** → Run workflow
   (defaults: 25.12.6, openUF `main`, US, DHCP).
4. Download the artifact: `…-openuf-…-squashfs-sysupgrade.bin`, `sha256sums`,
   `AUDIT.md` (must say PASS), `CVE-SCAN.md`.

## Flash

Router already runs plain OpenWrt → LuCI **System → Backup / Flash Firmware →
Flash image…**, **untick "Keep settings"**, or over SSH:
`sysupgrade -n /tmp/<file>-sysupgrade.bin`. sysupgrade refuses the image if the
board is not a JIDU6J01-family unit.

Then plug any port into the UniFi network. The box gets a DHCP address
(192.168.1.1 is gone), shows up in UniFi **Devices** as a U6-InWall → **Adopt**.

Undo AP mode: `openuf-convert --revert && reboot`.
