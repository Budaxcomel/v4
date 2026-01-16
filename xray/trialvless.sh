#!/bin/bash

domain=$(cat /etc/xray/domain)
TIMES="10"

CHATID=""
KEY=""
URL=""
TELEGRAM_OK=0

# Telegram adalah pilihan (optional). Kalau /etc/id atau /etc/token tiada,
# skrip tetap berjalan tanpa ralat dan tanpa hantar notifikasi.
if [[ -s /etc/id && -s /etc/token ]]; then
  CHATID="$(cat /etc/id)"
  KEY="$(cat /etc/token)"
  URL="https://api.telegram.org/bot${KEY}/sendMessage"
  TELEGRAM_OK=1
fi

# Ambil port dari /root/log-install.txt (label ikut output log semasa).
tls="$(grep -w "VLESS TLS" /root/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"
none="$(grep -w "VLESS Tanpa TLS" /root/log-install.txt 2>/dev/null | cut -d: -f2 | sed 's/ //g')"

# fallback kalau parsing gagal
[[ -z "$tls" ]] && tls=443
[[ -z "$none" ]] && none=80
user=trial$(</dev/urandom tr -dc X-Z0-9 | head -c4)
uuid=$(cat /proc/sys/kernel/random/uuid)

read -p "Tempoh tamat (hari): " masaaktif
[[ -z "$masaaktif" ]] && masaaktif=1
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
sed -i '/#vless$/a\#& '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#& '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
vlesslink1="vless://${uuid}@${domain}:$tls?path=/vless&security=tls&encryption=none&type=ws#${user}"
vlesslink2="vless://${uuid}@${domain}:$none?path=/vless&encryption=none&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:$tls?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${user}"
systemctl restart xray
clear
vless1="$(echo $vlesslink1 | base64 -w 0)"
vless2="$(echo $vlesslink2 | base64 -w 0)"
vless3="$(echo $vlesslink3 | base64 -w 0)"

TEXT="
<code>◇━━━━━━━━━━━━━━━━━◇</code>
<code>  Akaun Vless (Trial)</code>
<code>◇━━━━━━━━━━━━━━━━━◇</code>
<code>Remarks      : </code> <code>${user}</code>
<code>Domain       : </code> <code>${domain}</code>
<code>Port TLS     : </code> <code>${tls}</code>
<code>Port NTLS    : </code> <code>${none}</code>
<code>Port GRPC    : </code> <code>${tls}</code>
<code>User ID      : </code> <code>${uuid}</code>
<code>AlterId      : 0</code>
<code>Security     : auto</code>
<code>Network      : WS or gRPC</code>
<code>Path vless   : </code> <code>/vless</code>
<code>ServiceName  : </code> <code>/vless-grpc</code>
<code>Tamat pada : </code> <code>${exp}</code>
<code>◇━━━━━━━━━━━━━━━━━◇</code>
<code>Link TLS     :</code> 
<code>${vless1}</code>
<code>◇━━━━━━━━━━━━━━━━━◇</code>
<code>Link NTLS    :</code> 
<code>${vless2}</code>
<code>◇━━━━━━━━━━━━━━━━━◇</code>
<code>Link GRPC    :</code> 
<code>${vless3}</code>
<code>◇━━━━━━━━━━━━━━━━━◇</code>
"

if [[ "$TELEGRAM_OK" = "1" ]]; then
  curl -s --max-time "$TIMES" -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" "$URL" >/dev/null
fi

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[40;1;37m        Trial Xray/Vless        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Remarks        : ${user}"
echo -e "Domain         : ${domain}"
echo -e "port TLS       : $tls"
echo -e "port none TLS  : $none"
echo -e "id             : ${uuid}"
echo -e "Encryption     : none"
echo -e "Network        : ws"
echo -e "Path           : /vless"
echo -e "Path           : vless-grpc"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Link TLS       : ${vlesslink1}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Link none TLS  : ${vlesslink2}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Link GRPC      : ${vlesslink3}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Expired On     : $exp"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa-apa kekunci untuk kembali ke menu"

menu
