Installing SCOT
================================

We've made installing SCOT a snap; follow these simple instructions and you'll be running in no time.

Minimum System Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Ubuntu 12.04LTS or Newer (14.04 preferred)
* 2CPU 
* 4GB Ram
* 100GB Disk

Docker (beta)

* RHEL 6/7
* MacOSX (boot2docker)
* Windows (boot2docker) 

Initial Installation
^^^^^^^^^^^^^^^^^^^^

You can install via Source or Docker(beta)

* Source (Ubuntu only)

  * git clone https://github.com/sandialabs/scot.git scot 
  * cd scot
  * bash install_scot3

* Docker (beta)

  * docker pull sandialabs/scot
  * docker run sandialabs/scot

.. _upgrade:

Upgrading
^^^^^^^^^

* Source
   * git pull
   * bash install_scot3

* Docker (beta)
   * docker pull sandialabs/scot
   * docker reload sandialabs/scot
   
   NOTE: you will need to manual backup the SCOT database, move the backup file out of the container, and then move
   the backup file back into the container after upgrading and then perform an manual restore.

Uninstallation
^^^^^^^^^^^^^^

* Source
   * rm -rf /opt/sandia/webapps/scot3/
   * sudo crontab -e #remove all the scot stuff
   * a bunch of other stuff....

* Docker (beta)
   * docker destroy sandialabs/scot
