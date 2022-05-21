#!/bin/sh
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
dpkg --configure -a
mount proc -t proc /proc
dpkg --configure -a
umount /proc
# Needed because we get permissions problems for some reason
chmod 0666 /dev/null
#
# Change Root Password
# sed -i -e "s/^root:[^:]\+:/root:`openssl passwd -1 -salt root licheerv`:/" /etc/shadow
usermod --password $(echo licheerv | openssl passwd -1 -stdin) root
#
# Add a new user rv:lichee
#
mkdir -p /home/rv
useradd --password dummy \
    -G cdrom,floppy,sudo,audio,dip,video,plugdev \
    --home-dir /home/rv --shell /bin/bash rv

chown rv:rv /home/rv
# sed -i -e "s/^rv:[^:]\+:/rv:`openssl passwd -1 -salt rv lichee`:/" /etc/shadow
usermod --password $(echo lichee | openssl passwd -1 -stdin) rv

# This is needed
systemctl enable systemd-resolved.service

apt update
apt upgrade
