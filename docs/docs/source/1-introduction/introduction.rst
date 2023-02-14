Introduction
============

What is helyOS?
---------------
The helyOS is a microservice architecture tailored for applications in fleet management of autonomous driving vehicles in delimited areas. 
The core software works as a ready-to-use backend for Control Tower Software and is able to orchestrate microservices to compose the mission data.

In brief, helyOS is a framework to accelerate the development of yard autonomous projects.

helyOS Framework
----------------
The helyOS framework contains three software components: **helyOS core**, **helyOS Agent SDK**, **helyOS JavaScript SDK**.

.. figure:: ./img/helyos_framework.png
    :width: 500pt
    :align: center

    helyOS framework
.. source of image needs to be updated

- **helyOS core**: a flexible backend software that receives mission requests from frontend apps and use microservices to transform these requests in vehicles assignments.

- **helyOS Agent SDK**: a Python library to connect agents (robots and vehicles) to helyOS core via rabbitMQ.

- **helyOS JavaScript SDK**: a JavaScript library to create frontend apps that communicates with helyOS core.


About this tutorial
-------------------
In this tutorial you will create a Hello-World web application within **helyOS** framework by using one of popular frontend frameworks **Vue.js** step by step.

The tutorial is aimed at people interested in building a yard automation project to visualize and control **yards**, **geographical data** and **autonomous driving agents**. 
You will start from an empty Vue project template, which can also be the reference for other frontend frameworks. Then implement the communication between your frontend and 
helyOS-backend. After following this tutorial, a modern SaaS-based yard automation web application within helyOS framework is expected.

The prior knowledge which will be helpful for you to understand and use are listed:

- Web development (HTML, CSS, JavaScript)
- TypeScript
- Vue.js
- Docker container
  

Useful Links
------------
Here are some useful links which could be helpful during the tutorial.

- `Vue.js <https://vuejs.org/>`_.
- `TypeScript <https://www.typescriptlang.org/>`_.
- `Leaflet Map <https://leafletjs.com/>`_.
- `helyOS JavaScript SDK <https://github.com/FraunhoferIVI/helyOS-javascript-sdk>`_.
- `helyOS Agent SDK <https://pypi.org/project/helyos-agent-sdk/>`_.
- `helyOS dashboard <http://localhost:8080>`_.
- `helyOS Web Demo <http://localhost:3080>`_.
- `Docker docs <https://docs.docker.com/>`_.