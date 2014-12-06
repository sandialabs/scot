![SCOT-logo](./SCOT_Logo64x64.png) SCOT Dockerfile
=================
<!-- ![SCOT-logo](./scot_logo_highrez_64x64.png) Dockerfile
================== -->

### Dependencies
* [ubuntu:latest](https://index.docker.io/_/ubuntu/)

### Installation

1. Install [Docker](https://www.docker.io/).

2. Download [trusted build](https://index.docker.io/u/sandia/scot) from public [Docker Registry](https://index.docker.io/): `docker pull sandia/scot`

#### Alternatively, build an image from Dockerfile
```bash
$ docker build -t sandia/scot github.com/sandia/scot
```

### To Build

```bash
$ git clone https://github.com/sandia/scot.git
$ cd scot/deploy/ScotBaseImage
$ sudo docker build -t sandia/scotbase .
$ cd ../.. (to the scot root folder)
$ sudo docker build -t sandia/scot .
```

### To Run

```bash
$ sudo docker run -d --restart always -p 443:443 --name scot sandia/scot
```
> NOTE: This is running with the `--restart always` flag which means the docker daemon will restart it when the host is rebooted

### To Run on OSX
- Install [Homebrew](http://brew.sh)

```bash
$ brew install cask
$ brew cask install virtualbox
$ brew install docker
$ brew install boot2docker
$ boot2docker up
```

#### Usage
```bash
$ docker run --name scot -p 443:443 -p 80:80 -d sandia/scot
```
As a convience you can add the **boot2docker** IP to you **/etc/hosts** file:
```bash
$ echo $(boot2docker ip) dockerhost | sudo tee -a /etc/hosts
```

1. Navigate to https://dockerhost from your host (OSX)
2. Log in with default creds
  * **user:** `admin`
  * **password:** `admin`

### To Develop on Mac
```bash
$ cd <scot_src_root_directory>
$ docker run --name scot -v $(pwd)/public:/opt/sandia/webapps/scot3/public:ro -p 443:443 -p 80:80 -d sandia/scot
```
Running the container in this way will mount the *SCOT* **public** folder from the OSX host into the container as a read only folder.  
Allowing you to make changes to the UI from your Mac and then refresh your browser to see the changes reflected inside the container.

#### To see the processes running in the container:
```bash
$ docker top scot
```
#### To see the stdout/stderr logs from the container:
```bash
$ docker logs scot
```
#### To enter the container (kinda like ssh):
```bash
$ docker exec -it scot bash
```
#### To `tail -f` the scot logs:
```bash
$ docker exec -it scot tail -f /var/log/scot.prod.log
```
#### Contribute to the SCOT team (PLEASE!)
```bash
$ git request-pull v3.4 https://github.com/sandia/scot master
```
#### For Fun
```bash
$ brew install mpg123
```
Add the following to your bash or zsh profile
```bash
$ alias docker='echo "WE HAVE TO GO DEEPER"; mpg123 -q http://inception.davepedu.com/inception.mp3; docker'
```

## SCOT Vagrantfile
### Dependencies
* [homebrew](http://brew.sh)
* [brew-cask](http://caskroom.io)
* [vagrant](https://www.vagrantup.com/downloads.html)
* [virtualbox](https://www.virtualbox.org/wiki/Downloads)

### Installation (OSX)

1. Install **homebrew** `ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"`
2. Install **brew-cask** `brew install caskroom/cask/brew-cask`
3. Install **vagrant** `brew cask install vagrant`
4. Install **virtualbox** `brew cask install virtualbox`

### To Build

```bash
$ git clone https://github.com/sandia/scot.git
$ cd scot/deploy
$ vagrant up
```
> NOTE: This is configuring a fresh install of ubuntu, installing docker and building the SCOT docker container (which can take a long time)

### To Run
1. Navigate to https://127.0.0.1:8080 from your host (OSX)
2. Log in with default creds
  * **user:** `admin`
  * **password:** `admin`


### To Enter Ubuntu VM running docker -> running a container running SCOT

```bash
$ vagrant ssh

# to see running SCOT docker container
$ sudo docker ps -a
```

### To Enter SCOT docker container running on Ubuntu VM running in vagrant on your host ( *It's Software-ception!!* )
![deeper](http://static3.wikia.nocookie.net/__cb20130123200725/glee/images/6/6f/We-need-to-go-deeper_inception.jpg)
```bash
# List all running docker containers
$ sudo docker ps -a
CONTAINER ID        IMAGE                COMMAND                CREATED             STATUS              PORTS                             NAMES
e73bf10923e7        sandia/scot:latest   "/usr/bin/supervisor"   17 minutes ago      Up 17 minutes       0.0.0.0:443->443/tcp   scot
# To enter the running scot container
$ sudo docker exec -it e73bf10923e7 bash
# We now are essentially sshed into the running scot container
root@e73bf10923e7:~# cd /
# Show the container filesystem
root@e73bf10923e7:/# ls
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```
