# Locked Build Parameters & Baseline Reference: JIDU6J01 openUF Firmware

**Status:** Verified Working & Fully Adopted on Hardware  
**Baseline Release:** v1.0.0-stable  
**Verified Platform:** JioRouter AX6000 JIDU6J01 (MediaTek MT7986A Filogic 830, MT7531 DSA Switch, MT7976 DBDC Wi-Fi)

---

## 1. Locked System Credentials & Access
| Parameter | Value | Purpose |
|---|---|---|
| **Root User** | `root` | System administrator |
| **Root Password** | `admin` | Baked directly into `/etc/shadow` (SHA-512 crypt) from first boot. Prevents LuCI session loop. |
| **Adoption User** | `ubnt` | Pre-configured UniFi factory adoption account (`UID 0`, `/bin/ash`). |
| **Adoption Password** | `ubnt` | Baked directly into `/etc/shadow`. Allows UniFi Controller SSH adoption without elevation blocks. |
| **LuCI Web GUI** | Pure OpenWrt LuCI | Portal gate disabled (`openuf.web.portal='0'`), direct access at `http://<ip>`. |

---

## 2. Locked Wireless Configuration
| Band | Setting | Standard / Width | Details |
|---|---|---|---|
| **5 GHz (radio1)** | `HE160` | 802.11ax, 160 MHz Channel Width | Full AX performance, automatic DFS channel exclusion (`acs_exclude_dfs = true`). |
| **2.4 GHz (radio0)** | `HE20` | 802.11ax, 20 MHz Channel Width | Strictly locked to 20 MHz to avoid 2.4 GHz interference while keeping Wi-Fi 6 (HE). |
| **Country Code** | `US` | FCC Regulatory Domain | Maximum transmit power and 160 MHz channel availability. |
| **Stock SSIDs** | Removed | Security hardening | Default open OpenWrt SSIDs deleted before radios are enabled; SSIDs managed exclusively by UniFi Controller. |

---

## 3. Locked UniFi Integration & Auto-Discovery
| Component | Implementation | Behavior |
|---|---|---|
| **UniFi Controller Discovery** | `/usr/sbin/openuf-autodiscover` | Background daemon scans default gateway and active ARP neighbors on the LAN for active port 8080. |
| **Inform URL** | Dynamic Auto-Config | The moment controller is discovered on any IP (e.g. `192.168.1.13`), sets inform URL and maps `<ip> unifi` in `/etc/hosts`. |
| **CLI Compatibility Wrappers** | `/usr/bin/` | Wrappers for `set-inform`, `set-adopt`, `mca-cli`, and `mca-cli-op` guarantee that any command issued by the UniFi controller succeeds. |
| **Fast Roaming (802.11r)** | `openuf-rrb` daemon | Inter-AP key exchange translator for roaming between this AP and genuine UniFi APs. |
| **Fast Roaming Packages** | `ucode-mod-socket`, `kmod-veth` | Raw packet sockets and veth pairs baked directly into ROM. |

---

## 4. Locked Network & Bridge Architecture
- **Operating Mode:** Pure Bridge Access Point (WAN port + LAN1-LAN4 joined into `br-lan`).
- **Management IP:** Automatic DHCP client from upstream router / gateway.
- **Routing Services Disabled:** `dnsmasq`, `firewall`, `odhcpd`, `mwan3` disabled to prevent double-NAT or DHCP conflicts.
- **VPN:** Tailscale pre-installed inside the ROM (`tailscale`, `kmod-tun`, `ca-bundle`).

---

## 5. How to Build Updates While Keeping Everything Locked
When new OpenWrt versions (e.g., 25.12.7, 26.x) or yesrab/openUF updates are released:
1. Go to your GitHub repository: [kuduku1/jidu6j01-unifi](https://github.com/kuduku1/jidu6j01-unifi)
2. Click **Actions** ➔ **Build JIDU6J01 openUF firmware** ➔ **Run workflow**.
3. All the locked parameters above are set as defaults. If updating OpenWrt, enter the new version number; otherwise leave defaults.
4. The GitHub Action will compile a brand new binary with the latest upstream packages while keeping all your locked configurations 100% intact.
