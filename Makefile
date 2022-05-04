all:
	sudo rm -rf ~/port/rv64-port
	docker-compose build
	docker-compose up

create_image:
	cd ~/port/ && sudo ./create_image.sh `pwd`
