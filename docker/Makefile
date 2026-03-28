run: build 
	docker rm -f profissional
	docker run --name=profissional --hostname=profissional --network=bridge -v $$(pwd)/volumes/profissional-milters:/opt/sooma-milters -v $$(pwd)/..:/srv/www -p 127.0.0.1:25:25 -p 127.0.0.1:143:143 -p 127.0.0.1:5432:5432 -p 127.0.0.2:80:80 -ti profissional

build:
	docker build -t profissional --progress=plain .

shell:
	docker exec -ti profissional /bin/zsh

stop:
	docker stop profissional

rm:
	docker rm -f profissional
