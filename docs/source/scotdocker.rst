Docker-SCOT v 0.01
***************

=================
Table of Contents
=================

* Overview
* Docker-SCOT containers
* Managing the containers
* Configuration
* FAQ / Common Issues


**Overview** 
----------------------

Docker-SCOT is an experimental, multi-container based implementation of SCOT. Docker-Scot allows a new user to get up and running with SCOT much quicker, and easier than with the traditional SCOT install process. 

**IMPORTANT**

Backup your database via the backup.pl in the /opt/scot/bin/ directory before upgrading to the docker version of SCOT. If you are upgrading, you will also need to turn off all services that the older version of SCOT uses such as Apache, Activemq, Mongodb, ElasticSearch and SCOT (i.e. sudo service stop scot). Also as far as upgrading, we have **not** tested upgrading from any version before 3.4. Upgrade from versions prior to 3.4 to 3.5 first before upgrading to Docker-SCOT



Docker-SCOT containers
----------------------
Docker-SCOT is comprised of the following services: 

* **SCOT** - SCOT Application and associated API
* **MongoDB** - Storage for SCOT
* **ActiveMQ** - Message broker for servies interested in SCOT data
* **Apache** - Proxy for traffic between some services
* **ElasticSearch** - Search engine
* **Flair Engine** - 'Entities' found within SCOT are highlighted with a count of the number of times SCOT has 'seen' them before
* **Game Engine** - Used for homepage statistics
* **Stretch** - Used for adding data to ElasticSearch
* **Mail** - Used as a reslient mechanism for importing data to SCOT (not enabled by default - See configuration section)
* **Reflair** Similar to flair


Docker Installation
------------

To get started, refer to the Docker Community Edition documentation for installing the Docker engine on your respective OS: `https://docs.docker.com/engine/installation/ <https://docs.docker.com/engine/installation/>`_

Next, Docker-SCOT relies on docker-compose to build, run and manage services. Docker-compose does not ship with Docker engine, so you will need to refer to the following documentation for installation of Docker-Compose: https://docs.docker.com/compose/install/

SCOT Installation
---------------


There are two methods for getting started with SCOT. Run the SCOT/restart-build-deploy.sh script (will be promopted to enter sudo credentials) and follow the on screen prompts for either. 


1. Easy mode - this mode will pull all necessary docker images from from Dockerhub (preconfigured). This is the preferred method if you do are not concerned with any of the below bullet points. 
    * Using self-signed certificates for apache
    * Making changes to the underlying SCOT perl source code
    * Configuring the mail service to integrate with you a corporate email account
2. Custom Mode - If you are concerned with the above, you should use the custom mode which builds the docker containers from source and deploys them. 



Managing the containers
---------------
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

The docker-scripts directory contains scripts for backing up the data contained in MongoDB container and will eventually house other scripts that are similar.

The following scripts are currently supported: 

1. /opt/scot/bin/restore.pl
2. /opt/scot/bin/restore_remote_scotdb.pl
3. restore.pl

To execute one of the above scripts, simply connect to the scot container via:: 


    sudo docker exec -i -t -u 0 scot /bin/bash

cd to /opt/scot/bin/

and run::


    ./scriptexample.pl
   

**Restoring a database**

If you are upgrading to the docker version of SCOT and need to restore your database (make sure to backup your database prior to upgrading) or you are already using the docker version of SCOT and want to backup your database simply run:: 

    sudo docker exec -i -t -u 0 scot /bin/bash

cd to /opt/scot/bin and run::
    ./backup.pl
    
To restore, once you have finished the backup::

    sudo docker exec -i -t -u 0 scot /bin/bash

cd to /opt/scot/bin and run::
    ./restore.pl


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

**LDAP**

By default, LDAP configuration is not enabled in docker-configs/scot/scot.cfg.pl. To enable, simply uncomment the LDAP configuration lines in docker-configs/scot/scot.cfg.pl and edit the necessary information to begin checking LDAP for group membership / auth. 


**Custom SSL**

Docker-SCOT's Apache instance comes configured with a self-signed SSL cert baked into the container. However, if you wish to use your own ceritifcates, do the following: 

1. Remove the SSL cert creation lines from the Dockerfile-Apache file. 
2. In docker-configs/apache/ directory, there is a scot-revproxy-Ubuntu.conf. Replace the following line:: 

    ServerName apache
    
with::

    Servername nameofyourhost
    
3. In the same file, replace the following lines::

    SSLCertificateFile /etc/apache2/ssl/scot.crt
    SSLCertificateKeyFile /etc/apache2/ssl/scot.key

with the path and name of the eventual location where you will map your certs to via a shared data volume. 
4. Next, as mentioned above, you need to pump your certs from your host machine into the container via a data volume (you can also copy them into the container at build time via COPY directive). In order to map them in via a data volume, add a new data volume under the apache service in the docker-compose.yml file. Eg.::
    volumes:
     - "/etc/timezone:/etc/timezone:ro"
     - "/etc/localtime:/etc/localtime:ro"
     - "/var/log/apache2:/var/log/apache2/"
     - "/path/to/your/cert:/path/to/file/location/you/defined/in/step/3
     - "/path/to/your/key:/path/to/file/location/you/defined/in/step/3

5. Re-run the restart-build-deploy.sh script and you should be set!

FAQ / Common Issues
-------------

**Common Issues**

1. Apache frequently will throw an error on run time that the process is already running and will subequently die. In the event this happens, simply re-run the script. 

