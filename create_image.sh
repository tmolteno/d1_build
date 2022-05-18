#!/bin/sh
#
# Author. Tim Molteno tim@molteno.net
# (C) 2022.
# http://www.orangepi.org/Docs/Makingabootable.html

# Make Image the first parameter of this script is the directory containing all the files needed
# This is done to allow the script to be run outside of Docker for testing.
OUTPORT=$1

IMG=${OUTPORT}/licheerv.img

echo "Creating Blank Image ${IMG}"

dd if=/dev/zero of=${IMG} bs=1M count=3500

# Setup Loopback device
LOOP=`losetup -f --show ${IMG} | cut -d'/' -f3`
LOOPDEV=/dev/${LOOP}
echo "Partitioning loopback device ${LOOPDEV}"


dd if=/dev/zero of=${LOOPDEV} bs=1M count=200
parted -s -a optimal -- ${LOOPDEV} mklabel gpt
parted -s -a optimal -- ${LOOPDEV} mkpart primary ext2 40MiB 500MiB
parted -s -a optimal -- ${LOOPDEV} mkpart primary ext4 540MiB -1GiB
parted -s -a optimal -- ${LOOPDEV} mkpart primary linux-swap -1GiB 100%

kpartx -av ${LOOPDEV}

mkfs.ext2 /dev/mapper/${LOOP}p1
mkfs.ext4 /dev/mapper/${LOOP}p2
mkswap /dev/mapper/${LOOP}p3

# Burn U-boot
echo "Burning u-boot to ${LOOPDEV}"

dd if=${OUTPORT}/boot0_sdcard_sun20iw1p1.bin of=${LOOPDEV} bs=8192 seek=16

# Copy files https://linux-sunxi.org/Allwinner_Nezha
dd if=${OUTPORT}/u-boot.toc1 of=${LOOPDEV} bs=512 seek=32800


# Copy Files, first the boot partition
echo "Mounting  partitions ${LOOPDEV}"
BOOTPOINT=/sdcard_boot

mkdir -p ${BOOTPOINT}
mount /dev/mapper/${LOOP}p1 ${BOOTPOINT}

# Boot partition
cp ${OUTPORT}/Image.gz "${BOOTPOINT}/"
cp ${OUTPORT}/Image "${BOOTPOINT}/"
# install U-Boot
cp ${OUTPORT}/boot.scr "${BOOTPOINT}/"

umount ${BOOTPOINT}
rm -rf ${BOOTPOINT}


# Now create the root partition
MNTPOINT=/sdcard_rootfs
mkdir -p ${MNTPOINT}
mount /dev/mapper/${LOOP}p2 ${MNTPOINT}

# Copy the rootfs
cp -a ${OUTPORT}/rv64-port/* ${MNTPOINT}


# install kernel and modules

ls -l /build

cd /build/linux-build && make ARCH=riscv INSTALL_MOD_PATH=${MNTPOINT} modules_install

MODDIR=`ls ${MNTPOINT}/lib/modules/`
echo "Creating wireless module in ${MODDIR}"
install -v -D -p -m 644 /build/8723ds.ko ${MNTPOINT}/lib/modules/${MODDIR}/kernel/drivers/net/wireless/8723ds.ko

rm "${MNTPOINT}/lib/modules/${MODDIR}/build"
rm "${MNTPOINT}/lib/modules/${MODDIR}/source"

depmod -a -b "${MNTPOINT}" "${MODDIR}"
echo '8723ds' >> "${MNTPOINT}/etc/modules"


# Set up fstab
# Add the following line to enable swap

cat >> "${MNTPOINT}/etc/fstab" <<EOF
# <device>        <dir>        <type>        <options>            <dump> <pass>
/dev/mmcblk0p1    /boot        ext2          rw,defaults,noatime  1      1
/dev/mmcblk0p2    /            ext4          rw,defaults,noatime  1      1
/dev/mmcblk0p3    none         swap          sw                   0      0
EOF

# Clean Up
umount ${MNTPOINT}
rm -rf ${MNTPOINT}

kpartx -d ${LOOPDEV}
losetup -d ${LOOPDEV}
