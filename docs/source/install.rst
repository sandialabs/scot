Installing SCOT
================================

We've made installing SCOT a snap, follow these simple instructions and you'll be running in no time.

Minimum System Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Linux (preferred) / MacOSX / Windows

  * Supported via Docker and/or Boot2Docker
* 2CPU 
* 4GB Ram
* 100GB Disk

 
Initial Installation
^^^^^^^^^^^^^^^^^^^^

You can install via Docker or Source

* Source (Ubuntu only)

  * git clone https://github.com/sandialabs/scot.git scot 
  * cd scot
  * bash install_scot3

* Docker
  * docker pull sandia/scot
  * docker run sandia/scot

Upgrading
^^^^^^^^^

* Source
   * git pull
   * bash install_scot3

* Docker
   * docker pull sandia/scot
   * docker reload sandia/scot

Uninstallation
^^^^^^^^^^^^^^

* Source
   * rm -rf /opt/sandia/webapps/scot3/
   * sudo crontab -e #remove all the scot stuff
   * a bunch of other stuff....

* Docker
   * docker destroy sandia/scot
