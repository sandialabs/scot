Installing SCOT
================================

We've made installing SCOT a snap, follow these simple instructions and you'll be running in no time.

Minimum System Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Ubuntu 12.04LTS or Newer (14.04 preferred)
* 2CPU 
* 4GB Ram
* 100GB Disk

Docker (Coming Soon)

* RHEL 6/7
* MacOSX (boot2docker)
* Windows (boot2docker) 

Initial Installation
^^^^^^^^^^^^^^^^^^^^

You can install via Source or Docker(coming soon)

* Source (Ubuntu only)

  * git clone https://github.com/sandialabs/scot.git scot 
  * cd scot
  * bash install_scot3

* Docker (coming soon)

  * docker pull sandia/scot
  * docker run sandia/scot

Upgrading
^^^^^^^^^

* Source
   * git pull
   * bash install_scot3

* Docker (coming soon)
   * docker pull sandia/scot
   * docker reload sandia/scot

Uninstallation
^^^^^^^^^^^^^^

* Source
   * rm -rf /opt/sandia/webapps/scot3/
   * sudo crontab -e #remove all the scot stuff
   * a bunch of other stuff....

* Docker (coming soon)
   * docker destroy sandia/scot
