Installing SCOT
===============

Minimum System Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^

* Ubuntu 14.04 LTS (best tested), 16.04 LTS, or CentOS 7.
* 2 Quad Core CPU
* 16 GB RAM
* 1 TB Disk

System Preparation
^^^^^^^^^^^^^^^^^^

CENTOS 7 (only)
---------------

If you built your system from the minimal ISO, you will need to do the following first::

    $ su
    password: 
    # yum update
    # yum -y install net-tools
    # yum -y install git
    # yum -y groupinstall "Development Tools"
    # yum -y install wget

Perl on CENT/RedHat is pretty ancient and will not work with SCOT.  SCOT requires at least Perl 5.18.
Fortunately, is is pretty easy to update Perl using the following::

    $ su
    password:
    # wget http://www.cpan.org/src/5.0/perl-5.24.0.tar.gz
    # tar xzvf perl-5.24.0.tar.gz
    # cd perl-5.24.0
    # ./Configure -des
    # make
    # make test
    # make install

Ubuntu and CENT
---------------

# Now you are ready to pull the SCOT source from GitHub::

    $ git clone https://github.com/sandialabs/scot.git scot

# cd into the SCOT directory::

    $ cd /home/user/scot

# Are you upgrading from SCOT 3.4?  If so, you should do the following

    * Backup you existing SCOT database::
    
        $ mongodump scotng-prod
        $ tar czvf scotng-backup.tgz ./dump

    * delete SCOT init script and crontab entries::

        # rm /etc/init.d/scot3
        # crontab -e 

# go ahead and become root::

    $ sudo bash
    
# Make sure that the http_proxy and https_proxy variables are set if needed::
  
    # echo $http_proxy
    # export http_proxy=http://yourproxy.domain.com:80
    # export https_proxy=https://yourproxy.domain.com:88

# You are now ready to begin the install::

   # ./install.sh

Go get a cup of cofee.  Initial install will download and install all the dependencies for SCOT.  If any errors should 
occurr, it is OK to re-run the installer after those problems are resolved.

install.sh Options
^^^^^^^^^^^^^^^^^^

SCOT's installer, install.sh,  is designed to automate many of the tasks need to install and 
upgrade SCOT.  The installer takes the following flags to modify its installtion behavior::

Usage: ./install.sh [-abigmsrflq] [-A mode] 

    -a      do not attempt to perform an "apt-get update"
    -d      do not delete /opt/scot before installation
    -i      do not overwrite an existing /etc/init.d/scot file
    -g      Overwrite existing GeoCitiy DB
    -m      Overwrite mongodb config and restart mongo service
    -s      SAFE SCOT. Only instal SCOT software, do not refresh apt, do not
                overwrite /etc/init.d/scot, do not reset db, and
                do not delete /opt/scotfiles
    -r      delete SCOT database (will result in data loss!)
    -f      delete /opt/scotfiles directory and contents ( again, data loss!)
    -l      truncate logs in /var/log/scot (potential data loss)
    -q      install new activemq config, apps, initfiles and restart service
    -w      overwrite existing SCOT apache config files
    -A mode     mode = Local | Ldap | Remoteuser
                default is Remoteuser (see docs for details)
