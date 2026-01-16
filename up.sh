#!/bin/bash
# up.sh - Kemas kini penuh fail /usr/bin + (opsyen) pasang semula UDP & SlowDNS
# Serasi: Ubuntu 22.04+
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

REPO_BASE="https://raw.githubusercontent.com/Budaxcomel/v4/main"
TRIAL_BASE="https://raw.githubusercontent.com/Fikripps/Ver3/main"

info() { echo -e " [INFO] $*"; }
warn() { echo -e " [AMARAN] $*"; }

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Sila jalankan sebagai root."
  exit 1
fi

apt-get update -y >/dev/null 2>&1 || true
apt-get install -y --no-install-recommends wget curl unzip >/dev/null 2>&1 || true

download() {
  local src="$1"
  local dst="$2"
  local url="$3"

  if wget -q -O "$dst" "$url"; then
    chmod +x "$dst" || true
    info "OK: $src -> $dst"
  else
    warn "Gagal: $src (URL: $url)"
    return 1
  fi
}

info "Memulakan kemas kini fail..."

# Senarai fail dari repo ini
declare -A FILES=(
  [menu]="menu/menu.sh"
  [menu-vmess]="menu/menu-vmess.sh"
  [menu-vless]="menu-vless.sh"
  [running]="menu/running.sh"
  [clearcache]="menu/clearcache.sh"
  [menu-trgo]="menu/menu-trgo.sh"
  [menu-trojan]="menu/menu-trojan.sh"
  [menu-sshh]="menu/menu-sshh.sh"
  [usernew]="ssh/usernew.sh"
  [trial]="ssh/trial.sh"
  [renew]="ssh/renew.sh"
  [hapus]="ssh/hapus.sh"
  [cek]="ssh/cek.sh"
  [member]="ssh/member.sh"
  [delete]="ssh/delete.sh"
  [autokilll]="ssh/autokilll.sh"
  [ceklim]="ssh/ceklim.sh"
  [tendang]="ssh/tendang.sh"
  [menu-set]="menu/menu-set.sh"
  [menu-domain]="menu/menu-domain.sh"
  [add-host]="ssh/add-host.sh"
  [port-change]="port/port-change.sh"
  [certv2ray]="xray/certv2ray.sh"
  [menu-webmin]="menu/menu-webmin.sh"
  [speedtest]="ssh/speedtest_cli.py"
  [about]="menu/about.sh"
  [auto-reboot]="menu/auto-reboot.sh"
  [restarts]="menu/restarts.sh"
  [bw]="menu/bw.sh"
  [port-ssl]="port/port-ssl.sh"
  [port-ovpn]="port/port-ovpn.sh"
  [xp]="ssh/xp.sh"
  [acs-set]="acs-set.sh"
  [sshws]="ssh/sshws.sh"
  [status]="status.sh"
  [jam]="jam.sh"
  [bot]="bot.sh"
  [install-bot]="install-bot.sh"
)

# Fail dari repo luar (jika masih diperlukan)
TRIAL_SCRIPT_PATH="menu/menu-trial.sh"

# Muat turun fail ke /usr/bin
for cmd in "${!FILES[@]}"; do
  path="${FILES[$cmd]}"
  download "$path" "/usr/bin/$cmd" "$REPO_BASE/$path" || true
done

# menu-trial dari repo luar (jika wujud)
download "$TRIAL_SCRIPT_PATH" "/usr/bin/menu-trial" "$TRIAL_BASE/$TRIAL_SCRIPT_PATH" || true

# Backup/restore
download "backup/menu-backup.sh" "/usr/bin/menu-backup" "$REPO_BASE/backup/menu-backup.sh" || true
download "backup/backup.sh" "/usr/bin/backup" "$REPO_BASE/backup/backup.sh" || true
download "backup/restore.sh" "/usr/bin/restore" "$REPO_BASE/backup/restore.sh" || true

# Set backup rclone (jika perlu)
wget -q "$REPO_BASE/backup/set-br.sh" -O /root/set-br.sh && chmod +x /root/set-br.sh && /root/set-br.sh >/dev/null 2>&1 || true

info "Kemas kini fail selesai."

# Opsyen: pasang semula UDP & SlowDNS (ikut behavior lama skrip update)
info "Memasang semula UDP-Custom & SlowDNS (jika internet OK)..."
wget -q "$REPO_BASE/udp/udp.sh" -O /root/udp.sh && bash /root/udp.sh >/dev/null 2>&1 || true

# SlowDNS (guna skrip dalam repo ini)
wget -q "$REPO_BASE/SLDNS/install-sldns" -O /root/install-sldns && chmod +x /root/install-sldns && /root/install-sldns >/dev/null 2>&1 || true

info "Selesai. Anda boleh jalankan 'menu' untuk semak."
exit 0
