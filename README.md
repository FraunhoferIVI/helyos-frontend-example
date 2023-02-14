# helyos_helloworld

To install this helyOS hello world app, run the following commands:

## Starting the application
 
```
docker network create control-tower-net

docker-compose  -f ./helyos_backend/docker-compose.yml up -d 

docker-compose  -f ./simulators/docker-compose.yml up -d  

docker-compose  -f ./hello_helyos_frontend/docker-compose.yml  up -d   

```

## Terminating application and keeping database

You must wait a couple of seconds between each command.

```
docker-compose  -f ./simulators/docker-compose.yml down

docker-compose  -f ./hello_helyos_frontend/docker-compose.yml down

docker-compose  -f ./helyos_backend/docker-compose.yml down

docker network rm control-tower-net

```

helyos_control_tower is the last one to be shut down.

## Terminating application and reseting database
```
docker-compose  -f ./simulators/docker-compose.yml down

docker-compose  -f ./hello_helyos_frontend/docker-compose.yml down

docker-compose  -f ./helyos_backend/docker-compose.yml down -v

docker network rm control-tower-net

```