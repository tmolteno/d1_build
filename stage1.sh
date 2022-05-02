# Update package information
apt-get update
# Set up basic networking
cat >>/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
# Set root password
passwd
# Disable the getty on hvc0 as hvc0 and ttyS0 share the same console device in qemu.
ln -sf /dev/null /etc/systemd/system/serial-getty@hvc0.service
# Install kernel and bootloader infrastructure
apt-get install -y linux-image-riscv64 u-boot-menu
# Install and configure ntp tools
apt-get install -y openntpd ntpdate
sed -i 's/^DAEMON_OPTS="/DAEMON_OPTS="-s /' /etc/default/openntpd
# Configure syslinux-style boot menu
cat >>/etc/default/u-boot <<EOF
U_BOOT_PARAMETERS="rw noquiet root=/dev/vda1"
U_BOOT_FDT_DIR="noexist"
EOF
u-boot-update
exit
