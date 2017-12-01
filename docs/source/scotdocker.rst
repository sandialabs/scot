Docker-SCOT
***************

**Overview** 

Docker-SCOT is an experimental, multi-container based implementation of SCOT. Docker-Scot allows a new user to get up and running with SCOT much quicker, and easier than with the traditional SCOT install process. 


Docker-SCOT containers
----------------------
Docker-SCOT is comprised of the following services: 

* **SCOT API**
* **MongoDB** - Storage for SCOT
* **ActiveMQ** - Message broker for servies interested in SCOT data
* **Apache** - Proxy for traffic between some services
* **ElasticSearch** - Search engine
* **Flair Engine** - 'Entities' found within SCOT are highlighted with a count of the number of times SCOT has 'seen' them before
* **Game Engine** - Used for homepage statistics
* **Stretch** - Used for adding data to ElasticSearch
* **Mail** - Used as a reslient mechanism for importing data to SCOT (not enabled by default - See configuration section)
* **Reflair** Similar to flair

Docker-SCOT also runs the following ephemeral containers on demand or on startup:

* Docker-Utilities - A container that can be built and run on demand for executing scripts against Mongo, Scot, Elastic, etc. For instance, if a user wants to run the restore_remote_db.pl script to restore the database for MongoDB from a remote source, they can do so by: 

sudo docker build --build-arg SCRIPT=restore_remote_scotdb.pl  -t util -f Dockerfile-Utilities .

Passing in the name of the script they would like to execute. More on this, in the 'Configuration - Docker-scripts' section. 

Installation
------------

To get started, refer to the Docker Community Edition documentation for installing the Docker engine on your respective OS: `https://docs.docker.com/engine/installation/ <https://docs.docker.com/engine/installation/>`_

Next, Docker-SCOT relies on docker-compose to build, run and manage services. Docker-compose does not ship with Docker engine, so you will need to refer to the following documentation for installation of Docker-Compose: https://docs.docker.com/compose/install/

Getting Started
---------------

Once you have Docker engine and Docker-Compose installed, cd into the root of the SCOT software directory and run::

    sudo docker-compose up --build

This above command will manage the building, running, name-spacing, networking, etc. of the Docker-SCOT services as defined in the docker-compose.yml file. 

To stop Docker-SCOT::

    sudo docker-compose stop

To start a specific service:: 

    sudo docker-compose up --build name_of_service


To stop a specific service::

    sudo docker-compose stop name_of_of_service
    
To restart a specific service and build in any particular changes you have made to source:: 

    sudo docker-compose up -d --build name_of_service
    



Configuration
-------------

Docker-SCOT relies on the docker-compose.yml to define the execution of the services, the DockerFiles that define the dependencies for each container, and two directories (docker-scripts & docker-configs). Below I will talk about each. 

**docker-compose.yml**

The docker-compose.yml simply defines the port mappings, data volumes, build contexts, etc. Most of this can be configured as you please but keep in mind some of the data volume mapping and all of the static IPs are currently required unless you modify the configuration files in docker-configs. 

**docker-scripts**

The docker-scripts directory contains scripts for backing up the data contained in MongoDB container and will eventually house other scripts that are similar. These scripts are packaged into the Docker-Utilities container and are run on a manual basis. To run a particular script, simply:: 

    sudo docker build --build-arg SCRIPT=name_of_script_that_exists_in_docker_scripts_directory  -t docker-util -f Dockerfile-Utilities .

And then run:: 

    sudo docker run -it --rm --name docker-util -e SCRIPT=name_of_script_that_exists_in_docker_scripts_directory --net scot_scot-docker-net --ip 172.18.0.11  docker-util

This will execute the script and close the container once it completes. 

**docker-configs**

The docker-configs directory contains modified config files, perl modules, scripts, etc. that allow SCOT to function properly in a containerized environment. Most changes are references to localhost in the standard SCOT codebase where we modify those addresses to reference the ip addresses on the scot_docker subnet. 


**MongoDB Default password**

MongoDB default password (also used for logging in to SCOT if local auth is enabled (by default)), is: 

* Username: admin
* Password: admin

Note: If by chance you ever go to wipe your mongo database and would like to start fresh, you would need to delete the file /var/lib/mongodb/.mongodb_password_set. 


**Persisted Data** 

You can view which data is being persisted by viewing the docker-compose.yml script and referring to the various 'Volumes'. With regard to MongoDB (where SCOT records are persisted), those directories are mapped to your Host's: /var/lib/mongodb directory. 

**Mail** 

To begin using mail, you will need to uncomment the 'mail' service in the docker-compose.yml file and also add any of your organization's mail configurations into the 
docker-configs/mail/alert.cfg.pl file. 









