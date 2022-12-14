#!/bin/sh
#
# Author. Tim Molteno tim@molteno.net
# (C) 2022.
# http://www.orangepi.org/Docs/Makingabootable.html

# Make Image the first parameter of this script is the directory containing all the files needed
# This is done to allow the script to be run outside of Docker for testing.
OUTPORT="$1"


KERNEL_TAG="$(echo "${KERNEL_TAG}" | tr '/' '_')"
IMG_NAME="${BOARD}_gcc_${GNU_TOOLS_TAG}_kernel_${KERNEL_TAG}.img"
IMG="${OUTPORT}/${IMG_NAME}"

echo "Creating Blank Image ${IMG}"

dd if=/dev/zero "of=${IMG}" bs=1M "count=${DISK_MB}"

# Setup Loopback device
LOOP="$(losetup -f --show "${IMG}" | cut -d'/' -f3)"
LOOPDEV="/dev/${LOOP}"
echo "Partitioning loopback device ${LOOPDEV}"


# dd if=/dev/zero of=${LOOPDEV} bs=1M count=200
parted -s -a optimal -- "${LOOPDEV}" mklabel gpt
parted -s -a optimal -- "${LOOPDEV}" mkpart primary ext2 40MiB 100MiB
parted -s -a optimal -- "${LOOPDEV}" mkpart primary ext4 100MiB -1GiB
parted -s -a optimal -- "${LOOPDEV}" mkpart primary linux-swap -1GiB 100%

kpartx -av "${LOOPDEV}"

mkfs.ext2 "/dev/mapper/${LOOP}p1"
mkfs.ext4 "/dev/mapper/${LOOP}p2"
mkswap "/dev/mapper/${LOOP}p3"

# Burn U-boot
echo "Burning u-boot to ${LOOPDEV}"

# Copy files https://linux-sunxi.org/Allwinner_Nezha
dd if=/builder/u-boot-sunxi-with-spl.bin "of=${LOOPDEV}" bs=1024 seek=128

# Copy Files, first the boot partition
echo "Mounting  partitions ${LOOPDEV}"
BOOTPOINT=/sdcard_boot

mkdir -p "${BOOTPOINT}"
mount "/dev/mapper/${LOOP}p1" "${BOOTPOINT}"

# Boot partition
cp /builder/Image.gz "${BOOTPOINT}/"

# install U-Boot
cp /builder/boot.scr "${BOOTPOINT}/"
cp /builder/ov_lichee_rv_mini_lcd.dtb "${BOOTPOINT}/"

umount "${BOOTPOINT}"
rm -rf "${BOOTPOINT}"


# Now create the root partition
MNTPOINT=/sdcard_rootfs
mkdir -p "${MNTPOINT}"
mount "/dev/mapper/${LOOP}p2" "${MNTPOINT}"

# Copy the rootfs
cp -a /builder/rv64-port/* "${MNTPOINT}"

# Set up the rootfs
chroot "${MNTPOINT}" /bin/sh /setup_rootfs.sh
rm "${MNTPOINT}/setup_rootfs.sh"

# Set up fstab
cat >> "${MNTPOINT}/etc/fstab" <<EOF
# <device>        <dir>        <type>        <options>            <dump> <pass>
/dev/mmcblk0p1    /boot        ext2          rw,defaults,noatime,discard  1      1
/dev/mmcblk0p2    /            ext4          rw,defaults,noatime,discard  1      1
/dev/mmcblk0p3    none         swap          sw,discard                   0      0
EOF

# Clean Up
echo "Cleaning Up..."
umount "${MNTPOINT}"
rm -rf "${MNTPOINT}"

kpartx -d "${LOOPDEV}"
losetup -d "${LOOPDEV}"

# Now compress the image
echo "Compressing the image: ${IMG}"

(cd "${OUTPORT}" && xz -T0 -9 "${IMG}")
