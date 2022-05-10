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
echo "Using loopback device ${LOOPDEV}"

# Create partitions
# sfdisk ${LOOPDEV} < ${OUTPORT}/disk_layout.sfdisk
# kpartx -av ${LOOPDEV}
# mkfs.vfat /dev/mapper/${LOOP}p1
# mkfs.ext4 /dev/mapper/${LOOP}p2

dd if=/dev/zero of=${LOOPDEV} bs=1k count=1023 seek=1
parted -s -a optimal -- ${LOOPDEV} mklabel gpt
parted -s -a optimal -- ${LOOPDEV} mkpart primary ext2 40MiB 100MiB
parted -s -a optimal -- ${LOOPDEV} mkpart primary ext4 100MiB -1GiB
parted -s -a optimal -- ${LOOPDEV} mkpart primary linux-swap -1GiB 100%

kpartx -av ${LOOPDEV}

mkfs.ext2 /dev/mapper/${LOOP}p1
mkfs.ext4 /dev/mapper/${LOOP}p2
mkswap /dev/mapper/${LOOP}p3

# Burn U-boot
echo "Burning u-boot to ${LOOPDEV}"

# dd if=/dev/zero of=${LOOPDEV} bs=1k count=1023 seek=1
dd if=${OUTPORT}/boot0_sdcard_sun20iw1p1.bin of=${LOOP} bs=8192 seek=16

# Copy files https://linux-sunxi.org/Allwinner_Nezha
dd if=${OUTPORT}/u-boot.toc1 of=${LOOPDEV} bs=512 seek=32800
dd if=${OUTPORT}/u-boot.toc1 of=${LOOPDEV} bs=512 seek=24576


# Copy Files, first the boot partition
echo "Copying files to boot partition ${LOOPDEV}"
MNTPOINT=/sdcard_boot
mkdir -p ${MNTPOINT}
mount /dev/mapper/${LOOP}p1 ${MNTPOINT}
cp ${OUTPORT}/Image.gz ${MNTPOINT}
# install U-Boot
cp ${OUTPORT}/boot.scr "${MNTPOINT}"
umount ${MNTPOINT}
rm -rf ${MNTPOINT}

echo "Copying files to main partition ${LOOPDEV}"

MNTPOINT=/sdcard_root
mkdir -p ${MNTPOINT}
mount /dev/mapper/${LOOP}p2 ${MNTPOINT}

cp -a ${OUTPORT}/rv64-port/* ${MNTPOINT}

umount ${MNTPOINT}
rm -rf ${MNTPOINT}

# Clean Up

kpartx -d ${LOOPDEV}
losetup -d ${LOOPDEV}
