#!/bin/bash
# setup.sh - Autoscript VPN (Ubuntu 22.04+)
# Repo: Budaxcomel/v4

REPO_BASE="https://raw.githubusercontent.com/Budaxcomel/v4/main"

dateFromServer=$(curl -fsI https://google.com/ 2>/dev/null | grep -i '^date:' | sed -e 's/Date: //I' | tr -d '\r')
if [[ -n "$dateFromServer" ]]; then
  biji=$(date +"%Y-%m-%d" -d "$dateFromServer" 2>/dev/null)
else
  biji=$(date +"%Y-%m-%d")
fi

clear
red='\e[1;31m'
green='\e[1;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
NC='\e[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

cd /root

# Semak root
if [ "${EUID}" -ne 0 ]; then
  echo -e "${red}Sila jalankan skrip ini sebagai root.${NC}"
  exit 1
fi

# Semak virtualisasi (OpenVZ tak disokong)
if [ "$(systemd-detect-virt 2>/dev/null)" = "openvz" ]; then
  echo -e "${red}OpenVZ tidak disokong.${NC}"
  exit 1
fi

# Semak OS (cadangan Ubuntu 22.04+)
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "${ID:-}" == "ubuntu" && -n "${VERSION_ID:-}" ]]; then
    if command -v dpkg >/dev/null 2>&1 && dpkg --compare-versions "${VERSION_ID}" lt "22.04"; then
      echo -e "${yell}[AMARAN]${NC} Skrip ini disyorkan untuk Ubuntu 22.04 ke atas. Versi anda: Ubuntu ${VERSION_ID}"
      sleep 2
    fi
  fi
fi

# Betulkan /etc/hosts jika perlu
localip=$(hostname -I | awk '{print $1}')
hst=$(hostname)
dart=$(awk -v h="$hst" '$2==h {print $2}' /etc/hosts | head -n1)
if [[ "$hst" != "$dart" ]]; then
  echo "$localip $hst" >> /etc/hosts
fi

mkdir -p /etc/xray /etc/v2ray
touch /etc/xray/domain /etc/v2ray/domain /etc/xray/scdomain /etc/v2ray/scdomain

echo -e "[ ${tyblue}NOTA${NC} ] Sebelum mula..."
sleep 1
echo -e "[ ${tyblue}NOTA${NC} ] Saya perlu semak linux-headers dahulu."
sleep 1
echo -e "[ ${green}INFO${NC} ] Semakan linux-headers"
sleep 1

totet=$(uname -r)
REQUIRED_PKG="linux-headers-$totet"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$REQUIRED_PKG" 2>/dev/null | grep -q "install ok installed" && echo "ok" || true)

if [[ -z "$PKG_OK" ]]; then
  echo -e "[ ${yell}AMARAN${NC} ] $REQUIRED_PKG belum dipasang. Cuba pasang..."
  apt-get update -y
  apt-get --yes install "$REQUIRED_PKG" || true
  echo -e "\n[ ${tyblue}NOTA${NC} ] Jika masih ralat, cuba langkah ini:"
  echo -e "  1) apt update -y"
  echo -e "  2) apt upgrade -y"
  echo -e "  3) apt dist-upgrade -y"
  echo -e "  4) reboot"
  echo -e "Kemudian jalankan setup.sh semula."
  read -rp "Tekan Enter untuk teruskan..." _
else
  echo -e "[ ${green}INFO${NC} ] linux-headers sudah dipasang."
fi

ReqPKG="linux-headers-$(uname -r)"
if ! dpkg -s "$ReqPKG" >/dev/null 2>&1; then
  rm -f /root/setup.sh >/dev/null 2>&1 || true
  exit 1
fi

secs_to_human() {
  echo "Masa pemasangan : $(( ${1} / 3600 )) jam $(( (${1} / 60) % 60 )) minit $(( ${1} % 60 )) saat"
}
start=$(date +%s)

ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# Bersihkan .profile sementara (elak menu auto-run semasa install)
cat > /root/.profile << 'END'
# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
mesg n || true
clear
END
chmod 644 /root/.profile

echo -e "[ ${green}INFO${NC} ] Menyediakan fail pemasangan..."
apt-get update -y >/dev/null 2>&1
apt-get install -y git curl wget ca-certificates >/dev/null 2>&1
# Python untuk Ubuntu 22.04+ (python2 tiada)
apt-get install -y python3 python3-pip python-is-python3 >/dev/null 2>&1

echo -e "[ ${green}INFO${NC} ] Fail pemasangan sedia."
sleep 1
echo -ne "[ ${green}INFO${NC} ] Semak kebenaran : "

mkdir -p /var/lib/SIJA >/dev/null 2>&1
echo "IP=" >> /var/lib/SIJA/ipvps.conf

echo ""
# tools.sh (keperluan asas + keserasian)
wget -q "$REPO_BASE/tools.sh" -O /root/tools.sh
chmod +x /root/tools.sh
bash /root/tools.sh
rm -f /root/tools.sh
clear

yellow "Masukkan domain (untuk VMess/VLESS/Trojan dan sijil SSL)"
echo ""

pp=""
while [[ -z "$pp" ]]; do
  read -rp "Masukkan domain anda (contoh: vpn.example.com): " pp
  pp="${pp// /}"
  if [[ -z "$pp" ]]; then
    echo -e "${yell}Domain tidak boleh kosong. Sila cuba lagi.${NC}"
  fi
done

