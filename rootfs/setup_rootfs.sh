#!/bin/sh
#
#  Author: Tim Molteno tim@molteno.net
#  (c) 2022
#
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
/var/lib/dpkg/info/dash.preinst install
/var/lib/dpkg/info/base-passwd.preinst install
/var/lib/dpkg/info/sgml-base.preinst install
mkdir -p /etc/sgml
dpkg --configure -a
mount proc -t proc /proc
dpkg --configure -a
umount /proc
# Needed because we get permissions problems for some reason
chmod 0666 /dev/null

#
# Change root password to 'licheerv'
#
usermod --password "$(echo licheerv | openssl passwd -1 -stdin)" root

#
# Add a new user rv
#
mkdir -p /home/rv
useradd --password dummy \
    -G cdrom,floppy,sudo,audio,dip,video,plugdev \
    --home-dir /home/rv --shell /bin/bash rv
chown rv:rv /home/rv
# Set password to 'lichee'
usermod --password "$(echo lichee | openssl passwd -1 -stdin)" rv

# 
# Enable system services
#
systemctl enable systemd-resolved.service

#
# Clean apt cache on the system
#
apt-get clean
rm -rf /var/cache/*
find /var/lib/apt/lists -type f -not -name '*.gpg' -print0 | xargs -0 rm -f
find /var/log -type f -print0 | xargs -0 truncate --size=0
