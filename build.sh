#/bin/sh

cp /etc/resolv.conf /port/rv64-port/etc/resolv.conf
chroot /port/rv64-port /multistrap_config.sh

# Now have to create a filesystem image...
# http://www.orangepi.org/Docs/Makingabootable.html

dd if=/dev/zero of=/outport/licheerv.img bs=1M count=3500
losetup -f --show /outport/licheerv.img
# Create partitions
# sudo fdisk /dev/loopX
# sudo kpartx -av /dev/loop0
# # Format them
# sudo mkfs.vfat /dev/mapper/loop0p1
# sudo mkfs.ext4 /dev/mapper/loop0p2
# Copy files
# sudo dd if=/uboot/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin of=/dev/sdX bs=8192 seek=1
# sudo dd if=/uboot/u-boot.toc1 of=/dev/sdX bs=512 seek=32800
# sudo dd if=/uboot/u-boot.toc1 of=/dev/sdX bs=512 seek=24576

# Somehow copy the root filesystem /port/rv64-port /port/licheerv.sqsh


cp -a /port/rv64-port /outport/
