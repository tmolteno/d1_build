#!/bin/sh
#
# Author. Tim Molteno tim@molteno.net
# (C) 2022.
# http://www.orangepi.org/Docs/Makingabootable.html

# Make Image the first parameter of this script is the directory containing all the files needed
# This is done to allow the script to be run outside of Docker for testing.
OUTPORT=$1

IMG=${OUTPORT}/licheerv.img
dd if=/dev/zero of=${IMG} bs=1M count=3500

# Setup Loopback device
LOOP=`losetup -f --show ${IMG}`

# Create partitions
sfdisk ${LOOP} < ${OUTPORT}/disk_layout.sfdisk
kpartx -av ${LOOP}
mkfs.vfat /dev/mapper/loop0p1
mkfs.ext4 /dev/mapper/loop0p2

# Burn U-boot
dd if=/dev/zero of=${LOOP} bs=1k count=1023 seek=1
dd if=${OUTPORT}/boot0_sdcard_sun20iw1p1.bin of=${LOOP} bs=8192 seek=16

# Copy files https://linux-sunxi.org/Allwinner_Nezha
dd if=${OUTPORT}/u-boot.toc1 of=${LOOP} bs=512 seek=32800
dd if=${OUTPORT}/u-boot.toc1 of=${LOOP} bs=512 seek=24576

# Copy Files, first the boot partition
# mount /dev/mapper/loop0p1 /mnt
# cp ${uImage_dir}/uImage /mnt
# cp ${script.bin_dir)/script.bin /mnt
# cp ${uEnv.txt_dir}/uEnv.txt /mnt
# umount /mnt


mount /dev/mapper/loop0p2 /mnt
cp -a ${OUTPORT}/rv64-port/* /mnt
umount /mnt

# Clean Up
kpartx -d ${LOOP}
losetup -d ${LOOP}
umount ${LOOP}
