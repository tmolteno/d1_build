#/bin/sh
# Author. Tim Molteno tim@molteno.net
# (C) 2022.

ROOT_FS=/port/rv64-port

cp /etc/resolv.conf ${ROOT_FS}/etc/resolv.conf
chroot ${ROOT_FS} /multistrap_config.sh

# cp stage1.sh ${ROOT_FS}/stage1.sh
# chroot ${ROOT_FS} /stage1.sh

#  Move files we'll need from inside the container to the users directory /outport
#  These files will all be visible in ~/port/ after the script is finished.
# cp disk_layout.sfdisk /outport/
cp create_image.sh /outport/

cp /build/linux-build/arch/riscv/boot/Image.gz /outport/
cp /build/linux-build/arch/riscv/boot/Image /outport/


cp -a /build/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin /outport/
cp -a /build/u-boot.toc1 /outport/
cp -a /build/boot.scr /outport/
cp -a ${ROOT_FS} /outport/

# Run the script to create the disk image
/build/create_image.sh /outport
