# helyOS-Emons yard automation demonstration. 
 Use the docker-compose.yml as a template to your own yard automation project.

 ## Core features
  * Serving database CRUD operations via GraphQL query language.
  * Registration of vehicles (agents) via RabbitMQ message broker.
  * Assignment of user-triggered processes to one or several services for path calculation (configurable using dashboard).
  * Collection of path calculations and delivering to agents via RabbitMQ (configurable using dashboard). 


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

## helyOS Dasboard

[http://localhost:8080/login](http://localhost:8080/login)

username: admin
password: admin


## GraphlQL

[http://localhost:5000/graphiql](http://localhost:5000/graphiql)




<!-- ## Production
<img src="image/Docker_architeture.png" alt="drawing" width="800"/>



## Development
<img src="image/Devarch.png" alt="drawing" width="800"/> -->