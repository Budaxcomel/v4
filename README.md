# Autoscript VPN v4 (Ubuntu 22.04+)

Repositori ini ialah autoscript untuk pemasangan servis VPN/Proxy (SSH/WS, XRAY, SlowDNS, UDP-Custom) **serta panel Bot Telegram**.

> Nota penting: Skrip ini ada **semakan permission (IP whitelist + tarikh tamat)**. Jika IP VPS anda tidak tersenarai atau tempoh sudah tamat, pemasangan/menu akan **ditolak**.

---

## Keperluan

- **Ubuntu 22.04 / 24.04 (disyorkan)**  
- Akses **root**
- VPS baharu (disyorkan supaya tiada konflik servis)
- **Domain** yang sudah pointing ke IP VPS (A record)
  - Pastikan **port 80 & 443 terbuka** untuk pengeluaran SSL (ACME)

---

## Cara Install Autoscript

⚠️ **Jangan ubah cara install di bawah (ikut arahan asal).**

```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl unzip && wget https://raw.githubusercontent.com/Budaxcomel/v4/main/setup.sh && chmod +x setup.sh && sed -i -e 's/$//' setup.sh && screen -S setup ./setup.sh
```

Semasa pemasangan, anda akan diminta masukkan:

- **Domain** (contoh: `vpn.example.com`)

Selepas siap, skrip akan minta reboot dan VPS akan **reboot automatik**.

---

## Selepas Reboot

1. Login semula VPS anda (SSH).
2. Menu biasanya akan keluar automatik. Jika tidak keluar, jalankan:

```bash
menu
```

---

## Cara Install Bot Telegram (Panel Bot)

Bot panel diurus melalui command `bot`.

### Cara paling mudah (melalui menu)
Dalam menu utama, pilih:
- **[10] INSTALL BOT** (atau ikut label yang ada dalam menu)

### Cara manual (terus di terminal)
```bash
bot
```

Dalam panel bot, pilih:
- **1) Pasang / Kemas kini bot**

Kemudian masukkan:
- **Token bot** (ambil dari `@BotFather`)
- **Telegram ID admin**
  - Boleh dapatkan menggunakan `@MissRose_bot` → taip `/info`

Selepas siap:
- Servis `adminbot` akan dipasang sebagai **systemd service**
- Watchdog cron akan cuba pastikan bot sentiasa hidup

Semak status bot:
```bash
systemctl status adminbot
```

Restart bot:
```bash
systemctl restart adminbot
```

Lihat log:
```bash
journalctl -u adminbot -n 100 --no-pager
```

---

## Backup / Update (Cara Asal)

### Update ringkas (menu + backup + bot)
```bash
wget https://raw.githubusercontent.com/Budaxcomel/v4/main/update.sh && chmod +x update.sh && ./update.sh
```

### Update penuh (fail /usr/bin + pasang semula UDP & SlowDNS)
```bash
wget https://raw.githubusercontent.com/Budaxcomel/v4/main/up.sh && chmod +x up.sh && ./up.sh
```

---

## Troubleshooting

### 1) `PERMISSION DENIED`
Maksudnya IP VPS anda tidak tersenarai atau sudah tamat tempoh.

Semakan dibuat dari fail permission:
- `https://raw.githubusercontent.com/Budaxcomel/permission/main/ipmini`
- (fallback) `https://raw.githubusercontent.com/Budaxcomel/izinvps/ipuk/ip`

Pastikan IP VPS anda berada dalam senarai dan tarikh belum tamat.

---

### 2) SSL/ACME gagal (sijil tak keluar)
Perkara biasa yang perlu disemak:
- Domain **betul-betul** pointing ke IP VPS (A record)
- Jika guna Cloudflare, pastikan mode **DNS only** (awan kelabu) semasa issue sijil
- Pastikan **port 80** tidak disekat (ACME guna port 80 untuk validasi)

---

### 3) Menu tak keluar selepas login
Jalankan manual:
```bash
menu
```

Jika masih tak keluar, semak fail:
- `/root/.profile`

---

### 4) Semak servis penting
```bash
systemctl status nginx --no-pager
systemctl status xray --no-pager
systemctl status ws-stunnel --no-pager
systemctl status ws-dropbear --no-pager
vnstat --version
```

---

## Nota Keselamatan

- Jalankan pada VPS yang anda miliki/urus.
- Jangan kongsi **Token Bot** anda kepada sesiapa.
- Jika token bot sudah terdedah, **revoke/regenerate** di `@BotFather`.

---

## Kredit

- Script asal & penambahbaikan: **IMMANVPN / Budaxcomel**
