#/bin/sh
multistrap -f multistrap.conf
cp /etc/resolv.conf /port/rv64-port/etc/resolv.conf
chroot /port/rv64-port /multistrap_config.sh


