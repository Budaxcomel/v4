#!/bin/bash

# Fungsi untuk mengirim notifikasi menggunakan Telegram Bot API
send_notification() {
    chat_id="1358956715"
    token="5517879910:AAEs5k9mfCzbw2LBIA63P3FnH3CoVq9GDCE"
    message="$1"

    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d text="$message" \
        -d parse_mode="HTML"
}

# Instalasi paket-paket yang diperlukan
apt-get update
apt-get install -y package1 package2 package3

# Mengirim notifikasi ke Telegram saat instalasi selesai
send_notification "Instalasi bash full selesai."

# Jalankan perintah-perintah lain yang diperlukan setelah instalasi
