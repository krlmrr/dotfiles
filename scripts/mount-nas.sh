#!/usr/bin/env bash
set -euo pipefail

SERVER=10.10.10.2
SHARE=media
MOUNTPOINT=/mnt/nas
CREDS=/etc/samba/credentials/nas
UID_N=1000
GID_N=1000

[ "$EUID" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

read -rp "NAS username: " NAS_USER
read -rsp "NAS password: " NAS_PASS; echo

install -d -m 700 /etc/samba/credentials
umask 077
cat > "$CREDS" <<EOF
username=$NAS_USER
password=$NAS_PASS
EOF
chmod 600 "$CREDS"
unset NAS_PASS

install -d -m 755 "$MOUNTPOINT"

cat > /etc/systemd/system/mnt-nas.mount <<EOF
[Unit]
Description=NAS $SHARE share
After=network-online.target tailscaled.service
Wants=network-online.target

[Mount]
What=//$SERVER/$SHARE
Where=$MOUNTPOINT
Type=cifs
Options=credentials=$CREDS,uid=$UID_N,gid=$GID_N,file_mode=0664,dir_mode=0775,iocharset=utf8,nofail,_netdev,noatime,cache=loose,actimeo=30
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/mnt-nas.automount <<EOF
[Unit]
Description=Automount NAS $SHARE share

[Automount]
Where=$MOUNTPOINT
TimeoutIdleSec=600

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mnt-nas.automount

echo
echo "Triggering mount..."
if ls "$MOUNTPOINT" >/dev/null 2>&1; then
  echo "OK: $MOUNTPOINT"
  findmnt "$MOUNTPOINT" || true
  ls -1 "$MOUNTPOINT" | head
else
  echo "FAILED. Diagnose with:  systemctl status mnt-nas.mount ; journalctl -u mnt-nas.mount -n 30"
  exit 1
fi
