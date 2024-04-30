#! /bin/bash
apt update -y
apt install docker.io -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu
curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
apt install git -y
apt install openjdk-17-jre-headless
apt install java-11-amazon-corretto -y
cd /home/ubuntu && git clone https://github.com/yakin68/ozgur-yazilim-tasg.git
