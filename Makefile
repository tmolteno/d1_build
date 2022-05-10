all:
	sudo rm -rf ~/port/*
	docker-compose build
	docker-compose up

clean:
	docker-compose build --no-cache
	docker-compose up

zip:
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ~/port/licheerv.img.7z ~/port/glicheerv.img

create_image:
	cd ~/port/ && sudo ./create_image.sh `pwd`
