#!/bin/bash
# install-bot.sh - Pemasangan bot Telegram (adminbot) melalui bot.sh
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Sila jalankan sebagai root."
  exit 1
fi

# Pastikan /usr/bin/bot wujud (bot panel)
if [[ ! -x /usr/bin/bot ]]; then
  wget -q -O /usr/bin/bot https://raw.githubusercontent.com/Budaxcomel/v4/main/bot.sh
  chmod +x /usr/bin/bot
fi

/usr/bin/bot --install

# Kembali ke menu jika wujud
if command -v menu >/dev/null 2>&1; then
  read -n 1 -s -r -p "Tekan apa-apa kekunci untuk kembali ke menu..."
  menu
fi
