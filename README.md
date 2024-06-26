# Microservices CI/CD Pipeline with Jenkins

## Description

This project aims to create full CI/CD Pipeline for microservice based applications using Microservices Application. Jenkins Server deployed on Elastic Compute Cloud (EC2) Instance is used as CI/CD Server to build pipelines. 


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 1 - Prepair GitHub Repository for your proje 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* create a private repo named ozgur-yzl-tasg. No readme.md.

``` bash
git clone https://github.com/yakin68/ozgur-yzl-tasg.git 
```

* Connect to the [Spring Petclinic Microservices Application] {https://github.com/yakin68/ozgur-yzl-tasg.git} repo and copy the Spring Petclinic Microservices Application to the repo we created. If you want, you can "fork" or download the repo.

* What should be taken into consideration here is to delete the ".git" directory in the "git clone https://github.com/yakin68/ozgur-yzl-tasg.git" locale clone when copying the application. must. Otherwise, you may receive errors on the project. You need to do this if you want the project to be yours and you want to make changes to it.

```bash
cd ozgur-yzl-tasg
rm -rf .git
```

*  Enter the following commands from the terminal so that it does not always ask who are you.

```bash
git init  
git add .
git config --global user.email "yakin68@gmail.com"
git config --global user.name "yakin68"
git commit -m "first commit"
git remote add origin https://[github username]:[your-token]@github.com/yakin68/ozgur-yzl-tasg.git  
git push origin main
```

* Do not push the token to github and do not share it with anyone. *This command is used to add a remote repository to a Git repository. In the relevant example, a remote repository is added with the git remote add command. The name origin is usually used by default for the main remote repository. You specify your GitHub username in the [github username] section, your GitHub account's access token in the [your-token] section, and the repository address you want to add in the yakin68/ozguryzl-tasg.git section. If you use this command, you specify your GitHub username and If you insert your access token correctly, you will link a local Git repository to the remote repository "yakin68/ozgur-yzl-tasg" on GitHub. This allows you to push the changes you made locally to this remote repository and pull them from the remote repository to the local repository.


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 2 - Install jenkins-server for automation infrastructure
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create a folder for ansible jobs under the `main` folder.
  
```bash
mkdir -p infrastructure/jenkins-server
```

* Prepare a terraform file for jenkins server,  and save it as `jenkins-server.tf` , `jenkinsdata.sh` ,`jenkins.auto.tfvars.tf` , `jenkins_variables.tf` under the `infrastructure/jenkins-server

* Create terraform file for jenkins-server.tf  
```go
provider "aws" {
  region = var.region
  //  access_key = ""
  //  secret_key = ""
}

resource "aws_instance" "tf-jenkins-server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-jenkins-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.tf-jenkins-server-profile.name
  root_block_device {
    volume_size = 16
  }
  tags = {
    Name = var.jenkins-server-tag
    server = "Jenkins"
  }
  user_data = file("jenkinsdata.sh")
}

