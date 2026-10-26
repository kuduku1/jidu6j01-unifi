# JIDU6J01 + openUF Firmware (OpenWrt 25.12.6)

Custom OpenWrt image for the **JioRouter AX6000 JIDU6J01 family**
(JIDU6J01 / JIDU6201 / JIDU6401 / JIDU6601 / JIDU6701 — board name `jiorouter,ax6000-jidu6j01`) with **openUF** pre-installed and locked down.

---

## Locked Build Baseline (v1.0.0-stable)

| Feature | Locked Baseline Value |
|---|---|
| **Root Password** | `admin` (pre-hashed in image) |
| **Adoption Account** | `ubnt` / `ubnt` (`UID 0`, `/bin/ash`) |
| **UniFi Controller Discovery** | `openuf-autodiscover` daemon (automatic L2/ARP probe for port 8080) |
| **Wi-Fi 5 GHz** | **HE160** (160 MHz channel width), Country US |
| **Wi-Fi 2.4 GHz** | **HE20** (20 MHz channel width, Wi-Fi 6 802.11ax), Country US |
| **Fast Roaming (802.11r)** | `openuf-rrb`, `ucode-mod-socket`, `kmod-veth` pre-installed |
| **LuCI Web GUI** | Pure OpenWrt LuCI directly accessible at `http://<ip>` |
| **VPN** | Tailscale pre-installed (`tailscale`, `kmod-tun`, `ca-bundle`) |
| **Operating Mode** | Pure Bridge AP (WAN + LAN1-LAN4 in `br-lan`, management IP by DHCP) |

*Full documentation of locked parameters: see [BUILD-PARAMETERS.md](file:///C:/Users/2NCC/.gemini/antigravity/scratch/jidu6j01-unifi/BUILD-PARAMETERS.md).*

---

## Building Updates on GitHub Actions

Whenever OpenWrt or openUF releases an update:
1. Go to **Actions** ➔ **Build JIDU6J01 openUF firmware** ➔ **Run workflow**.
2. Defaults are locked to the verified working parameters.
3. The build compiles in ~3-4 minutes and produces a verified, audited sysupgrade image.

---

## Flashing Instructions

1. Download the sysupgrade binary: `openwrt-25.12.6-openuf-v0.2.3.2-auto-adopt-jidu6j01-sysupgrade.bin`
2. In LuCI: **System ➔ Backup / Flash Firmware ➔ Flash image…** (untick *"Keep settings"* for clean flash).
3. Connect any port to your local network. The router will automatically detect your UniFi Controller and appear in UniFi Devices as **Click to Adopt**.
4. Log into LuCI with username `root` and password `admin`.
