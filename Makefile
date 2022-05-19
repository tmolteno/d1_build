#
#	Build the bootable image
#
#	Author: Tim Molteno tim@molteno.net
#
ROOTFS=~/port/
DEVICE=/dev/mmcblk0

all:
	sudo rm -rf ${ROOTFS}/rv64-port
	docker-compose build
	docker-compose up

clean:
	docker-compose build --no-cache
	docker-compose up

zip:
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ${ROOTFS}/licheerv.img.7z ${ROOTFS}/licheerv.img

flash:
	cd ${ROOTFS} && sudo dd if=licheerv.img of=${DEVICE} bs=8M

serial:
	cu -s 115200 -l /dev/ttyUSB0
