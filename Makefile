#
#	Build the bootable image
#
#	Author: Tim Molteno tim@molteno.net
#
ROOTFS=~/port
DEVICE=/dev/mmcblk0

all:
	sudo rm -rf ${ROOTFS}/*
	docker-compose build
	docker-compose up

clean:
	docker-compose build --no-cache
	docker-compose up

lichee_rv.img.7z:
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on lichee_rv.img.7z ${ROOTFS}/lichee_rv*.img

flash:
	cd ${ROOTFS} && sudo dd status=progress if=lichee_rv.img of=${DEVICE} bs=8M

flash_7z: licheerv.img.7z
	7z x licheerv.img.7z -so | less | sudo dd of=${DEVICE} status=progress

serial:
	cu -s 115200 -l /dev/ttyUSB0

prerequisites:
	sudo aptitude install binfmt-support

qemu:
	cd ~/port; sudo qemu-system-riscv64 -m 1G -nographic -machine virt \
		-kernel Image -append "earlycon=sbi console=ttyS0,115200n8 root=/dev/mmcblk0p2 cma=96M" \
		-drive file=licheerv.img,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0
