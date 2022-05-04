#/bin/sh

PORT=/port/rv64-port

cp /etc/resolv.conf ${PORT}/etc/resolv.conf
chroot ${PORT} /multistrap_config.sh



#  Move files we'll need
cp disk_layout.sfdisk /outport/
cp -a /uboot/sun20i_d1_spl/nboot/boot0_sdcard_sun20iw1p1.bin /outport/
cp -a /uboot/u-boot.toc1 /outport/

cp -a ${PORT} /outport/


# ./create_image.sh /outport
