#! /bin/bash
# update os
apt update -y
# set server hostname as jenkins-server
hostnamectl set-hostname jenkins-server

# install git
apt install git -y

# install java 11
apt install fontconfig openjdk-17-jre -y

# install jenkins
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install jenkins -y
systemctl enable jenkins
systemctl start jenkins

# install docker
apt install docker.io -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu
usermod -a -G docker jenkins

# configure docker as cloud agent for jenkins
# showed you a simple procedure for setting up Docker containers as build agents in Jenkins.
cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2376 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart jenkins


# install python 3
apt install -y python3-pip python3-devel

# install boto3
pip3 install boto3 botocore