echo "$pp" > /root/scdomain
echo "$pp" > /etc/xray/scdomain
echo "$pp" > /etc/xray/domain
echo "$pp" > /etc/v2ray/domain
echo "$pp" > /root/domain
echo "IP=$pp" > /var/lib/SIJA/ipvps.conf

sleep 1

# Install SSH/WS
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${green}      Pasang SSH / WS${NC}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sleep 1
clear
wget -q "$REPO_BASE/ssh/ssh-vpn.sh" -O /root/ssh-vpn.sh
chmod +x /root/ssh-vpn.sh
bash /root/ssh-vpn.sh

# Install XRAY
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${green}          Pasang XRAY${NC}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sleep 1
clear
wget -q "$REPO_BASE/xray/ins-xray.sh" -O /root/ins-xray.sh
chmod +x /root/ins-xray.sh
bash /root/ins-xray.sh

# Install SSHWS (Dropbear WS + Stunnel WS)
wget -q "$REPO_BASE/sshws/insshws.sh" -O /root/insshws.sh
chmod +x /root/insshws.sh
bash /root/insshws.sh
clear

# Install SlowDNS (kekal seperti asal)
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${green}          Pasang SlowDNS${NC}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sleep 1
clear
wget -q "https://raw.githubusercontent.com/Andyvpn/Autoscript-by-azi/main/autoscript-ssh-slowdns-main/slowdns.sh" -O /root/slowdns.sh
chmod +x /root/slowdns.sh
bash /root/slowdns.sh
clear

# Install UDP-Custom
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${green}          Pasang UDP-Custom${NC}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sleep 1
clear
wget -q "$REPO_BASE/udp/udp.sh" -O /root/udp.sh
bash /root/udp.sh
clear

# Set .profile untuk terus buka menu selepas login
cat > /root/.profile << 'END'
# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
mesg n || true
clear
menu
END
chmod 644 /root/.profile

# Bersihkan log lama jika ada
rm -f /root/log-install.txt >/dev/null 2>&1 || true
rm -f /etc/afak.conf >/dev/null 2>&1 || true

if [ ! -f "/etc/log-create-user.log" ]; then
  echo "Log Semua Akaun" > /etc/log-create-user.log
fi

history -c

# Autoreboot hour (default 0 jika fail)
aureb=$(cat /home/re_otm 2>/dev/null || echo 0)
b=11
if [[ "$aureb" =~ ^[0-9]+$ ]] && [ "$aureb" -gt $b ]; then
  gg="PM"
else
  gg="AM"
fi

curl -sS ifconfig.me > /etc/myipvps 2>/dev/null || true

echo " "
echo "=====================-[ IMMANVPN PREMIUM ]-===================="
echo ""
echo "   >>> Servis & Port"  | tee -a /root/log-install.txt
echo "   - OpenSSH               : 22"  | tee -a /root/log-install.txt
echo "   - SSH Websocket         : 80 [ON]" | tee -a /root/log-install.txt
echo "   - SSH SSL Websocket     : 443" | tee -a /root/log-install.txt
echo "   - Stunnel4              : 447, 777" | tee -a /root/log-install.txt
echo "   - Dropbear              : 109, 143" | tee -a /root/log-install.txt
echo "   - Badvpn                : 7100-7900" | tee -a /root/log-install.txt
echo "   - Nginx                 : 81" | tee -a /root/log-install.txt
echo "   - VMess TLS             : 443" | tee -a /root/log-install.txt
echo "   - VMess Tanpa TLS       : 80" | tee -a /root/log-install.txt
echo "   - VLESS TLS             : 443" | tee -a /root/log-install.txt
echo "   - VLESS Tanpa TLS       : 80" | tee -a /root/log-install.txt
echo "   - Trojan GRPC           : 443" | tee -a /root/log-install.txt
echo "   - Trojan WS             : 443" | tee -a /root/log-install.txt
echo "   - Trojan GO             : 443" | tee -a /root/log-install.txt
echo "   - SlowDNS               : 443,80,8080,53,5300" | tee -a /root/log-install.txt
echo ""  | tee -a /root/log-install.txt
echo "   >>> Maklumat Server & Ciri"  | tee -a /root/log-install.txt
echo "   - Timezone              : Asia/Kuala_Lumpur (GMT +8)"  | tee -a /root/log-install.txt
echo "   - Fail2Ban              : [ON]"  | tee -a /root/log-install.txt
echo "   - Dflate                : [ON]"  | tee -a /root/log-install.txt
echo "   - IPTables              : [ON]"  | tee -a /root/log-install.txt
echo "   - Auto-Reboot           : [ON]"  | tee -a /root/log-install.txt
echo "   - IPv6                  : [OFF]"  | tee -a /root/log-install.txt
echo "   - AutoReboot pada       : $aureb:00 $gg (GMT +8)" | tee -a /root/log-install.txt
echo "   - AutoKill Multi Login" | tee -a /root/log-install.txt
echo "   - Auto Delete Akaun Tamat Tempoh" | tee -a /root/log-install.txt
echo "   - Skrip automatik sepenuhnya" | tee -a /root/log-install.txt
echo "" | tee -a /root/log-install.txt
echo "===============-[ Script By IMMANVPN ]-==============="
echo "" | tee -a /root/log-install.txt

rm -f /root/setup.sh /root/ins-xray.sh /root/insshws.sh /root/ssh-vpn.sh /root/slowdns.sh /root/udp.sh >/dev/null 2>&1 || true
secs_to_human "$(($(date +%s) - ${start}))" | tee -a /root/log-install.txt

echo -e "\n"
read -n 1 -s -r -p "Tekan Enter untuk reboot..."
reboot
