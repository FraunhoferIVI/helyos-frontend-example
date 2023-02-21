# Hello helyOS

## 1. Introduction

helyOS is a framework to accelerate the development of yard autonomous projects. The helyOS framework contains three software components: helyOS core, helyOS Agent SDK, helyOS JavaScript SDK. 

![helyOS_framework](./img/helyos_framework.png)

To display main features of helyOS, this repository build a minimalistic web application (hello helyOS) within helyOS framework. The structure of this repository are listed:

- *./hello_helyos*: The source code of hello helyOS frontend
- *./backend*: The docker image of helyOS core
- *./helyos_agent_slim_simulator*: The  docker image of helyOS agent simulator
- *./docs*: The tutorial of hello helyOS

## 2. Prior Knowledge

- Software as a service (SaaS)
- Web development (html, CSS, JavaScript)
- TypeScript
- Vue.js (or React, Angular, …)
- Web map API (leaflet map)

## 3. Build

To install this hello helyOS app, make sure you have docker installed, and then run the following commands:

### Starting the application

Before building the frontend app, make sure you have backend (**helyOS core**) installed.
 
```
docker network create control-tower-net

docker-compose  -f ./backend/docker-compose.yml up -d 

docker-compose  -f ./hello_helyos/docker-compose.yml  up -d   

docker-compose  -f ./helyos_agent_slim_simulator/docker-compose.yml up -d  
```

### Terminating application and keeping database

You must wait a couple of seconds between each command.

```
docker-compose  -f ./helyos_agent_slim_simulator/docker-compose.yml down

docker-compose  -f ./hello_helyos/docker-compose.yml down

docker-compose  -f ./backend/docker-compose.yml down

docker network rm control-tower-net
```

*backend* is the last one to be shut down.

### Terminating application and reseting database
```
docker-compose  -f ./helyos_agent_slim_simulator/docker-compose.yml down

docker-compose  -f ./hello_helyos/docker-compose.yml down

docker-compose  -f ./backend/docker-compose.yml down -v

docker network rm control-tower-net
```

## 4. Demo

If you build the whole app correctly, you can access to hello helyOS web app via  http://localhost:5174/.

![helyOS_login](./img/helyos_login.png)
Login in with the {"username": "admin", "password": "admin"}, or other accounts registered at helyOS Dashboard.

![hello_helyOS](./img/hello_helyos.PNG)

Features included in hello helyOS:
- Switch yards
- Upload, push, delete geojson file displayed as shapes (geojson examples stored at *./hello_helyos/src/assets/mock/*)
- Change icon of agents (icons stored at *./hello_helyos/src/assets/icon/*)
- Track tool status, position
- Select, dispatch a mission
- SDK hints

## 5. Useful Links

- [helyOS Dashboard](http://localhost:8080)
- [Hello helyOS](http://localhost:5174)
- [Hello helyOS Tutorial](https://readthedocs.org/projects/helyos-app-tutorial/)
- [helyOS JavaScript SDK](https://github.com/FraunhoferIVI/helyOS-javascript-sdk)
- [helyOS Agent SDK](https://pypi.org/project/helyos-agent-sdk/)


## Author
- [Jiapan Wang](https://github.com/Wjppppp)

## License
This project is licensed under the MIT License