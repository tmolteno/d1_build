all:
	sudo rm -rf ~/port/rv64-port
	docker-compose build
	docker-compose up
