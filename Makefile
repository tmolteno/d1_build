#
#	Build the bootable image
#
#	Author: Tim Molteno tim@molteno.net
#
DEVICE=/dev/mmcblk0

all: panel dock

panel:
	sudo rm -rf ./port_86/*
	docker-compose build rv86panel
	docker-compose up rv86panel

dock:
	sudo rm -rf ./port_dock/*
	docker-compose build lichee_rv
	docker-compose up lichee_rv

clean:
	sudo rm -rf ./port_dock/*
	sudo rm -rf ./port_86/*
	docker-compose build --no-cache
	docker-compose up

serial:
	cu -s 115200 -l /dev/ttyUSB0

prerequisites:
	sudo aptitude install binfmt-support

qemu:
	cd ~/port; sudo qemu-system-riscv64 -m 1G -nographic -machine virt \
		-kernel Image -append "earlycon=sbi console=ttyS0,115200n8 root=/dev/mmcblk0p2 cma=96M" \
		-drive file=licheerv.img,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0
