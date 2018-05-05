#!/bin/sh 

# change hostname 
#sudo hostname -b raspi

### setting up docker ###
sudo apt-get update
sudo apt-get install -y --no-install-recommends apt-transport-https \
    ca-certificates curl software-properties-common

sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo apt-key fingerprint 9DC858229FC7DD38854AE2D88D81803C0EBFCD88

#deb https://download.docker.com/linux/debian jessie stable

echo "deb [arch=armhf] https://download.docker.com/linux/debian \
     $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get -y install docker-ce

sudo systemctl start docker

### setting up rabbitMQ in docker ###
HB_RABBITMQ_DEFAULT_USER=pi
HB_RABBITMQ_DEFAULT_PASS=vulam,.

cd ~; 
rm -rf docker-rabbitmq; 
cd ~; 
git clone https://github.com/sejnub/docker-rabbitmq.git; 
cd ~/docker-rabbitmq; 
sudo docker build --build-arg HB_RABBITMQ_DEFAULT_USER=$HB_RABBITMQ_DEFAULT_USER --build-arg HB_RABBITMQ_DEFAULT_PASS=$HB_RABBITMQ_DEFAULT_PASS -t sejnub/rabbitmq .

#launch it
sudo docker rm -f rabbitmq; 
sudo docker run  -d --restart unless-stopped -p 5672:5672 -p 15672:15672 -p 1883:1883 --name rabbitmq sejnub/rabbitmq 

# getting iGrowFlora
cd ~/
git clone https://github.com/szymansk/iGrowFlora.git

### setting up node-red in docker ###
cd ~/
git clone https://github.com/node-red/node-red-docker.git
cd node-red-docker

# Build it with the desired tag
sudo docker build -f rpi/Dockerfile -t nodered/node-red-docker:rpi-alexa .

sudo docker run -d --restart unless-stopped --cap-add SYS_RAWIO --device /dev/gpiomem --privileged -p 1880:1880  -v ~/iGrowFlora/node-red-data:/data --link rabbitmq:broker --name nodered/node-red-docker:rpi-alexa

sudo docker run -d --restart unless-stopped --cap-add SYS_RAWIO --device /dev/gpiomem --privileged -v ~/iGrowFlora/raspberryPI/src/config:/config -v ~/iGrowFlora/raspberryPI/src:/data --link rabbitmq:broker --name nodeGrow hypriot/rpi-node node /data/mqttValveControllerClient.js
  




