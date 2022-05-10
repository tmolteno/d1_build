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
sfdisk ${LOOPDEV} < ${OUTPORT}/disk_layout.sfdisk
kpartx -av ${LOOPDEV}
mkfs.vfat /dev/mapper/${LOOP}p1
mkfs.ext4 /dev/mapper/${LOOP}p2

# Burn U-boot
echo "Burning u-boot to ${LOOPDEV}"

dd if=/dev/zero of=${LOOPDEV} bs=1k count=1023 seek=1
dd if=${OUTPORT}/boot0_sdcard_sun20iw1p1.bin of=${LOOP} bs=8192 seek=16

# Copy files https://linux-sunxi.org/Allwinner_Nezha
dd if=${OUTPORT}/u-boot.toc1 of=${LOOPDEV} bs=512 seek=32800
dd if=${OUTPORT}/u-boot.toc1 of=${LOOPDEV} bs=512 seek=24576


# Copy Files, first the boot partition
echo "Copying files to boot partition ${LOOPDEV}"
MNTPOINT=/rvmnt

# mount /dev/mapper/loop0p1 ${MNTPOINT}
# cp ${uImage_dir}/uImage ${MNTPOINT}
# cp ${script.bin_dir)/script.bin ${MNTPOINT}
# cp ${uEnv.txt_dir}/uEnv.txt ${MNTPOINT}
# umount ${MNTPOINT}

echo "Copying files to main partition ${LOOPDEV}"

mkdir -p ${MNTPOINT}
mount /dev/mapper/${LOOP}p2 ${MNTPOINT}

cp -a ${OUTPORT}/rv64-port/* ${MNTPOINT}
# install U-Boot
cp "${OUTPORT}/boot.scr" "${MNTPOINT}/boot/"

umount ${MNTPOINT}

# Clean Up
kpartx -d ${LOOPDEV}
losetup -d ${LOOPDEV}
