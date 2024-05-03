# Microservices CI/CD Pipeline

## Description

This project aims to create full CI/CD Pipeline for microservices based applications using Spring Petclinic Microservices Application. [Spring Petclinic Microservices Application](https://github.com/spring-petclinic/spring-petclinic-htmx.git).

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 1 - Prepair GitHub Repository for your proje 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


* create a repo named ozguryzl-tasg. No readme.md.

``` bash
git clone https://github.com/yakin68/ozguryzl-task.git 
```

* Connect to the [Spring Petclinic Microservices Application] (https://github.com/spring-petclinic/spring-petclinic-htmx.git. repo and copy the Spring Petclinic Microservices Application to the repo we created. If you want, you can "fork" or download the repo.

* What should be taken into consideration here is to delete the ".git" directory in the "Spring Petclinic Microservices Application" report and the ".git" directory in the "git clone https://github.com/yakin68/ozguryzl-tasg.git" locale clone when copying the application. must. Otherwise, you may receive errors on the project. You need to do this if you want the project to be yours and you want to make changes to it.

```bash
cd ozguryzl-tasg
rm -rf .git
```

*  Enter the following commands from the terminal so that it does not always ask who are you.

```bash
git init  
git add .
git config --global user.email "yakin68@gmail.com"
git config --global user.name "yakin68"
git commit -m "first commit"
git remote add origin https://[github username]:[your-token]@github.com/yakin68/ozguryzl-tasg.git  
```

* Do not push the token to github and do not share it with anyone. *This command is used to add a remote repository to a Git repository. In the relevant example, a remote repository is added with the git remote add command. The name origin is usually used by default for the main remote repository. You specify your GitHub username in the [github username] section, your GitHub account's access token in the [your-token] section, and the repository address you want to add in the yakin68/ozguryzl-tasg.git section. If you use this command, you specify your GitHub username and If you insert your access token correctly, you will link a local Git repository to the remote repository "yakin68/ozguryzl-tasg" on GitHub. This allows you to push the changes you made locally to this remote repository and pull them from the remote repository to the local repository.

git push origin main
```


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 2 - Terraform Dosyalarını Hazırlayın ve Uygulamayı manual test edelim. [ Bu adımı geçebilirsiniz.]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Before preparing the microservice architecture, it is a best-practice method to manually check whether it works or not. You can also follow readme.md in the app's repo. For this purpose, 2 virtual machines were requested to be set up in the tag, 1 virtual machine will be deleted after it is created for testing.

* Terraform files are prepared under 'infrastructure' in the (https://github.com/yakin68/ozguryzl-tasg.git) repo.
 
* Run the terraform files in the /infrastructure/test-of-petclinic folder. (This will stand up a virtual machine for testing.)
   
``` bash  
  terraform init 
  terraform apply -auto-approve
```

* connect to the virtual machine (either vscode or aws console etc.) and run the command below for app testing
  
``` bash  
git clone https://github.com/spring-petclinic-htmx/spring-petclinic-htmx.git
cd spring-petclinic-htmx
./mvnw package
java -jar target/*.jar
```

* When we examine readme.md in the [Spring Petclinic Microservices Application] repo, you will be able to get images with https://localhost:8080. You need to get the localhost here, the EC2 instance public ip that we set up for testing. After the image is taken, let's enter the command.

``` bash  
  terraform destroy -auto-approve
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 3 - install jenkins-server 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


* Run the terraform files in the /infrastructure/jenkins-server folder. (This will create a virtual machine for the jenkin server.)


``` bash  
  terraform init 
  terraform apply -auto-approve
```

* Get the initial administrative password.
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
* Enter the temporary password to unlock the Jenkins.

* Install suggested plugins.

* Create first admin user.

* Open your Jenkins dashboard and navigate to Manage Jenkins >> Plugins >> Available tab

* Search and select GitHub Integration, Docker, Docker Pipeline, Email Extension plugins, then click Install without restart. Note: No need to install the other Git plugin which is already installed can be seen under Installed tab.


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 4 - Prepare Dockerfiles for Microservices 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare a Dockerfile file in the main directory.

```
FROM amazoncorretto:17-alpine3.18
WORKDIR /app
COPY ./target/*.jar /app.jar
ENV SPRING_PROFILES_ACTIVE mysql
EXPOSE 8080
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 -Prepare Automation Pipeline [environment]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare environment, S3 bucket for HELM , Create ECR Repo for store, manage, and distribute Docker container images and save it under `jenkinsfile` file. 

```
pipeline {
    agent any
    environment {
        APP_NAME="petclinic"
        APP_REPO_NAME="ozgur-yazilim-repo/${APP_NAME}"
        AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR="petclinic-${APP_NAME}-${BUILD_NUMBER}.key"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
        ANSIBLE_HOST_KEY_CHECKING="False"
    }
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 -Prepare Automation Pipeline [Check S3 Bucket]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    stages {    
        stage('Check S3 Bucket') {
            steps {
                script {
                    try {
                        sh 'aws s3api head-bucket --bucket petclinic-helm-charts-yakin --region us-east-1'
                        echo 'Bucket already exists'
                    } catch (Exception e) {
                        echo 'Bucket does not exist. Creating...'
                        sh 'aws s3api create-bucket --bucket petclinic-helm-charts-yakin --region us-east-1'
                        sh 'aws s3api put-object --bucket petclinic-helm-charts-yakin --key stable/myapp/'
                    }
                }
            }
        }  
```
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 -Prepare Automation Pipeline [Create ECR Repo]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        stage('Create ECR Repo') {
            steps {
                echo "Creating ECR Repo for ${APP_NAME} app"
                sh '''
                aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
                         aws ecr create-repository \
                         --repository-name ${APP_REPO_NAME} \
                         --image-scanning-configuration scanOnPush=true \
                         --image-tag-mutability MUTABLE \
                         --region ${AWS_REGION}
                '''
            }
        }          
    }
}    
```    
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 -Prepare Automation Pipeline [build,push and tags for docker images]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Prepare a script to ``package`` the app with maven Docker container and save it as `package-with-maven-container.sh` and save it under `jenkins` folder.

```bash
docker run --rm -v $HOME/.m2:/root/.m2 -v $WORKSPACE:/app -w /app maven:3.9.5-amazoncorretto-17 mvn clean package
```
* Give execution permission to package-with-maven-container.sh
```bash
chmod +x package-with-maven-container.sh
```

* Prepare a stage to create ``ECR tags`` for docker images and save it as and save it under `jenkinsfile` file.

```
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_PETCLINIC="${ECR_REGISTRY}/${APP_REPO_NAME}:yakin-petclinic-v${MVN_VERSION}-b${BUILD_NUMBER}"
                }
            }
        }
```

* Prepare a script to build the dev docker images tagged for ECR registry and save it as `build-prod-docker-images-for-ecr.sh` and save it under `jenkins` folder. 

``` bash
docker build --force-rm -t "${IMAGE_TAG_PETCLINIC}" .
```
* Give execution permission to build-prod-docker-images-for-ecr.sh
```bash
chmod +x build-prod-docker-images-for-ecr.sh
```

* Prepare a script to push the dev docker images to the ECR repo and save it as `push-prod-docker-images-to-ecr.sh` and save it under `jenkins` folder.

```bash
# Provide credentials for Docker to login the AWS ECR and push the images
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} 
docker push "${IMAGE_TAG_ADMIN_SERVER}"
```
* Give execution permission to push-prod-docker-images-to-ecr.sh
```bash
chmod +x push-prod-docker-images-to-ecr.sh
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - STEP 5 -Prepare Automation Pipeline [Create Key Pair for Ansible]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create Key Pair for Ansible
```
        stage('Create Key Pair for Ansible') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                sh "aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${ANS_KEYPAIR}"
                sh "chmod 400 ${ANS_KEYPAIR}"
            }
        }
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - STEP 5 -Prepare Automation Pipeline [Create Infrastructure Kubernetes Cluster]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
* Prepare a terraform file for kubernetes Infrastructure consisting of master server,  and save it as `main.tf` and `master.sh` under the `infrastructure/create-kube-cluster
  
```go for main.tf
provider "aws" {
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # change here, optional
  name = "ozguryazilim"
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
    Project = "kube-ansible"
    Role = "master"
    Id = "1"
    environment = "ozgur-yazilim"
  }
}


resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2connectprofile-${local.name}"
  role = aws_iam_role.ec2connect.name
}

resource "aws_iam_role" "ec2connect" {
  name = "ec2connect-${local.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
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
```

```go for master.sh
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

sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo ./get_helm.sh
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - STEP 5 -Prepare Automation Pipeline [Create Infrastructure Kubernetes Cluster]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create Infrastructure Kubernetes Cluster and Deploy App on Kubernetes cluster'
```
        stage('Create Infrastructure Kubernetes Cluster ') {
            steps {
                echo 'Creating QA Automation Infrastructure for Dev Environment'
                sh """
                    cd infrastructure/create-kube-cluster
                    sed -i "s/yaksonkey/$ANS_KEYPAIR/g" main.tf
                    terraform init
                    terraform apply -auto-approve -no-color
                """
                script {
                    echo "Kubernetes Master is not UP and running yet."
                    env.id = sh(script: 'aws ec2 describe-instances --filters Name=tag-value,Values=master Name=tag-value,Values=tera-kube-ans Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text',  returnStdout:true).trim()
                    sh 'aws ec2 wait instance-status-ok --instance-ids $id'
                }
            }
        }
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - STEP 5 -Prepare Automation Pipeline [Create Helm chart]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
* Create an helm chart named `petclinic_chart` under `k8s` folder.
```bash
cd k8s
helm create petclinic_chart
```
* Add `k8s/petclinic_chart/values-template.yaml` file as below.
```yaml for values-template.yaml
IMAGE_TAG_PETCLINIC: "${IMAGE_TAG_PETCLINIC}"
DNS_NAME: "www.devopsturkiye.store"
```
* In ``Chart.yaml``, ``set`` the `version` value(0.1.0) to `HELM_VERSION` in Chart.yaml for automation in jenkins pipeline.

* Remove all files under the petclinic_chart/templates folder.
```bash
rm -r petclinic_chart/templates/*

* Create yaml files under 'petclinic_chart/templates/' folder for keeping the manifest files of Petclinic App on Kubernetes cluster.
```

```yaml for petclinic-deploy.yml
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
      containers:
      - name: petclinic
        image: '{{ .Values.IMAGE_TAG_PETCLINIC }}'
        ports:
        - containerPort: 8080
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
```yaml for petclinic-service.yml
apiVersion: v1
kind: Service
metadata:
  name: petclinic-service
  labels:
    name: petclinic
spec:
  selector:
    app: petclinic
  ports:
  - port: 8080
    targetPort: 8080

```yaml for mysql-deploy.yml
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

```yaml for mysql-service.yml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
stringData:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_PASSWORD: petclinic

```yaml for mysql-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-cm
data:
    MYSQL_USER: "petclinic"
    MYSQL_DATABASE: "petclinic"

```yaml for mysql-secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
stringData:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_PASSWORD: petclinic
  
```yaml for ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway
spec:
  ingressClassName: nginx
  rules:
    - host: '{{ .Values.DNS_NAME }}'
      http:
        paths:
          - backend:
              service:
                name: petclinic-service
                port:
                  number: 8080
            path: /
            pathType: Prefix
status:
  loadBalancer: {}
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - Prepare Automation Pipeline [Create Ansible jobs]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
* Create a folder for ansible jobs under the `main` folder.

```bash
mkdir -p ansible/inventory
```

* Prepare dynamic inventory file with name of `dynamic_inventory_aws_ec2.yaml` for Ansible under `ansible/inventory` folder using ec2 instances private IP addresses.

```yaml
plugin: aws_ec2
regions:
  - "us-east-1"
filters:
  tag:Project: kube-ansible
  tag:environment: ozgur-yazilim
  instance-state-name: running
keyed_groups:
  - key: tags['Project']
    prefix: 'all_instances'
  - key: tags['Role']
    prefix: 'role'
hostnames:
  - "ip-address"
compose:
  ansible_user: "'ubuntu'"
```

* Create Ansible playbook for deploying application as `dev-petclinic-deploy-template` under `ansible/playbooks` folder.
```yaml
- hosts: role_master
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

  - name: deploy petclinic application
    shell: |
      helm plugin install https://github.com/hypnoglow/helm-s3.git
      kubectl create ns petclinic-dev
      kubectl delete secret regcred -n petclinic-dev || true
      kubectl create secret generic regcred -n petclinic-dev \
        --from-file=.dockerconfigjson=/home/ubuntu/.docker/config.json \
        --type=kubernetes.io/dockerconfigjson
      AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-yakin/stable/myapp/
      AWS_REGION=$AWS_REGION helm repo update
      AWS_REGION=$AWS_REGION helm upgrade --install \
        petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
        --namespace petclinic-dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 5 - Prepare Automation Pipeline [Deploying App on Kubernetes]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #        
        stage('Deploy App on Kubernetes cluster'){
            steps {
                echo 'Deploying App on Kubernetes'
                sh "envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml"
                sh "sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml"
                sh "helm plugin install https://github.com/hypnoglow/helm-s3.git || true"
                sh "AWS_REGION=us-east-1 helm s3 init s3://petclinic-helm-charts-yakin/stable/myapp || true"
                sh "AWS_REGION=us-east-1 helm repo add stable-petclinicapp s3://petclinic-helm-charts-yakin/stable/myapp/ || true"
                sh "helm package k8s/petclinic_chart"
                sh "helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic"
                sh "envsubst < ansible/playbooks/dev-petclinic-deploy-template > ansible/playbooks/dev-petclinic-deploy.yaml"
                sh "sleep 60"    
                sh "ansible-playbook -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/dev-petclinic-deploy.yaml"

            }
        }        
```
```
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 12 - Destroy the infrastructure
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

```
        stage('Destroy the infrastructure'){
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve terminate'
                }
                sh """
                docker image prune -af
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION} \
                  --force
                """
                echo 'Tear down the Kubernetes Cluster'
                sh """
                cd infrastructure/create-kube-cluster
                terraform destroy -auto-approve -no-color
                rm -rf .terraform
                rm -rf .terraform.lock.hcl
                rm -rf terraform.tfstate
                rm -rf terraform.tfstate.backup
                """                
            }
        }
```           

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 12 - Deleting all local images and Send to mail success
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }

        success {
            mail bcc: '', body: 'Congrats !!! CICD Pipeline is successfull.', cc: '', from: '', replyTo: '', subject: 'Test Mail', to: 'yakin68@gmail.com'
            }
    }


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 13 - Prepair github token after this proje 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* create token from github
* Move the yout project to private repo
* Jenkins Deashboard/Manege Jenkins/Credentials/System/Global credentials(unrestricted)/Add Credentials
* Username: copy your github token name
* Password: copy your github token 
* Description: github
* create

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 14 - Create Docker Registry for Dev Manually
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
