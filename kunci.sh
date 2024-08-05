#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
###########- COLOR CODE -##############
echo -e " [INFO] Downloading Update File"
sleep 2
# hapus menu
rm -rf user-lock
rm -rf user-unlock
# download script
cd /usr/bin
# menu
wget -O user-lock "https://raw.githubusercontent.com/Andyyuda/v4/main/ssh/user-lock.sh"
wget -O user-unlock "https://raw.githubusercontent.com/Andyyuda/v4/main/ssh/user-unlock.sh"
# chomad
wget -q -O /usr/bin/user-lock "https://raw.githubusercontent.com/Andyyuda/v4/main/ssh/user-lock.sh" && chmod +x /usr/bin/user-lock
wget -q -O /usr/bin/user-unlock "https://raw.githubusercontent.com/Andyyuda/v4/main/ssh/user-unlock.sh" && chmod +x /usr/bin/user-unlock
echo -e " [INFO] Update Successfully"
sleep 2
exit
