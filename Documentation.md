To build and run it locally:
docker build -t ipfs-metadata:latest . --no-cache
docker run -d -p 8080:8080 --name ipfs-metadata -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=testdb -e POSTGRES_HOST=host.docker.internal -e POSTGRES_PORT=5432 ipfs-metadata:latest

Note POSTGRES_HOST is overwritten to be host.docker.internal instead of localhost, because if we are using locally running postgreSQL server, it needs to be point to host.docker.internal
