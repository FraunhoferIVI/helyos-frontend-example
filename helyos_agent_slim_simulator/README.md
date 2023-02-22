# helyOS Agent Slim Simulator
This is a docker image of helyOS agent slim simulator. Configurations can be set in *./docker-compose.yml*.

## To start
```
docker-compose up
```

## To restart
This will delete the database.
```
docker-compose down
docker volume prune
docker-compose up
```

## To terminate
```
docker-compose down
```