#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WebSocket TCP forwarder (Python 3)
Asal: IMMANVPN (versi lama Python2). Dikemas kini untuk Ubuntu 22.04+.

Ciri serasi dengan skrip asal:
- Header sokongan: X-Real-Host, X-Pass, X-Split
- Jika X-Real-Host tiada, akan guna DEFAULT_HOST
- Jika PASS kosong, hanya benarkan sambungan ke 127.0.0.1/localhost
"""

import socket
import threading
import select
import sys
import time
from typing import Tuple, Optional

LISTENING_ADDR = "0.0.0.0"
DEFAULT_LISTEN_PORT = 2082

PASS = ""  # Letak kata laluan jika mahu paksa header X-Pass

BUFLEN = 1024 * 64
IDLE_TIMEOUT = 60  # saat
DEFAULT_HOST = "127.0.0.1:88"

RESPONSE = (
    "HTTP/1.1 101 Switching Protocols\r\n"
    "Connection: Upgrade\r\n"
    "Upgrade: websocket\r\n"
    "Content-Length: 104857600000\r\n"
    "\r\n"
).encode("utf-8")


def _parse_target(value: str, fallback: str) -> Tuple[str, int]:
    """Parse host[:port]."""
    value = (value or "").strip()
    if not value:
        value = fallback

    # Fallback parse
    fb_host, fb_port = fallback.split(":") if ":" in fallback else (fallback, "80")

    if ":" in value:
        host, port_s = value.rsplit(":", 1)
        host = host.strip() or fb_host
        try:
            port = int(port_s.strip())
        except ValueError:
            port = int(fb_port)
    else:
        host = value
        port = int(fb_port)

    return host, port


def _is_local(host: str) -> bool:
    host_l = host.lower()
    return host_l in ("127.0.0.1", "localhost")


def _read_http_request(client: socket.socket) -> bytes:
    client.settimeout(3)
    data = b""
    try:
        while b"\r\n\r\n" not in data and len(data) < 8192:
            chunk = client.recv(BUFLEN)
            if not chunk:
                break
            data += chunk
            if len(chunk) < BUFLEN:
                break
    except Exception:
        pass
    finally:
        try:
            client.settimeout(None)
        except Exception:
            pass
    return data


def _parse_headers(raw: bytes) -> dict:
    headers = {}
    try:
        text = raw.decode("latin-1", errors="ignore")
    except Exception:
        return headers
    parts = text.split("\r\n")
    for line in parts[1:]:
        if not line or ":" not in line:
            continue
        k, v = line.split(":", 1)
        headers[k.strip()] = v.strip()
    return headers


def _handle_client(client: socket.socket, addr: Tuple[str, int]) -> None:
    target: Optional[socket.socket] = None
    try:
        raw = _read_http_request(client)
        headers = _parse_headers(raw)

        # 'X-Split' digunakan untuk buang payload awal (serasi skrip asal)
        if "X-Split" in headers:
            try:
                _ = client.recv(BUFLEN)
            except Exception:
                pass

        x_pass = headers.get("X-Pass", "")
        x_real_host = headers.get("X-Real-Host", "")

        host, port = _parse_target(x_real_host, DEFAULT_HOST)

        # Sekatan keselamatan (serasi skrip asal)
        if PASS:
            if x_pass != PASS:
                client.sendall(b"HTTP/1.1 403 Forbidden\r\n\r\n")
                return
        else:
            if not _is_local(host):
                client.sendall(b"HTTP/1.1 403 Forbidden\r\n\r\n")
                return

        target = socket.create_connection((host, port), timeout=5)
        client.sendall(RESPONSE)

        client.setblocking(False)
        target.setblocking(False)

        last = time.monotonic()
        sockets = [client, target]

        while True:
            r, _, e = select.select(sockets, [], sockets, 1)
            if e:
                break

            if r:
                for s in r:
                    try:
                        data = s.recv(BUFLEN)
                    except BlockingIOError:
                        continue
                    except Exception:
                        return

                    if not data:
                        return

                    if s is client:
                        try:
                            target.sendall(data)
                        except Exception:
                            return
                    else:
                        try:
                            client.sendall(data)
                        except Exception:
                            return

                    last = time.monotonic()

            if time.monotonic() - last > IDLE_TIMEOUT:
                break

    finally:
        try:
            if target is not None:
                target.close()
        except Exception:
            pass
        try:
            client.close()
        except Exception:
            pass


def main() -> int:
    port = DEFAULT_LISTEN_PORT
    if len(sys.argv) >= 2:
        try:
            port = int(sys.argv[1])
        except ValueError:
            port = DEFAULT_LISTEN_PORT

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTENING_ADDR, port))
    server.listen(200)

    while True:
        client, addr = server.accept()
        t = threading.Thread(target=_handle_client, args=(client, addr), daemon=True)
        t.start()


if __name__ == "__main__":
    raise SystemExit(main())