resource "aws_security_group" "tf-jenkins-sec-gr" {
  name = var.jenkins_server_secgr
  tags = {
    Name = var.jenkins_server_secgr
  }
  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "tf-jenkins-server-role" {
  name               = var.jenkins-role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess", "arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "tf-jenkins-server-profile" {
  name = var.jenkins-profile
  role = aws_iam_role.tf-jenkins-server-role.name
}
```

* Create terraform userdata for jenkinsdata.sh  
```go
#! /bin/bash
# update os
apt update -y
# set server hostname as jenkins-server
hostnamectl set-hostname jenkins-server

# install git
apt install git -y

# install java 17
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

# install ansible
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y

# install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Helm 
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# install boto3
sudo apt update
sudo apt-get install python3-pip -y
sudo pip3 install --upgrade pip
sudo pip3 install boto3 botocore
sudo apt update

# install aws cli
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo apt update
```

* Create terraform auto.tfvars file for jenkins.auto.tfvars  
```go
mykey = "yaksonkey" # write your key
ami = "ami-0e001c9271cf7f3b9"
region = "us-east-1"
instance_type = "t3a.medium"
jenkins_server_secgr = "ozguryzl-jenkins-server-secgr"
jenkins-server-tag = "Jenkins Server of ozguryzl"
jenkins-profile = "ozguryzl-jenkins-server-profile"
jenkins-role = "ozguryzl-jenkins-server-role"
```
* Create terraform variables file for jenkins_variables.tf  
```go
variable "mykey" {}
variable "ami" {
  description = "amazon ubuntu 22.04 ami"
}
variable "region" {}
variable "instance_type" {}
variable "jenkins_server_secgr" {}
variable "jenkins-server-tag" {}
variable "jenkins-profile" {}
variable "jenkins-role" {}
```

* Run the terraform files in the /infrastructure/jenkins-server folder. (This will create a virtual machine for the jenkin server.)

``` bash  
  terraform init 
  terraform apply -auto-approve
```

* Get the initial administrative password.

``` bash  
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
* Enter the temporary password to unlock the Jenkins.

* Install suggested plugins.

* Create first admin user.

* Open your Jenkins dashboard and navigate to Manage Jenkins >> Plugins >> Available tab

* Search and select GitHub Integration, Docker, Docker Pipeline, Email Extension plugins, then click Install without restart. Note: No need to install the other Git plugin which is already installed can be seen under Installed tab.

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 3 - Run App locally
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Before preparing the microservice architecture, it is a best-practice method to manually check whether it works or not. 
* Spring Petclinic is a Spring Boot application built using Maven or Gradle. You can build a jar file and run it from the command line (it should work just as well with Java 17 or newer):

* Create a job in Jenkins 
```
./mvnw package
java -jar target/*.jar
```

* When we examine readme.md in the [Spring Petclinic Microservices Application] repo, you will be able to get images with https://localhost:8080. You need to get the localhost here, the EC2 instance public ip that we set up for Jenkins-server. 
  

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 4 - Prepare Dockerfiles for Microservices 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare a Dockerfile file in the main directory.

```
FROM amazoncorretto:17-alpine3.18
WORKDIR /app
COPY ./target/*.jar /app.jar
ENV SPRING_PROFILES_ACTIVE mysql
EXPOSE 8080
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 -Prepare Automation Pipeline [environment]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare environment, S3 bucket for HELM , Ansible, Create ECR Repo for store, manage, and distribute Docker container images and save it as `jenkinsfile` file under jenkins folder.

```
APP_NAME="ozguryzl"
APP_REPO_NAME="ozgur-yzl-repo/${APP_NAME}"
AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ANS_KEYPAIR="${APP_NAME}-kube-master-${BUILD_NUMBER}"
ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}.pem"
ANSIBLE_HOST_KEY_CHECKING="False"
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 6 -Prepare Automation Pipeline [Check S3 Bucket]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create an S3 bucket for Helm charts. In the bucket, create a folder called stable/myapp. The example in this pattern uses s3://${APP_NAME}-helm-charts-/stable/myapp as the target chart repository.

```
sh 'aws s3api head-bucket --bucket ${APP_NAME}-helm-charts-repo --region us-east-1'

sh 'aws s3api create-bucket --bucket ${APP_NAME}-helm-charts-repo --region us-east-1'
sh 'aws s3api put-object --bucket ${APP_NAME}-helm-charts-repo --key stable/myapp/'
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 7 -Prepare Automation Pipeline [Create Docker Registry for on AWS ECR ]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare a stage to create Docker Registry for on AWS ECR 
    
```
aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
--repository-name ${APP_REPO_NAME} \
--image-scanning-configuration scanOnPush=true \
--image-tag-mutability MUTABLE \
--region ${AWS_REGION}
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 8 -Prepare Continuous Integration (CI) Pipeline [build,push and tags for docker images]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create a folder, named jenkins, to keep and Jenkins jobs of the project.
* Prepare a script to ``package`` the app with maven Docker container and save it as `package-with-maven-container.sh` and save it under `jenkins` folder.

```bash
docker run --rm -v $HOME/target:/root/target -v $WORKSPACE:/app -w /app maven:3.9.5-amazoncorretto-17 mvn clean package
```
* Give execution permission to package-with-maven-container.sh
```bash
chmod +x package-with-maven-container.sh
```

* Prepare a stage to create ``ECR tags`` for docker images and save it as and save it under `jenkinsfile` file.

```
MVN_VERSION=sh(script:'. ${WORKSPACE}/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
env.IMAGE_TAG_OZGURYZL="${ECR_REGISTRY}/${APP_REPO_NAME}:${APP_NAME}-v${MVN_VERSION}-b${BUILD_NUMBER}"
```

* Prepare a script to build the dev docker images tagged for ECR registry and save it as `build-prod-docker-images-for-ecr.sh` and save it under `jenkins` folder. 

``` bash
docker build --force-rm -t "${IMAGE_TAG_OZGURYZL}" .
```
* Give execution permission to build-prod-docker-images-for-ecr.sh
```bash

chmod +x build-prod-docker-images-for-ecr.sh
```

* Prepare a script to push the dev docker images to the ECR repo and save it as `push-prod-docker-images-to-ecr.sh` and save it under `jenkins` folder.

```bash
# Provide credentials for Docker to login the AWS ECR and push the images
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker push "${IMAGE_TAG_OZGURYZL}"
```
* Give execution permission to push-prod-docker-images-to-ecr.sh
```bash
chmod +x push-prod-docker-images-to-ecr.sh
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 9 - Prepare Automation Pipeline [Create Helm chart]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create an helm chart named `ozguryzl_chart` under `k8s` folder.
  
```bash
cd k8s
helm create ozguryzl_chart
```

* In ``Chart.yaml``, ``set`` the `version` value(0.1.0) to `HELM_VERSION` in Chart.yaml for automation in jenkins pipeline.

* Remove all files under the petclinic_chart/templates folder.
* 
```bash
rm -r ozguryzl_chart/templates/*
```

* Add `k8s/ozguryzl_chart/values-template.yaml` file as below. 

```
IMAGE_TAG_OZGURYZL: "${IMAGE_TAG_OZGURYZL}"
```
* Create yaml files under 'ozguryzl_chart/templates/' folder for keeping the manifest files of Petclinic App on Kubernetes cluster.

* Create yaml file for petclinic-deploy.yml
```yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: petclinic
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"    
      containers:
      - name: petclinic
        image: '{{ .Values.IMAGE_TAG_OZGURYZL }}'
        ports:
        - containerPort: 8080
          hostPort: 8080
          protocol: TCP
        resources:
          requests:
            cpu: 400m
            memory: 400Mi
          limits:
            cpu: 500m
            memory: 500Mi
      imagePullSecrets:
        - name: regcred
      initContainers:
        - name: init-mysql
          image: busybox:latest
          command: ['sh', '-c', 'until nc -z mysql-server:3306; do echo waiting for mysql-server; sleep 2; done;']
          resources:
            requests:
              cpu: 200m
              memory: 200Mi
            limits:
              cpu: 300m
              memory: 300Mi
```

* Create yaml file for petclinic-service.yml
```yaml 
apiVersion: v1
kind: Service
metadata:
  name: ozguryzl-service
  labels:
    name: petclinic
spec:
  selector:
    app: petclinic
  ports:
    - name: "8080"
      nodePort: 30001
      port: 8080
      targetPort: 8080
  type: NodePort 
```

* Create yaml file for mysql-deploy.yml
```yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-db
  template:
    metadata:
      labels:
        app: mysql-db
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: mysql-db
        image: mysql:8.2
        ports:
        - containerPort: 3306
        envFrom:
        - secretRef:
            name: mysql-secret
        - configMapRef:
            name: mysql-cm
```

* Create yaml file for mysql-service.yml
```yaml 
apiVersion: v1
kind: Service
metadata:
  name: mysql-server
  labels:
    name: mysql-server
spec:
  type: ClusterIP
  selector:
    app: mysql-db
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
```

* Create yaml file for mysql-configmap.yml   
```yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-cm
data:
    MYSQL_USER: "petclinic"
    MYSQL_DATABASE: "petclinic"
```

* Create yaml file for mysql-secret.yml
```yaml 
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
stringData:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_PASSWORD: petclinic
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 10 - Prepare to connect mysql for Kubernetes Cluster
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* See application features documentation
```bash
cd /src/main/resources/
sed -i "s/localdost/mysql-server/g" application-mysql.properties
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 11 - Set up a Helm v3 chart repository in Amazon S3
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* This pattern helps you to manage Helm v3 charts efficiently by integrating the Helm v3 repository into Amazon Simple Storage Service (Amazon S3) on the Amazon Web Services (AWS) Cloud. (https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html)

* Prepare a stage to install the helm-s3 plugin for Amazon S3.

```bash
helm plugin install https://github.com/hypnoglow/helm-s3.git 
```
* Initialize the Amazon S3 Helm repository.

```bash
AWS_REGION=us-east-1 helm s3 init s3://${APP_NAME}-helm-charts-repo/stable/myapp
```
* Add the Amazon S3 repository to Helm on the client machine.

```bash
AWS_REGION=us-east-1 helm repo add stable-${APP_NAME} s3://${APP_NAME}-helm-charts-repo/stable/myapp/
```

* Package the local Helm chart.

```bash
helm package k8s/ozguryzl_chart
```

* Store the local package in the Amazon S3 Helm repository.

```bash
helm s3 push --force ozguryzl_chart-${BUILD_NUMBER}.tgz stable-${APP_NAME}
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 12 - Create Key Pair for Ansible
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepair to stage to create key pair for Ansible

```bash
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${ANS_KEYPAIR}.pem"
chmod 400 ${ANS_KEYPAIR}.pem"
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 13 - Create Infrastructure Kubernetes Cluster with Terraform
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create a folder for ansible jobs under the `main` folder.
```bash
mkdir -p infrastructure/create-kube-cluster
```

* Prepare a terraform file for kubernetes Infrastructure consisting of master server,  and save it as `main.tf` and `master.sh` under the `infrastructure/create-kube-cluster

* Create terraform file for main.tf  
```go
provider "aws" {
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # change here, optional
  name = "ozgur-yazilim"
  keyname = "yaksonkey"
  instancetype = "t3a.medium"
  ami = "ami-0e001c9271cf7f3b9"
}

resource "aws_instance" "master" {
  ami                  = local.ami
  instance_type        = local.instancetype
  key_name             = local.keyname
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  user_data            = file("master.sh")
  vpc_security_group_ids = [aws_security_group.tf-k8s-master-sec-gr.id]
  availability_zone = "us-east-1a"
  tags = {
    Name = "kube-master"
  }
}

resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2profile-${local.name}"
  role = aws_iam_role.ec2connect.name
}

resource "aws_iam_role" "ec2connect" {
  name = "ec2connect-${local.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess", "arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output kube-master-ip {
  value       = aws_instance.master.public_ip
  sensitive   = false
  description = "public ip of the kube-master"
}
```

* Create terraform file for master.sh
```go 
#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname kube-master
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=1.29.0-1.1 kubeadm=1.29.0-1.1 kubectl=1.29.0-1.1 kubernetes-cni docker.io
apt-mark hold kubelet kubeadm kubectl
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu
newgrp docker
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
mkdir /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=All
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
su - ubuntu -c 'kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml'
sudo -i -u ubuntu kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sudo -i -u ubuntu kubectl taint node kube-master node-role.kubernetes.io/control-plane:NoSchedule-
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo ./get_helm.sh
sudo apt update
sudo apt-get install python3-pip -y
sudo pip3 install --upgrade pip
sudo pip3 install boto3 botocore
```
* Prepair to stage creating automation infrastructure for Kubernetes Cluster
  
 ```bash
cd infrastructure/create-kube-cluster
sed -i "s/yaksonkey/$ANS_KEYPAIR/g" main.tf
terraform init
terraform apply -auto-approve -no-color
```

* Prepare a script to wait until the automation infrastructure is prepared for Kubernetes Cluster
  
```bash
env.id = sh(script: 'aws ec2 describe-instances --filters Name=tag-value,Values=master Name=tag-value,Values=kube-master Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text',  returnStdout:true).trim()
aws ec2 wait instance-status-ok --instance-ids $id
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 14 - Prepare Automation Pipeline [Create Ansible jobs]
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
* Create a folder for ansible jobs under the `main` folder.

```bash
mkdir -p ansible/inventory
```

* Prepare dynamic inventory file with name of `dynamic_inventory_aws_ec2.yaml` for Ansible under `ansible/inventory` folder using ec2 instances private IP addresses.

```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:Name: 
    - kube-master
  instance-state-name: running  
keyed_groups:
  - key: tags['Name']
    prefix: 'all_instances'
hostnames:
  - "ip-address"    
compose:
  ansible_user: "'ubuntu'"
```

* Create Ansible playbook for deploying application as `dev-ozguryzl-deploy-template` under `ansible/playbooks` folder.
* 
```yaml
- hosts: all_instances_kube_master
  tasks:

  - name: Create .docker folder
    file:
      path: /home/ubuntu/.docker
      state: directory
      mode: '0755'

  - name: copy the docker config file
    become: yes
    copy: 
      src: $JENKINS_HOME/.docker/config.json
      dest: /home/ubuntu/.docker/config.json

  - name: deploy ozguryzl application
    shell: |
      helm plugin install https://github.com/hypnoglow/helm-s3.git
      kubectl create ns ozguryzl-dev
      kubectl delete secret regcred -n ozguryzl-dev
      kubectl create secret generic regcred -n ozguryzl-dev \
        --from-file=.dockerconfigjson=/home/ubuntu/.docker/config.json \
        --type=kubernetes.io/dockerconfigjson
      AWS_REGION=$AWS_REGION helm repo add stable-ozguryzl s3://ozguryzl-helm-charts-repo/stable/myapp/
      AWS_REGION=$AWS_REGION helm repo update
      AWS_REGION=$AWS_REGION helm upgrade --install \
        ozguryzl-app-release stable-ozguryzl/ozguryzl_chart --version ${BUILD_NUMBER} \
        --namespace ozguryzl-dev
```
* Prepair to stage for deploying app on Kubernetes Cluster
  
 ```bash
envsubst < ansible/playbooks/dev-ozguryzl-deploy-template > ansible/playbooks/dev-ozguryzl-deploy.yaml
ansible-inventory --graph -v -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml
ansible -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml all -m ping
sleep 60
ansible-playbook -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/dev-ozguryzl-deploy.yaml
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 15 - Take a standby step
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Take a standby step to examine the infrastructure, develop the application and secure it.

```bash
        stage('Destroy the infrastructure'){
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve terminate'
                }
        }  
```           

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 16 - Deleting all local images and Destroy the infrastructure
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* 
The `post` section in a Jenkins pipeline defines actions that should be taken after the main build steps have completed. 
**`always`:** This block contains actions that should be executed regardless of whether the build succeeded or failed. It ensures that certain cleanup or post-processing tasks are always performed, irrespective of the build result.


```
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'

            echo 'Delete the Image Repository on ECR'
            sh """                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION}\
                  --force
            """

            echo 'Tear down the Kubernetes Cluster'
            sh """
            cd infrastructure/create-kube-cluster
            terraform destroy -auto-approve -no-color
            rm -rf .terraform 
            """
            echo "Delete existing key pair using AWS CLI"
            sh "aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}"
            sh "rm -rf ${ANS_KEYPAIR}.pem"            
        }
    }    
```

* You will be able to get images with http://localhost:30001. You need to get the localhost here, the EC2 instance public ip that we set up for kube-master server.
* 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 17 -  Send to mail success 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Before doing this follow step-22 and make necessary adjustments
  
* Add a 'success' step under the post to send an email if the project is successful.
  
```
        success {
            mail bcc: '', body: 'Congrats !!! CICD Pipeline is successfull.', cc: '', from: '', replyTo: '', subject: 'Test Mail', to: 'yakin68@gmail.com'
            }
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 18 - Prepair NGINX Reverse Proxy for www.devopsproje.online
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Connect to kube-master server via ssh or AWS dashboard
* The first step is to install NGINX on our system. If you are using a Linux-based system, you can usually install NGINX through your package manager
```
sudo apt update
sudo apt install nginx -y
```

* Edit Configuration File: We will define the reverse proxy configuration by editing NGINX's configuration file. This file is usually located in a place like /etc/nginx/nginx.conf or /etc/nginx/sites-available/default
```
sudo rm -rf /etc/nginx/sites-available/default
sudo nano /etc/nginx/sites-available/default
```
* Add a Short Proxy Definition: Add the main server definition that will receive requests to the NGINX configuration file. In this definition, we will redirect incoming requests to a specific server or application.

* Use 'http' instead of 'https', it was used this way due to an error in the jenkins pipeline. 
```
 server {
    listen 80;
    server_name www.devopsproje.online;

    location / {
        proxy_pass https://54.91.196.114:30001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

 server {
    listen 80;
    server_name 54.91.196.114;

    location / {
        proxy_pass https://54.91.196.114:30001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
 }
```

Check Configuration and Restart NGINX: You can use the following commands to check the configuration file and test if NGINX is running correctly.
```
sudo nginx -t
sudo systemctl restart nginx

```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 19 - Prepair NGINX Reverse Proxy for jenkins server
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Connect to jenkins server via ssh or AWS dashboard
* The first step is to install NGINX on our system. If you are using a Linux-based system, you can usually install NGINX through your package manager
```
sudo apt update
sudo apt install nginx -y
```

* Edit Configuration File: We will define the reverse proxy configuration by editing NGINX's configuration file. This file is usually located in a place like /etc/nginx/nginx.conf or /etc/nginx/sites-available/default
```
sudo rm -rf /etc/nginx/sites-available/default
sudo nano /etc/nginx/sites-available/default
```
* Add a Short Proxy Definition: Add the main server definition that will receive requests to the NGINX configuration file. In this definition, we will redirect incoming requests to a specific server or application.
```
 server {
    listen 80;
    server_name 3.239.128.187;

    location / {
        proxy_pass https://3.239.128.187:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
 }
```

Check Configuration and Restart NGINX: You can use the following commands to check the configuration file and test if NGINX is running correctly.
```
sudo nginx -t
sudo systemctl restart nginx

```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 20 - Enable SSL in Jenkins Server -Setting Domain Name and TLS for Production Pipeline with Route 53
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Cloudflare provides SSL support and is generally a preferred solution by users. Cloudflare offers advanced features for SSL/TLS encryption and security for your website. Some advantages of Cloudflare include: 1. Free SSL Certificates: Cloudflare provides free SSL/TLS certificates to encrypt your website traffic. This ensures a secure connection by enabling your website to use the HTTPS protocol.

* First move your domain to cloudflare
  
* Create and save A record for jenkins.devopsproje.online and www.devopsproje.com
  
* Choose SSL/TSL --> Overview --> Your SSL/TLS encryption mode is Flexible

* You can try different solutions, for example, you can create your own password with openssl and get 90-day free SSL certificates from https://app.zerossl.com/dashboard.

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 21 - Prepair github token after this proje 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* GitHub token is an authentication mechanism used to access GitHub's API (Application Programming Interface) on behalf of a user or a GitHub application. Tokens are typically used for automation, such as when integrating GitHub with other services or when performing repetitive tasks programmatically.

*Here's how you can generate a personal access token on GitHub:
```
Go to your GitHub account settings.
Navigate to the "Developer settings" section.
Click on "Personal access tokens".
Click the "Generate new token" button.
Give your token a descriptive name and select the desired scopes (permissions) for the token.
Click "Generate token" and authenticate if prompted.
Copy the generated token and securely store it. GitHub will not show it to you again.
You can then use this token in your scripts or applications to authenticate with GitHub's API. Make sure to keep your token secure and avoid sharing it publicly, as it grants access to your GitHub account based on the permissions you've assigned to it.
```

* Move the your project to private repo and prepair Jenkins Manege

```
* Jenkins Deashboard/Manege Jenkins/Credentials/System/Global credentials(unrestricted)/Add Credentials
* Username: copy your github token name
* Password: copy your github token 
* Description: github
* create
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## THE FINAL STEP 22 - configure Email Notification in Jenkins | Send Email using Gmail SMTP server
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Configure Email Notification in Jenkins | Send Email using Gmail SMTP server
  
```
* Go to your Google Account.
Select Security.
Under "Signing in to Google," select 2-Step Verification.
At the bottom of the page, select App passwords.
Enter a name that helps you remember where you’ll use the app password.
Select Generate.
Add the app password for SMTP GMAIL account instead of your GMAIL account password
```

``` 
Go to the Jenkins home page and click Manage Jenkins.
Select Configure System.
Scroll down to the Email Notification section.
Enter the SMTP server name as smtp.gmail.com
Click Advanced.
Select Use SMTP Authentication.
Enter your Gmail ID and password.
Select Use SSL.
Enter 465 as the SMTP port.
Enter your email ID as the Reply-to-Address.
Send Test Email from Jenkins- Output --> Email was successfully sent
Click Save.
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 23 - Install Rancher App on Kubernetes Cluster
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 24 - Monitoring with Prometheus and Grafana
# # # # # # # # # # # # # # # # # # # # # # # # # # # #