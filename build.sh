#/bin/sh
# Author. Tim Molteno tim@molteno.net
# (C) 2022.

PORT=/port/rv64-port

cp /etc/resolv.conf ${PORT}/etc/resolv.conf
chroot ${PORT} /multistrap_config.sh


#  Move files we'll need from inside the container to the users directory /outport
#  These files will all be visible in ~/port/ after the script is finished.
cp disk_layout.sfdisk /outport/
cp create_image.sh /outport/

cp /kbuild/linux-build/arch/riscv/boot/Image.gz /outport/
cp /kbuild/linux-build/arch/riscv/boot/Image /outport/

cd /kbuild/linux-build && make modules_install ARCH=riscv INSTALL_MOD_PATH=${PORT}
# KERNELRELEASE=5.17.0-rc2-379425-g06b026a8b714

cp -a /uboot/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin /outport/
cp -a /uboot/u-boot.toc1 /outport/
cp -a /uboot/boot.scr /outport/
cp -a ${PORT} /outport/

# Run the script to create the disk image
/build/create_image.sh /outport
