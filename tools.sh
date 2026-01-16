#!/bin/bash
# tools.sh - Keperluan asas, keserasian & semakan permission (Ubuntu 22.04+)
# Projek: Budaxcomel/v4
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Warna
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
NC='\e[0m'

info()  { echo -e "[ ${GREEN}INFO${NC} ] $*"; }
warn()  { echo -e "[ ${YELLOW}AMARAN${NC} ] $*"; }
error() { echo -e "[ ${RED}RALAT${NC} ] $*"; }

get_server_date() {
  # Cuba ambil tarikh dari header Date (google) supaya sukar dimanipulasi
  local date_hdr
  date_hdr=$(curl -fsI https://google.com/ 2>/dev/null | grep -i '^date:' | sed -e 's/Date: //I' | tr -d '\r' || true)
  if [[ -n "$date_hdr" ]]; then
    date -d "$date_hdr" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
  else
    date +%Y-%m-%d
  fi
}

# Parse format permission yang guna token '###'
# Contoh ipmini:
#   ### nama tanggal ip ON ### immanvpn 2050-07-25 103.91.194.216 ON ...
# Contoh izin:
#   #vps ### abgdinur 2064-10-30 152.42.224.43 ...
extract_expiry_from_text() {
  local ip="$1"
  awk -v ip="$ip" '
    {
      for (i=1; i<=NF; i++) {
        if ($i == "###") {
          name=$(i+1)
          expiry=$(i+2)
          ipaddr=$(i+3)
          status=$(i+4)
          if (ipaddr == ip) {
            print expiry
            exit
          }
        }
      }
    }
  '
}

check_permission() {
  local myip="$1"
  local today="$2"
  local perm_url="https://raw.githubusercontent.com/Budaxcomel/permission/main/ipmini"
  local izin_url="https://raw.githubusercontent.com/Budaxcomel/izinvps/ipuk/ip"

  local data exp

  data=$(curl -fsS "$perm_url" 2>/dev/null || true)
  data=$(echo "$data" | tr $'\r' ' ')
  exp=$(echo "$data" | extract_expiry_from_text "$myip")

  if [[ -z "$exp" ]]; then
    # Cuba fallback izin file
    data=$(curl -fsS "$izin_url" 2>/dev/null || true)
    data=$(echo "$data" | tr $'\r' ' ')
    exp=$(echo "$data" | extract_expiry_from_text "$myip")
  fi

  if [[ -z "$exp" ]]; then
    error "PERMISSION DENIED: IP $myip tidak dijumpai dalam senarai permission."
    error "Sila hubungi admin untuk aktifkan akses."
    exit 1
  fi

  # Banding tarikh dengan epoch
  local today_s exp_s
  today_s=$(date -d "$today" +%s 2>/dev/null || echo 0)
  exp_s=$(date -d "$exp" +%s 2>/dev/null || echo 0)

  if [[ "$today_s" -ge "$exp_s" ]]; then
    error "PERMISSION DENIED: akses untuk IP $myip telah tamat pada $exp."
    error "Sila hubungi admin untuk sambung tempoh."
    exit 1
  fi

  info "Permission Accepted (Tamat: $exp)"
}

# Semak OS
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi

if [[ "${ID:-}" == "ubuntu" ]]; then
  if command -v dpkg >/dev/null 2>&1 && [[ -n "${VERSION_ID:-}" ]]; then
    if dpkg --compare-versions "${VERSION_ID}" lt "22.04"; then
      warn "Skrip ini disyorkan untuk Ubuntu 22.04 ke atas. Versi dikesan: Ubuntu ${VERSION_ID}"
    else
      info "OS dikesan: Ubuntu ${VERSION_ID}"
    fi
  fi
else
  warn "OS dikesan: ${PRETTY_NAME:-unknown}. Skrip ini dioptimumkan untuk Ubuntu 22.04+."
fi

# Permission
MYIP=$(curl -fsS ipinfo.io/ip 2>/dev/null || curl -fsS ifconfig.me 2>/dev/null || curl -fsS api.ipify.org 2>/dev/null || wget -qO- ipinfo.io/ip 2>/dev/null || echo "")
TODAY=$(get_server_date)

if [[ -z "$MYIP" ]]; then
  error "Tidak dapat kesan IP public. Sila semak internet VPS anda."
  exit 1
fi
check_permission "$MYIP" "$TODAY"

# Kemas kini apt
info "Mengemas kini senarai pakej..."
apt-get update -y

info "Memasang pakej keperluan (asas autoscript)..."
# Elak prompt iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections || true
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections || true

apt-get install -y --no-install-recommends \
  ca-certificates curl wget gnupg lsb-release sudo \
  jq unzip zip \
  cron net-tools lsof \
  iptables iptables-persistent netfilter-persistent \
  vnstat \
  python3 python3-pip python-is-python3 \
  socat openssl pwgen bc \
  tzdata

# Opsyenal: bantu menu SSH-WS (node/tmux)
apt-get install -y --no-install-recommends tmux nodejs || true

# Matikan IPv6 secara kekal (selari dengan arahan install)
info "Menyahaktifkan IPv6 (kekal)..."
cat >/etc/sysctl.d/99-disable-ipv6.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
sysctl --system >/dev/null 2>&1 || true

# Pastikan direktori asas wujud
mkdir -p /etc/xray /etc/v2ray /etc/bot /etc/per /etc/perlogin /var/lib/SIJA || true

# Hidupkan vnStat jika ada
systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable vnstat >/dev/null 2>&1 || true
systemctl restart vnstat >/dev/null 2>&1 || true

info "tools.sh selesai."
