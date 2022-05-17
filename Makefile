all:
	sudo rm -rf ~/port/*
	docker-compose build
	docker-compose up

clean:
	docker-compose build --no-cache
	docker-compose up

zip:
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ~/port/licheerv.img.7z ~/port/licheerv.img

flash:
	cd ~/port && sudo dd if=licheerv.img of=/dev/mmcblk0 bs=8M

serial:
	cu -s 115200 -l /dev/ttyUSB0
