#
#	Build bootable SDcard image for various Allwinner D1 boardss
#
#	Author: Tim Molteno tim@molteno.net
#
DEVICE=/dev/mmcblk0

all: panel dock

panel:
	sudo rm -rf ./lichee_rv_86/*
	DOCKER_BUILDKIT=1 docker-compose build panel
	docker-compose up panel

dock:
	sudo rm -rf ./lichee_rv_dock/*
	DOCKER_BUILDKIT=1 docker-compose build dock
	docker-compose up dock

lcd:
	sudo rm -rf ./lichee_rv_lcd/*
	DOCKER_BUILDKIT=1 docker-compose build lcd
	docker-compose up lcd

clean:
	sudo rm -rf ./lichee_rv_dock/*
	sudo rm -rf ./lichee_rv_86/*
	DOCKER_BUILDKIT=1 docker-compose build --no-cache
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
