#!/bin/bash
# update.sh - Kemas kini fail utama (menu + backup + bot)
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

info() { echo -e " [INFO] $*"; }

info "Memuat turun fail kemas kini..."

# Padam fail lama (jika ada)
rm -f set-br menu-bckp menu-backup backup restore >/dev/null 2>&1 || true

# Muat turun semula
wget -q https://raw.githubusercontent.com/Budaxcomel/v4/main/backup/set-br.sh -O /root/set-br.sh
chmod +x /root/set-br.sh
/root/set-br.sh

wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/Budaxcomel/v4/main/menu/menu.sh"
chmod +x /usr/bin/menu

wget -q -O /usr/bin/menu-backup "https://raw.githubusercontent.com/Budaxcomel/v4/main/backup/menu-backup.sh"
chmod +x /usr/bin/menu-backup

wget -q -O /usr/bin/backup "https://raw.githubusercontent.com/Budaxcomel/v4/main/backup/backup.sh"
chmod +x /usr/bin/backup

wget -q -O /usr/bin/restore "https://raw.githubusercontent.com/Budaxcomel/v4/main/backup/restore.sh"
chmod +x /usr/bin/restore

# Bot panel
wget -q -O /usr/bin/bot "https://raw.githubusercontent.com/Budaxcomel/v4/main/bot.sh"
chmod +x /usr/bin/bot

info "Kemas kini berjaya."
sleep 1
exit 0
