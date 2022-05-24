#
#	Build the bootable image
#
#	Author: Tim Molteno tim@molteno.net
#
ROOTFS=~/port
DEVICE=/dev/mmcblk0

all: panel dock

panel:
	docker-compose build rv86panel
	docker-compose up rv86panel

dock:
	docker-compose build lichee_rv
	docker-compose up lichee_rv

clean:
	sudo rm -rf ${ROOTFS}/*
	docker-compose build --no-cache
	docker-compose up

lichee_rv.img.xz:
	xz ${ROOTFS}/lichee_rv*.img -9 --keep --stdout > lichee_rv.img.xz

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
