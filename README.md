# Microservices CI/CD Pipeline

## Description

This project aims to create full CI/CD Pipeline for microservices based applications using Spring Petclinic Microservices Application. [Spring Petclinic Microservices Application](https://github.com/spring-petclinic/spring-petclinic-htmx.git).

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 1 - Prepair GitHub Repository for your proje 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


* create a repo named ozgur-yazilim-tasg. No readme.md.

``` bash
git clone https://github.com/yakin68/ozgur-yazilim-tasg.git 
```

* Connect to the [Spring Petclinic Microservices Application] (https://github.com/spring-petclinic/spring-petclinic-htmx.git. repo and copy the Spring Petclinic Microservices Application to the repo we created. If you want, you can "fork" or download the repo.

* What should be taken into consideration here is to delete the ".git" directory in the "Spring Petclinic Microservices Application" report and the ".git" directory in the "git clone https://github.com/yakin68/ozgur-yazilim-tasg.git" locale clone when copying the application. must. Otherwise, you may receive errors on the project. You need to do this if you want the project to be yours and you want to make changes to it.

```bash
cd ozgur-yazilim-tasg
rm -rf .git
```

*  Enter the following commands from the terminal so that it does not always ask who are you.

```bash
git init  
git add .
git config --global user.email "yakin68@gmail.com"
git config --global user.name "yakin68"
git commit -m "first commit"
git remote add origin https://[github username]:[your-token]@github.com/yakin68/ozgur-yazilim-tasg.git  

* token ile github push yapmayın ve kimse ile paylaşmayın. *Bu komut, bir Git deposuna bir uzak depo eklemek için kullanılır. İlgili örnekte, git remote add komutu ile bir uzak depo eklenir. origin ismi genellikle varsayılan olarak ana uzak depo için kullanılır. [github username] kısmına GitHub kullanıcı adınızı, [your-token] kısmına GitHub hesabınızın erişim belirtecinizi (access token) ve yakin68/ozgur-yazilim-tasg.git kısmına da eklemek istediğiniz depo adresini belirtiyorsunuz.Eğer bu komutu kullanırsanız ve GitHub kullanıcı adınızı ve erişim belirtecinizi doğru şekilde yerine koyarsanız, yerel bir Git deposunu GitHub daki "yakin68/ozgur-yazilim-tasg" adlı uzak depoya bağlamış olursunuz. Bu, yerelde yaptığınız değişiklikleri bu uzak depoya itmenize (push) ve uzak depodan yerel depoya çekmenize (pull) olanak sağlar.

git push origin main
```


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
##  STEP 2 - Terraform Dosyalarını Hazırlayın ve Uygulamayı manual test edelim. [ Bu adımı geçebilirsiniz.]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Before preparing the microservice architecture, it is a best-practice method to manually check whether it works or not. You can also follow readme.md in the app's repo. For this purpose, 2 virtual machines were requested to be set up in the tag, 1 virtual machine will be deleted after it is created for testing.

* Terraform files are prepared under 'infrastructure' in the (https://github.com/yakin68/ozgur-yazilim-tasg.git) repo.
 
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

* Prepare dynamic inventory file with name of `dev_stack_dynamic_inventory_aws_ec2.yaml` for Ansible under `ansible/inventory` folder using ec2 instances private IP addresses.

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
                sh "helm repo add stable-petclinic s3://petclinic-helm-charts-yakin/stable/myapp/"
                sh "helm package k8s/petclinic_chart"
                sh "helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic"
                sh "envsubst < ansible/playbooks/dev-petclinic-deploy-template > ansible/playbooks/dev-petclinic-deploy.yaml"
                sh "sleep 60"    
                sh "ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/dev-petclinic-deploy.yaml"
            }
        }        
```
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
## STEP 13 - Prepare 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 14 - Create Docker Registry for Dev Manually
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

``

* Create a ``Jenkins Job`` to create Docker Registry for `dev` on AWS ECR manually.

```yml
- job name: create-ecr-docker-registry-for-dev
- job type: Freestyle project
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-dev"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
--repository-name ${APP_REPO_NAME} \
--image-scanning-configuration scanOnPush=false \
--image-tag-mutability MUTABLE \
--region ${AWS_REGION}
```

* Prepare a script to create Docker Registry for `dev` on AWS ECR and save it as `create-ecr-docker-registry-for-dev.sh` under `infrastructure` folder.

``` bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-dev"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
--repository-name ${APP_REPO_NAME} \
--image-scanning-configuration scanOnPush=false \
--image-tag-mutability MUTABLE \
--region ${AWS_REGION}
```

* Commit the change, then push the script to the remote repo.

``` bash
git add .
git commit -m 'added script for creating ECR registry for dev'
git push --set-upstream origin feature/STEP-14
git checkout dev
git merge feature/STEP-14
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 15 - Create a QA Automation Environment with Kubernetes - Part-1
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-15` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-15
git checkout feature/STEP-15
```

- Create a folder for kubernetes infrastructure with the name of `dev-k8s-terraform` under the `infrastructure` folder.

- Prepare a terraform file for kubernetes Infrastructure consisting of 1 master, 2 Worker Nodes and save it as `main.tf` under the `infrastructure/dev-k8s-terraform`.

```go
provider "aws" {
  region  = "us-east-1"
}

variable "sec-gr-mutual" {
  default = "petclinic-k8s-mutual-sec-group"
}

variable "sec-gr-k8s-master" {
  default = "petclinic-k8s-master-sec-group"
}

variable "sec-gr-k8s-worker" {
  default = "petclinic-k8s-worker-sec-group"
}

data "aws_vpc" "name" {
  default = true
}

resource "aws_security_group" "petclinic-mutual-sg" {
  name = var.sec-gr-mutual
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    self = true
  }

    ingress {
    protocol = "udp"
    from_port = 8472
    to_port = 8472
    self = true
  }

    ingress {
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    self = true
  }

}

resource "aws_security_group" "petclinic-kube-worker-sg" {
  name = var.sec-gr-k8s-worker
  vpc_id = data.aws_vpc.name.id


  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kube-worker-secgroup"
  }
}

resource "aws_security_group" "petclinic-kube-master-sg" {
  name = var.sec-gr-k8s-master
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 6443
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 10257
    to_port = 10257
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 10259
    to_port = 10259
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "kube-master-secgroup"
  }
}

resource "aws_iam_role" "petclinic-master-server-s3-role" {
  name               = "petclinic-master-server-role"
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

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}

resource "aws_iam_instance_profile" "petclinic-master-server-profile" {
  name = "petclinic-master-server-profile"
  role = aws_iam_role.petclinic-master-server-s3-role.name
}

resource "aws_instance" "kube-master" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    iam_instance_profile = aws_iam_instance_profile.petclinic-master-server-profile.name
    vpc_security_group_ids = [aws_security_group.petclinic-kube-master-sg.id, aws_security_group.petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-c41ba589"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "kube-master"
        Project = "tera-kube-ans"
        Role = "master"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "worker-1" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.petclinic-kube-worker-sg.id, aws_security_group.petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-c41ba589"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-1"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "worker-2" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.petclinic-kube-worker-sg.id, aws_security_group.petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-c41ba589"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-2"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "2"
        environment = "dev"
    }
}

output kube-master-ip {
  value       = aws_instance.kube-master.public_ip
  sensitive   = false
  description = "public ip of the kube-master"
}

output worker-1-ip {
  value       = aws_instance.worker-1.public_ip
  sensitive   = false
  description = "public ip of the worker-1"
}

output worker-2-ip {
  value       = aws_instance.worker-2.public_ip
  sensitive   = false
  description = "public ip of the worker-2"
}
```

- Commit the change, then push the terraform file (main.tf) to the remote repo.

```bash
git add .
git commit -m 'added dev-k8s-terraform  for kubernetes infrastructure'
git push --set-upstream origin feature/STEP-15
git checkout dev
git merge feature/STEP-15
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 16 - Create a QA Automation Environment with Kubernetes - Part-2
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-16` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-16
git checkout feature/STEP-16
git push --set-upstream origin feature/STEP-16
```

- Create a ``Jenkins Job`` to test `bash` scripts creating QA Automation Infrastructure for `dev` manually.

```yml
- job name: test-creating-qa-automation-infrastructure
- job type: Freestyle project
- GitHub project: https://github.com/[your-github-account]/petclinic-microservices
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */feature/STEP-16
- Build Environment: Add timestamps to the Console Output
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
echo $PATH
whoami
PATH="$PATH:/usr/local/bin"
python3 --version
pip3 --version
ansible --version
aws --version
terraform --version
```

  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test creating key pair for `ansible`. (Click `Configure`)

```bash
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
AWS_REGION="us-east-1"
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query "KeyMaterial" --output text > ${ANS_KEYPAIR}
chmod 400 ${ANS_KEYPAIR}
```
  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test creating kubernetes infrastructure with terraform. (Click `Configure`)

```bash
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
AWS_REGION="us-east-1"
cd infrastructure/dev-k8s-terraform
sed -i "s/clarus/$ANS_KEYPAIR/g" main.tf
terraform init
terraform apply -auto-approve -no-color
```
  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test SSH connection with one of the instances.(Click `Configure`)

```bash
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${WORKSPACE}/${ANS_KEYPAIR} ubuntu@172.31.91.243 hostname
```
  * Click `Save`

  * Click `Build Now`

- Create a folder for ansible jobs under the `Jenkins` folder.

```bash
mkdir -p ansible/inventory
```

- Prepare static inventory file with name of `hosts.ini` for Ansible under `ansible/inventory` folder using Docker machines private IP addresses.

```ini
172.31.91.243   ansible_user=ubuntu  
172.31.87.143   ansible_user=ubuntu
172.31.90.30    ansible_user=ubuntu
```

- Commit the change, then push to the remote repo.

```bash
git add .
git commit -m 'added ansible static inventory host.ini for testing'
git push --set-upstream origin feature/STEP-16
```

- Configure `test-creating-qa-automation-infrastructure` job and replace the existing script with the one below in order to test ansible by pinging static hosts.

```bash
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
export ANSIBLE_INVENTORY="${WORKSPACE}/ansible/inventory/hosts.ini"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible all -m ping
```

- Prepare dynamic inventory file with name of `dev_stack_dynamic_inventory_aws_ec2.yaml` for Ansible under `ansible/inventory` folder using ec2 instances private IP addresses.

```yaml
plugin: aws_ec2
regions:
  - "us-east-1"
filters:
  tag:Project: tera-kube-ans
  tag:environment: dev
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

- Commit the change, then push the ansible dynamic inventory files to the remote repo.

```bash
git add .
git commit -m 'added ansible dynamic inventory files for dev environment'
git push
```

- Configure `test-creating-qa-automation-infrastructure` job and replace the existing script with the one below in order to check the Ansible dynamic inventory for `dev` environment. (Click `Configure`)

```bash
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
PATH="$PATH:/usr/local/bin"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-inventory -v -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml --graph
```
  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test all instances within dev dynamic inventory by pinging static hosts. (Click `Configure`)

```bash
# Test dev dynamic inventory by pinging
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
PATH="$PATH:/usr/local/bin"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml all -m ping
```
  * Click `Save`

  * Click `Build Now`

- Create an ansible playbook to install kubernetes and save it as `k8s_setup.yaml` under `ansible/playbooks` folder.

```yaml
- hosts: all
  become: true
  tasks:

  - name: change hostnames
    shell: "hostnamectl set-hostname {{ hostvars[inventory_hostname]['private_dns_name'] }}"

  - name: Enable the nodes to see bridged traffic
    shell: |
      cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward                 = 1
      EOF
      sysctl --system

  - name: update apt-get
    shell: apt-get update

  - name: Install packages that allow apt to be used over HTTPS
    apt:
      name: "{{ packages }}"
      state: present
      update_cache: yes
    vars:
      packages:
      - apt-transport-https  
      - curl
      - ca-certificates

  - name: update apt-get and install kube packages
    shell: |
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
      apt-get update -q && \
      apt-get install -qy kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1 kubernetes-cni docker.io
      apt-mark hold kubelet kubeadm kubectl

  - name: Add ubuntu to docker group
    user:
      name: ubuntu
      group: docker

  - name: Restart docker and enable
    service:
      name: docker
      state: restarted
      enabled: yes

  # change the Docker cgroup driver by creating a configuration file `/etc/docker/daemon.json` 
  # and adding the following line then restart deamon, docker and kubelet

  - name: change the Docker cgroup
    shell: |
      mkdir /etc/containerd
      containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
      sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

  - name: Restart containerd and enable
    service:
      name: containerd
      state: restarted
      enabled: yes


- hosts: role_master
  tasks:
      
  - name: pull kubernetes images before installation
    become: yes
    shell: kubeadm config images pull

  - name: initialize the Kubernetes cluster using kubeadm
    become: true
    shell: |
      kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=All
    
  - name: Setup kubeconfig for ubuntu user
    become: true
    command: "{{ item }}"
    with_items:
     - mkdir -p /home/ubuntu/.kube
     - cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
     - chown ubuntu:ubuntu /home/ubuntu/.kube/config

  - name: Install flannel pod network
    remote_user: ubuntu
    shell: kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

  - name: Generate join command
    become: true
    command: kubeadm token create --print-join-command
    register: join_command_for_workers

  - debug: msg='{{ join_command_for_workers.stdout.strip() }}'

  - name: register join command for workers
    add_host:
      name: "kube_master"
      worker_join: "{{ join_command_for_workers.stdout.strip() }}"

  - name: install Helm 
    shell: |
      cd /home/ubuntu
      curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
      chmod 777 get_helm.sh
      ./get_helm.sh

- hosts: role_worker
  become: true
  tasks:

  - name: Join workers to cluster
    shell: "{{ hostvars['kube_master']['worker_join'] }}"
    register: result_of_joining

  - debug: msg='{{ result_of_joining.stdout }}'
```

- Commit the change, then push the ansible playbooks to the remote repo.

```bash
git add .
git commit -m 'added ansible playbooks for dev environment'
git push
```

- Configure `test-creating-qa-automation-infrastructure` job and replace the existing script with the one below in order to test the playbooks to create a Kubernetes cluster. (Click `Configure`)

```bash
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
PATH="$PATH:/usr/local/bin"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
# k8s setup
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml
```
  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test tearing down the Kubernetes cluster infrastructure. (Click `Configure`)

```bash
cd infrastructure/dev-k8s-terraform
terraform destroy -auto-approve -no-color
```
  * Click `Save`

  * Click `Build Now`

- After running the job above, replace the script with the one below in order to test deleting existing key pair using AWS CLI with following script. (Click `Configure`)

```bash
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
AWS_REGION="us-east-1"
aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}
```
  * Click `Save`

  * Click `Build Now`

- Create a script to create QA Automation infrastructure and save it as `create-qa-automation-environment.sh` under `infrastructure` folder. (This script shouldn't be used in one time. It should be applied step by step like above)

```bash
# Environment variables
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test-dev.key"
AWS_REGION="us-east-1"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
# Create key pair for Ansible
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query "KeyMaterial" --output text > ${ANS_KEYPAIR}
chmod 400 ${ANS_KEYPAIR}
# Create infrastructure for kubernetes
cd infrastructure/dev-k8s-terraform
terraform init
terraform apply -auto-approve -no-color
# Install k8s cluster on the infrastructure
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml
# Build, Deploy, Test the application
# Tear down the k8s infrastructure
cd infrastructure/dev-k8s-terraform
terraform destroy -auto-approve -no-color
# Delete key pair
aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}
```

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added scripts for qa automation environment'
git push
git checkout dev
git merge feature/STEP-16
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 17 - Prepare Petlinic Kubernetes YAML Files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-17` branch from `dev`.

``` bash
git checkout dev
git branch feature/STEP-17
git checkout feature/STEP-17
```

* Create a folder with name of `k8s` under `Jenkins` folder for keeping the manifest files of Petclinic App on Kubernetes cluster.

* Create a `docker-compose.yml` under `k8s` folder with the following content as to be used in conversion the k8s files.

```yaml
version: '3'
services:
  config-server:
    image: "{{ .Values.IMAGE_TAG_CONFIG_SERVER }}"
    ports:
     - 8888:8888
    labels:
      kompose.image-pull-secret: "regcred"
  discovery-server:
    image: "{{ .Values.IMAGE_TAG_DISCOVERY_SERVER }}"
    ports:
     - 8761:8761
    labels:
      kompose.image-pull-secret: "regcred"
  customers-service:
    image: "{{ .Values.IMAGE_TAG_CUSTOMERS_SERVICE }}"
    deploy:
      replicas: 2
    ports:
    - 8081:8081
    labels:
      kompose.image-pull-secret: "regcred"
  visits-service:
    image: "{{ .Values.IMAGE_TAG_VISITS_SERVICE }}"
    deploy:
      replicas: 2
    ports:
     - 8082:8082
    labels:
      kompose.image-pull-secret: "regcred"
  vets-service:
    image: "{{ .Values.IMAGE_TAG_VETS_SERVICE }}"
    deploy:
      replicas: 2
    ports:
     - 8083:8083
    labels:
      kompose.image-pull-secret: "regcred"
  api-gateway:
    image: "{{ .Values.IMAGE_TAG_API_GATEWAY }}"
    deploy:
      replicas: 1
    ports:
     - 8080:8080
    labels:
      kompose.image-pull-secret: "regcred"
      kompose.service.expose: "{{ .Values.DNS_NAME }}"
      kompose.service.expose.ingress-class-name: "nginx"
      kompose.service.type: "nodeport"
      kompose.service.nodeport.port: "30001"
  tracing-server:
    image: openzipkin/zipkin
    ports:
     - 9411:9411
  admin-server:
    image: "{{ .Values.IMAGE_TAG_ADMIN_SERVER }}"
    ports:
     - 9090:9090
    labels:
      kompose.image-pull-secret: "regcred"
  hystrix-dashboard:
    image: "{{ .Values.IMAGE_TAG_HYSTRIX_DASHBOARD }}"
    ports:
     - 7979:7979
    labels:
      kompose.image-pull-secret: "regcred"
  grafana-server:
    image: "{{ .Values.IMAGE_TAG_GRAFANA_SERVICE }}"
    ports:
    - 3000:3000
    labels:
      kompose.image-pull-secret: "regcred"
  prometheus-server:
    image: "{{ .Values.IMAGE_TAG_PROMETHEUS_SERVICE }}"
    ports:
    - 9091:9090
    labels:
      kompose.image-pull-secret: "regcred"

  mysql-server:
    image: mysql:5.7.8
    environment: 
      MYSQL_ROOT_PASSWORD: petclinic
      MYSQL_DATABASE: petclinic
    ports:
    - 3306:3306
```

* Install [conversion tool](https://kompose.io/installation/) named `Kompose` on your Jenkins Server. [User Guide](https://kompose.io/user-guide/#user-guide)

```bash
curl -L https://github.com/kubernetes/kompose/releases/download/v1.31.2/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/local/bin/kompose
kompose version
```

* Install Helm [version 3+](https://github.com/helm/helm/releases) on Jenkins Server. [Introduction to Helm](https://helm.sh/docs/intro/). [Helm Installation](https://helm.sh/docs/intro/install/).

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

* Create an helm chart named `petclinic_chart` under `k8s` folder.

```bash
cd k8s
helm create petclinic_chart
```

* Remove all files under the petclinic_chart/templates folder.

```bash
rm -r petclinic_chart/templates/*
```
  
* Convert the `docker-compose.yml` into k8s/petclinic_chart/templates objects and save under `k8s/petclinic_chart` folder.

```bash
kompose convert -f docker-compose.yml -o petclinic_chart/templates
```

* Update deployment files with `init-containers` to launch microservices in sequence. See [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

```yaml
# for discovery server
      initContainers:
        - name: init-config-server
          image: busybox
          command: ['sh', '-c', 'until nc -z config-server:8888; do echo waiting for config-server; sleep 2; done;']
# for admin-server, api-gateway, customers-service, hystrix-dashboard, vets-service and visits service
      initContainers:
        - name: init-discovery-server
          image: busybox
          command: ['sh', '-c', 'until nc -z discovery-server:8761; do echo waiting for discovery-server; sleep 2; done;']
``` 

* Update `spec.rules.host` field of `api-gateway-ingress.yaml` file and add `ingressClassName: nginx` field under the `spec` field as below.

```yaml
spec:
  ingressClassName: nginx
  rules:
    - host: '{{ .Values.DNS_NAME }}'
      ...
```

* Add `k8s/petclinic_chart/values-template.yaml` file as below.

```yaml
IMAGE_TAG_CONFIG_SERVER: "${IMAGE_TAG_CONFIG_SERVER}"
IMAGE_TAG_DISCOVERY_SERVER: "${IMAGE_TAG_DISCOVERY_SERVER}"
IMAGE_TAG_CUSTOMERS_SERVICE: "${IMAGE_TAG_CUSTOMERS_SERVICE}"
IMAGE_TAG_VISITS_SERVICE: "${IMAGE_TAG_VISITS_SERVICE}"
IMAGE_TAG_VETS_SERVICE: "${IMAGE_TAG_VETS_SERVICE}"
IMAGE_TAG_API_GATEWAY: "${IMAGE_TAG_API_GATEWAY}"
IMAGE_TAG_ADMIN_SERVER: "${IMAGE_TAG_ADMIN_SERVER}"
IMAGE_TAG_HYSTRIX_DASHBOARD: "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
IMAGE_TAG_GRAFANA_SERVICE: "${IMAGE_TAG_GRAFANA_SERVICE}"
IMAGE_TAG_PROMETHEUS_SERVICE: "${IMAGE_TAG_PROMETHEUS_SERVICE}"
DNS_NAME: "DNS Name of your application"
```

### Set up a Helm v3 chart repository in Amazon S3

* This pattern helps you to manage Helm v3 charts efficiently by integrating the Helm v3 repository into Amazon Simple Storage Service (Amazon S3) on the Amazon Web Services (AWS) Cloud. (https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html)

* Create an ``S3 bucket`` for Helm charts. In the bucket, create a ``folder`` called ``stable/myapp``. The example in this pattern uses s3://petclinic-helm-charts-<put-your-name>/stable/myapp as the target chart repository.

```bash
aws s3api create-bucket --bucket petclinic-helm-charts-<put-your-name> --region us-east-1
aws s3api put-object --bucket petclinic-helm-charts-<put-your-name> --key stable/myapp/
```

* Install the helm-s3 plugin for Amazon S3.

```bash
helm plugin install https://github.com/hypnoglow/helm-s3.git
```

* On some systems we need to install ``Helm S3 plugin`` as Jenkins user to be able to use S3 with pipeline script.

``` bash
sudo su -s /bin/bash jenkins
export PATH=$PATH:/usr/local/bin
helm version
helm plugin install https://github.com/hypnoglow/helm-s3.git
exit
``` 

* ``Initialize`` the Amazon S3 Helm repository.

```bash
AWS_REGION=us-east-1 helm s3 init s3://petclinic-helm-charts-<put-your-name>/stable/myapp 
```

* The command creates an ``index.yaml`` file in the target to track all the chart information that is stored at that location.

* Verify that the ``index.yaml`` file was created.

```bash
aws s3 ls s3://petclinic-helm-charts-<put-your-name>/stable/myapp/
```

* Add the Amazon S3 repository to Helm on the client machine. 

```bash
helm repo ls
AWS_REGION=us-east-1 helm repo add stable-petclinicapp s3://petclinic-helm-charts-<put-your-name>/stable/myapp/
```

* Update `version` and `appVersion` field of `k8s/petclinic_chart/Chart.yaml` file as below for testing.

```yaml
version: 0.0.1
appVersion: 0.1.0
```

* ``Package`` the local Helm chart.

```bash
cd k8s
helm package petclinic_chart/ 
```

* Store the local package in the Amazon S3 Helm repository.

```bash
HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./petclinic_chart-0.0.1.tgz stable-petclinicapp
```

* Search for the Helm chart.

```bash
helm search repo stable-petclinicapp
```

* You get an output as below.

```bash
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                
stable-petclinicapp/petclinic_chart     0.0.1           0.1.0           A Helm chart for Kubernetes
```

* In ``Chart.yaml``, ``set`` the `version` value to `0.0.2` in Chart.yaml, and then package the chart, this time changing the version in Chart.yaml to 0.0.2. Version control is ideally achieved through automation by using tools like GitVersion or Jenkins build numbers in a CI/CD pipeline. 

```bash
helm package petclinic_chart/
```

* Push the new version to the Helm repository in Amazon S3.

```bash
HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./petclinic_chart-0.0.2.tgz stable-petclinicapp
```

* Verify the updated Helm chart.

```bash
helm repo update
helm search repo stable-petclinicapp
```

* You get an ``output`` as below.

```bash
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                
stable-petclinicapp/petclinic_chart     0.0.2           0.1.0           A Helm chart for Kubernetes
```

* To view all the available versions of a chart execute following command.

```bash
helm search repo stable-petclinicapp --versions
```

* Output:

```bash
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                
stable-petclinicapp/petclinic_chart     0.0.2           0.1.0           A Helm chart for Kubernetes
stable-petclinicapp/petclinic_chart     0.0.1           0.1.0           A Helm chart for Kubernetes
```

* In ``Chart.yaml``, ``set`` the `version` value(0.1.0) to `HELM_VERSION` in Chart.yaml for automation in jenkins pipeline.

* Commit the change, then push the script to the remote repo.

``` bash
git add .
git commit -m 'added Configuration YAML Files for Kubernetes Deployment'
git push --set-upstream origin feature/STEP-17
git checkout dev
git merge feature/STEP-17
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 18 - Prepare a QA Automation Pipeline for Nightly Builds
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-18` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-18
git checkout feature/STEP-18
```

- Prepare a script to ``package`` the app with maven Docker container and save it as `package-with-maven-container.sh` and save it under `jenkins` folder.

```bash
docker run --rm -v $HOME/.m2:/root/.m2 -v $WORKSPACE:/app -w /app maven:3.8-openjdk-11 mvn clean package
```

- Prepare a script to create ``ECR tags`` for the dev docker images and save it as `prepare-tags-ecr-for-dev-docker-images.sh` and save it under `jenkins` folder.

```bash
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
```

- Prepare a script to build the dev docker images tagged for ECR registry and save it as `build-dev-docker-images-for-ecr.sh` and save it under `jenkins` folder.

```bash
docker build --force-rm -t "${IMAGE_TAG_ADMIN_SERVER}" "${WORKSPACE}/spring-petclinic-admin-server"
docker build --force-rm -t "${IMAGE_TAG_API_GATEWAY}" "${WORKSPACE}/spring-petclinic-api-gateway"
docker build --force-rm -t "${IMAGE_TAG_CONFIG_SERVER}" "${WORKSPACE}/spring-petclinic-config-server"
docker build --force-rm -t "${IMAGE_TAG_CUSTOMERS_SERVICE}" "${WORKSPACE}/spring-petclinic-customers-service"
docker build --force-rm -t "${IMAGE_TAG_DISCOVERY_SERVER}" "${WORKSPACE}/spring-petclinic-discovery-server"
docker build --force-rm -t "${IMAGE_TAG_HYSTRIX_DASHBOARD}" "${WORKSPACE}/spring-petclinic-hystrix-dashboard"
docker build --force-rm -t "${IMAGE_TAG_VETS_SERVICE}" "${WORKSPACE}/spring-petclinic-vets-service"
docker build --force-rm -t "${IMAGE_TAG_VISITS_SERVICE}" "${WORKSPACE}/spring-petclinic-visits-service"
docker build --force-rm -t "${IMAGE_TAG_GRAFANA_SERVICE}" "${WORKSPACE}/docker/grafana"
docker build --force-rm -t "${IMAGE_TAG_PROMETHEUS_SERVICE}" "${WORKSPACE}/docker/prometheus"
```

- Prepare a script to push the dev docker images to the ECR repo and save it as `push-dev-docker-images-to-ecr.sh` and save it under `jenkins` folder.

```bash
# Provide credentials for Docker to login the AWS ECR and push the images
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} 
docker push "${IMAGE_TAG_ADMIN_SERVER}"
docker push "${IMAGE_TAG_API_GATEWAY}"
docker push "${IMAGE_TAG_CONFIG_SERVER}"
docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"
docker push "${IMAGE_TAG_DISCOVERY_SERVER}"
docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
docker push "${IMAGE_TAG_VETS_SERVICE}"
docker push "${IMAGE_TAG_VISITS_SERVICE}"
docker push "${IMAGE_TAG_GRAFANA_SERVICE}"
docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"
```

- Commit the change, then push the scripts to the remote repo.

```bash
git add .
git commit -m 'added scripts for qa automation environment'
git push --set-upstream origin feature/STEP-18
```

  - OPTIONAL: Create a Jenkins job to test the scripts:

```yml
- job name: test-STEP-18-scripts
- job type: Freestyle project
- GitHub project: https://github.com/[your-github-account]/petclinic-microservices
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */feature/STEP-18
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-dev" # Write your own repo name
AWS_REGION="us-east-1" #Update this line if you work on another region
ECR_REGISTRY="046402772087.dkr.ecr.us-east-1.amazonaws.com" # Replace this line with your ECR name
aws ecr create-repository \
    --repository-name ${APP_REPO_NAME} \
    --image-scanning-configuration scanOnPush=false \
    --image-tag-mutability MUTABLE \
    --region ${AWS_REGION}
. ./jenkins/package-with-maven-container.sh
. ./jenkins/prepare-tags-ecr-for-dev-docker-images.sh
. ./jenkins/build-dev-docker-images-for-ecr.sh
. ./jenkins/push-dev-docker-images-to-ecr.sh
```
  * Click `Save`
  * Click `Build now` to manually start the job.

- Create Ansible playbook for deploying application as `dev-petclinic-deploy-template` under `ansible/playbooks` folder.

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
      AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-<put-your-name>/stable/myapp/
      AWS_REGION=$AWS_REGION helm repo update
      AWS_REGION=$AWS_REGION helm upgrade --install \
        petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
        --namespace petclinic-dev
```

- Create Selenium dummy test with name of `dummy_selenium_test_headless.py` with following content to check the setup for the Selenium jobs and save it under `selenium-jobs` folder.

```python
from selenium import webdriver

chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("headless")
chrome_options.add_argument("no-sandbox")
chrome_options.add_argument("disable-dev-shm-usage")
driver = webdriver.Chrome(options=chrome_options)

base_url = "https://www.google.com/"
driver.get(base_url)
source = driver.page_source

if "I'm Feeling Lucky" in source:
  print("Test passed")
else:
  print("Test failed")
driver.close()
```

- Create Ansible playbook for running dummy selenium job and save it as `pb_run_dummy_selenium_job.yaml` under `ansible/playbooks` folder.

```yaml
- hosts: all
  tasks:
  - name: run dummy selenium job
    shell: "docker run --rm -v {{ workspace }}:{{ workspace }} -w {{ workspace }} clarusway/selenium-py-chrome:latest python {{ item }}"
    with_fileglob: "{{ workspace }}/selenium-jobs/dummy*.py"
    register: output
  
  - name: show results
    debug: msg="{{ item.stdout }}"
    with_items: "{{ output.results }}"
```

- Prepare a script to run the playbook for dummy selenium job on Jenkins Server (localhost) and save it as `run_dummy_selenium_job.sh` under `ansible/scripts` folder.

```bash
PATH="$PATH:/usr/local/bin"
ansible-playbook --connection=local --inventory 127.0.0.1, --extra-vars "workspace=${WORKSPACE}" ./ansible/playbooks/pb_run_dummy_selenium_job.yaml
```

- Run the following command to test the `dummy_selenium_test_headless.py` file.

```bash
cd Jenkins/
ansible-playbook --connection=local --inventory 127.0.0.1, --extra-vars "workspace=$(pwd)" ./ansible/playbooks/pb_run_dummy_selenium_job.yaml
```

- Next, you can change something in the `dummy_selenium_test_headless.py` (I'm Feeling Lucks) and run the command again. And check the test ``passed`` or ``failed``. 

- Commit the change, then push the scripts for dummy selenium job to the remote repo.

```bash
git add .
git commit -m 'added scripts for running dummy selenium job'
git push --set-upstream origin feature/STEP-18
```

- Create a Jenkins job with name of `test-running-dummy-selenium-job` to check the setup for selenium tests by running dummy selenium job on `feature/STEP-18` branch.

```yml
- job name: test-running-dummy-selenium-job
- job type: Freestyle project
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */feature/STEP-18
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
ansible-playbook --connection=local --inventory 127.0.0.1, --extra-vars "workspace=$(pwd)" ./ansible/playbooks/pb_run_dummy_selenium_job.yaml
```

- Create Ansible playbook for running all selenium jobs under `selenium-jobs` folder and save it as `pb_run_selenium_jobs.yaml` under `ansible/playbooks` folder.

```yaml
- hosts: all
  tasks:
  - name: run all selenium jobs
    shell: "docker run --rm --env MASTER_PUBLIC_IP={{ master_public_ip }} -v {{ workspace }}:{{ workspace }} -w {{ workspace }} clarusway/selenium-py-chrome:latest python {{ item }}"
    register: output
    with_fileglob: "{{ workspace }}/selenium-jobs/test*.py"
  
  - name: show results
    debug: msg="{{ item.stdout }}"
    with_items: "{{ output.results }}"
```

- Change the `port of url field` in the `test_owners_all_headless.py, test_owners_register_headless.py and test_veterinarians_headless.py` as `30001` as below.

```py
APP_IP = os.environ['MASTER_PUBLIC_IP']
url = "http://"+APP_IP.strip()+":30001/"
```
 
- Prepare a script to run the playbook for all selenium jobs on Jenkins Server (localhost) and save it as `run_selenium_jobs.sh` under `ansible/scripts` folder.

```bash
PATH="$PATH:/usr/local/bin"
ansible-playbook -vvv --connection=local --inventory 127.0.0.1, --extra-vars "workspace=${WORKSPACE} master_public_ip=${MASTER_PUBLIC_IP}" ./ansible/playbooks/pb_run_selenium_jobs.yaml
```

- Prepare a Jenkinsfile for `petclinic-nightly` builds and save it as `jenkinsfile-petclinic-nightly` under `jenkins` folder.

```groovy
pipeline {
    agent any
    environment {
        APP_NAME="petclinic"
        APP_REPO_NAME="clarusway-repo/${APP_NAME}-app-dev"
        AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR="petclinic-${APP_NAME}-dev-${BUILD_NUMBER}.key"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
        ANSIBLE_HOST_KEY_CHECKING="False"
    }
    stages {
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
        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
                }
            }
        }
        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh ". ./jenkins/build-dev-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-dev-docker-images-to-ecr.sh"
            }
        }
        stage('Create Key Pair for Ansible') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                sh "aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${ANS_KEYPAIR}"
                sh "chmod 400 ${ANS_KEYPAIR}"
            }
        }

        stage('Create QA Automation Infrastructure') {
            steps {
                echo 'Creating QA Automation Infrastructure for Dev Environment'
                sh """
                    cd infrastructure/dev-k8s-terraform
                    sed -i "s/clarus/$ANS_KEYPAIR/g" main.tf
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


        stage('Create Kubernetes Cluster for QA Automation Build') {
            steps {
                echo "Setup Kubernetes cluster for ${APP_NAME} App"
                sh "ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml"
            }
        }

        stage('Deploy App on Kubernetes cluster'){
            steps {
                echo 'Deploying App on Kubernetes'
                sh "envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml"
                sh "sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml"
                sh "helm repo add stable-petclinic s3://petclinic-helm-charts-<put-your-name>/stable/myapp/"
                sh "helm package k8s/petclinic_chart"
                sh "helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic"
                sh "envsubst < ansible/playbooks/dev-petclinic-deploy-template > ansible/playbooks/dev-petclinic-deploy.yaml"
                sh "sleep 60"    
                sh "ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/dev-petclinic-deploy.yaml"
            }
        }     

        stage('Test the Application Deployment'){
            steps {
                echo "Check if the ${APP_NAME} app is ready or not"
                script {
                    env.MASTER_PUBLIC_IP = sh(script:"aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=master Name=tag-value,Values=tera-kube-ans Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[PublicIpAddress] --output text", returnStdout:true).trim()
                    while(true) {
                        try{
                            sh "curl -s ${MASTER_PUBLIC_IP}:30001"
                            echo "${APP_NAME} app is successfully deployed."
                            break
                        }
                        catch(Exception){
                            echo "Could not connect to ${APP_NAME} app"
                            sleep(5)
                        }
                    }
                }
            }
        }

        stage('Run QA Automation Tests'){
            steps {
                echo "Run the Selenium Functional Test on QA Environment"
                sh 'ansible-playbook -vvv --connection=local --inventory 127.0.0.1, --extra-vars "workspace=${WORKSPACE} master_public_ip=${MASTER_PUBLIC_IP}" ./ansible/playbooks/pb_run_selenium_jobs.yaml'
            }
        }
 }

    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
            echo 'Delete the Image Repository on ECR'
            sh """
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION}\
                  --force
                """
            echo 'Tear down the Kubernetes Cluster'
            sh """
            cd infrastructure/dev-k8s-terraform
            terraform destroy -auto-approve -no-color
            """
            echo "Delete existing key pair using AWS CLI"
            sh "aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}"
            sh "rm -rf ${ANS_KEYPAIR}"
        }
    }
}
```

- Create a Jenkins pipeline with the name of `petclinic-nightly` with the following script to run QA automation tests and configure a `cron job` to trigger the pipeline every night at midnight (`0 0 * * *`) on the `dev` branch. Input `jenkins/jenkinsfile-petclinic-nightly` to the `Script Path` field. Petclinic nightly build pipeline should be built on a temporary QA automation environment.

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added qa automation pipeline for dev'
git push
git checkout dev
git merge feature/STEP-18
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 19 - Create a QA Environment on EKS Cluster
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-19` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-19
git checkout feature/STEP-19
```

- Create a folder for QA environment on EKS cluster setup with the name of `qa-eks-cluster` under `infrastructure` folder.

- Create a `cluster.yaml` file under `infrastructure/qa-eks-cluster` folder.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: petclinic-cluster
  region: us-east-1
availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]
managedNodeGroups:
  - name: ng-1
    instanceType: t3a.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    volumeSize: 8
```

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added cluster.yaml file'
git push --set-upstream origin feature/STEP-19
git checkout dev
git merge feature/STEP-19
git push origin dev
```
- ### Install eksctl

- Download and extract the latest release of eksctl with the following command.

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
```

- Move the extracted binary to /usr/local/bin.

```bash
sudo mv /tmp/eksctl /usr/local/bin
```

- Test that your installation was successful with the following command.

```bash
eksctl version
```

### Install kubectl

- Download the Amazon EKS vended kubectl binary.

```bash
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.7/2023-11-14/bin/linux/amd64/kubectl
```

- Apply execute permissions to the binary.

```bash
chmod +x ./kubectl
```

- Move the kubectl binary to /usr/local/bin.

```bash
sudo mv kubectl /usr/local/bin
```

- After you install kubectl , you can verify its version with the following command:

```bash
kubectl version --short --client
```

- Switch user to jenkins for creating eks cluster. Execute following commands as `jenkins` user.

```bash
sudo su - jenkins
```

- Create a `cluster.yaml` file under `/var/lib/jenkins` folder.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: petclinic-cluster
  region: us-east-1
availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]
managedNodeGroups:
  - name: ng-1
    instanceType: t3a.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    volumeSize: 8
```

- Create an EKS cluster via `eksctl`. It will take a while.

```bash
eksctl create cluster -f cluster.yaml
```

- After the cluster is up, run the following command to install `ingress controller`.

```bash
export PATH=$PATH:$HOME/bin
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 20 - Prepare Build Scripts for QA Environment
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-20` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-20
git checkout feature/STEP-20
```

- Create a ``Jenkins Job`` to create Docker Registry for `QA` manually on AWS ECR.

```yml
- job name: create-ecr-docker-registry-for-petclinic-qa
- job type: Freestyle project
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-qa"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
 --repository-name ${APP_REPO_NAME} \
 --image-scanning-configuration scanOnPush=false \
 --image-tag-mutability MUTABLE \
 --region ${AWS_REGION}
```
* Click `save`.
* Click `Build Now`

- Prepare a script to create ECR tags for the docker images and save it as `prepare-tags-ecr-for-qa-docker-images.sh` and save it under `jenkins` folder.

```bash
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
```

- Prepare a script to build the dev docker images tagged for ECR registry and save it as `build-qa-docker-images-for-ecr.sh` and save it under `jenkins` folder.

```bash
docker build --force-rm -t "${IMAGE_TAG_ADMIN_SERVER}" "${WORKSPACE}/spring-petclinic-admin-server"
docker build --force-rm -t "${IMAGE_TAG_API_GATEWAY}" "${WORKSPACE}/spring-petclinic-api-gateway"
docker build --force-rm -t "${IMAGE_TAG_CONFIG_SERVER}" "${WORKSPACE}/spring-petclinic-config-server"
docker build --force-rm -t "${IMAGE_TAG_CUSTOMERS_SERVICE}" "${WORKSPACE}/spring-petclinic-customers-service"
docker build --force-rm -t "${IMAGE_TAG_DISCOVERY_SERVER}" "${WORKSPACE}/spring-petclinic-discovery-server"
docker build --force-rm -t "${IMAGE_TAG_HYSTRIX_DASHBOARD}" "${WORKSPACE}/spring-petclinic-hystrix-dashboard"
docker build --force-rm -t "${IMAGE_TAG_VETS_SERVICE}" "${WORKSPACE}/spring-petclinic-vets-service"
docker build --force-rm -t "${IMAGE_TAG_VISITS_SERVICE}" "${WORKSPACE}/spring-petclinic-visits-service"
docker build --force-rm -t "${IMAGE_TAG_GRAFANA_SERVICE}" "${WORKSPACE}/docker/grafana"
docker build --force-rm -t "${IMAGE_TAG_PROMETHEUS_SERVICE}" "${WORKSPACE}/docker/prometheus"
```

- Prepare a script to push the dev docker images to the ECR repo and save it as `push-qa-docker-images-to-ecr.sh` and save it under `jenkins` folder.

```bash
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker push "${IMAGE_TAG_ADMIN_SERVER}"
docker push "${IMAGE_TAG_API_GATEWAY}"
docker push "${IMAGE_TAG_CONFIG_SERVER}"
docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"
docker push "${IMAGE_TAG_DISCOVERY_SERVER}"
docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
docker push "${IMAGE_TAG_VETS_SERVICE}"
docker push "${IMAGE_TAG_VISITS_SERVICE}"
docker push "${IMAGE_TAG_GRAFANA_SERVICE}"
docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"
```

- Prepare a script to deploy the application on QA environment and save it as `deploy_app_on_qa_environment.sh` under `jenkins` folder.

```bash
echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml
AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-<put-your-name>/stable/myapp/ || echo "repository name already exists"
AWS_REGION=$AWS_REGION helm repo update
helm package k8s/petclinic_chart
AWS_REGION=$AWS_REGION helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic
kubectl create ns petclinic-qa || echo "namespace petclinic-qa already exists"
kubectl delete secret regcred -n petclinic-qa || echo "there is no regcred secret in petclinic-qa namespace"
kubectl create secret generic regcred -n petclinic-qa \
    --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
AWS_REGION=$AWS_REGION helm repo update
AWS_REGION=$AWS_REGION helm upgrade --install \
    petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
    --namespace petclinic-qa
```

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added build scripts for QA Environment'
git push --set-upstream origin feature/STEP-20
git checkout dev
git merge feature/STEP-20
git push origin dev
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 21 - Build and Deploy App on QA Environment Manually
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-21` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-21
git checkout feature/STEP-21
```

- Create a ``Jenkins Job`` with name of `build-and-deploy-petclinic-on-qa-env` to build and deploy the app on `QA environment` manually on `release` branch using following script, and save the script as `build-and-deploy-petclinic-on-qa-env-manually.sh` under `jenkins` folder.

```yml
- job name: build-and-deploy-petclinic-on-qa-env  
- job type: Freestyle project
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */release
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
PATH="$PATH:/usr/local/bin:$HOME/bin"
APP_NAME="petclinic"
APP_REPO_NAME="clarusway-repo/petclinic-app-qa"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo 'Packaging the App into Jars with Maven'
. ./jenkins/package-with-maven-container.sh
echo 'Preparing QA Tags for Docker Images'
. ./jenkins/prepare-tags-ecr-for-qa-docker-images.sh
echo 'Building App QA Images'
. ./jenkins/build-qa-docker-images-for-ecr.sh
echo "Pushing App QA Images to ECR Repo"
. ./jenkins/push-qa-docker-images-to-ecr.sh
echo 'Deploying App on Kubernetes Cluster'
. ./jenkins/deploy_app_on_qa_environment.sh
echo 'Deleting all local images'
docker image prune -af
```
* Click `save`.

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added script for jenkins job to build and deploy app on QA environment'
git push --set-upstream origin feature/STEP-21
git checkout dev
git merge feature/STEP-21
git push origin dev
```

- Merge `dev` into `release` branch, then run `build-and-deploy-petclinic-on-qa-env` job to build and deploy the app on `QA environment` manually.

```bash
git checkout release
git merge dev
git push origin release
```
* Click `Build Now`

- bind ingress address to your host name that defines in api-gateway-ingress.yaml on the route53 service.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 22 - Prepare a QA Pipeline
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

- Create `feature/STEP-22` branch from `dev`.

```bash
git checkout dev
git branch feature/STEP-22
git checkout feature/STEP-22
```

- Prepare a Jenkinsfile for `petclinic-weekly-qa` builds and save it as `jenkinsfile-petclinic-weekly-qa` under `jenkins` folder.

```groovy
pipeline {
    agent any
    environment {
        PATH=sh(script:"echo $PATH:/usr/local/bin:$HOME/bin", returnStdout:true).trim()
        APP_NAME="petclinic"
        APP_REPO_NAME="clarusway-repo/petclinic-app-qa"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }
    stages {
        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-qa-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
                }
            }
        }
        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh ". ./jenkins/build-qa-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-qa-docker-images-to-ecr.sh"
            }
        }
        stage('Deploy App on Kubernetes Cluster'){
            steps {
                echo 'Deploying App on Kubernetes Cluster'
                sh '. ./jenkins/deploy_app_on_qa_environment.sh'
            }
        }
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }
    }
}
```

- Commit the change, then push the script to the remote repo.

```bash
git add .
git commit -m 'added jenkinsfile petclinic-weekly-qa for release branch'
git push --set-upstream origin feature/STEP-22
git checkout dev
git merge feature/STEP-22
git push origin dev
```

- Merge `dev` into `release` branch to build and deploy the app on `QA environment` with pipeline.

```bash
git checkout release
git merge dev
git push origin release
```

- Create a QA ``Pipeline`` on Jenkins with name of `petclinic-weekly-qa` with following script and configure a `cron job` to trigger the pipeline every Sundays at midnight (`59 23 * * 0`) on `release` branch. Petclinic weekly build pipeline should be built on permanent QA environment.

```yml
- job name: petclinic-weekly-qa
- job type: pipeline
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */release
- Pipeline:
      Script Path: jenkins/jenkinsfile-petclinic-weekly-qa
```
* Click `save`.
* Click `Build Now`

- Delete  EKS cluster via `eksctl`. It will take a while.

```bash
sudo su - jenkins
eksctl delete cluster -f cluster.yaml
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 23 - Prepare High-availability RKE Kubernetes Cluster on AWS EC2
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-23` branch from `release`.

``` bash
git checkout release
git branch feature/STEP-23
git checkout feature/STEP-23
```

* Explain [Rancher Container Management Tool](https://rancher.com/docs/rancher/v2.x/en/overview/architecture/).

* Create an IAM Policy with name of `petclinic-rke-controlplane-policy.json` and also save it under `infrastructure` for `Control Plane` node to enable Rancher to create or remove EC2 resources.

``` json
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Action": [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey"
    ],
    "Resource": [
      "*"
    ]
  }
]
}
```

* Create an IAM Policy with name of `petclinic-rke-etcd-worker-policy.json` and also save it under `infrastructure` for `etcd` or `worker` nodes to enable Rancher to get information from EC2 resources.

```json
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage"
        ],
        "Resource": "*"
    }
]
}
```

* Create an IAM Role with name of `petclinic-rke-role` to attach RKE nodes (instances) using `petclinic-rke-controlplane-policy` and `petclinic-rke-etcd-worker-policy`.

* Create a security group for External Application Load Balancer of Rancher with name of `petclinic-rke-alb-sg` and allow HTTP (Port 80) and HTTPS (Port 443) connections from anywhere.
  
* Create a security group for RKE Kubernetes Cluster with name of `petclinic-rke-cluster-sg` and define following inbound and outbound rules.

  * ``Inbound`` rules;

    * Allow HTTP protocol (TCP on port 80) from Application Load Balancer.

    * Allow HTTPS protocol (TCP on port 443) from any source that needs to use Rancher UI or API.

    * Allow TCP on port 6443 from any source that needs to use Kubernetes API server(ex. Jenkins Server).
  
    * Allow SSH on port 22 to any node IP that installs Docker (ex. Jenkins Server).

  * ``Outbound`` rules;

    * Allow SSH protocol (TCP on port 22) to any node IP from a node created using Node Driver.

    * Allow HTTP protocol (TCP on port 80) to all IP for getting updates.
    
    * Allow HTTPS protocol (TCP on port 443) to `35.160.43.145/32`, `35.167.242.46/32`, `52.33.59.17/32` for catalogs of `git.rancher.io`.

    * Allow TCP on port 2376 to any node IP from a node created using Node Driver for Docker machine TLS port.

  * Allow all protocol on all port from `petclinic-rke-cluster-sg` for self communication between Rancher `controlplane`, `etcd`, `worker` nodes.

* Log into Jenkins Server and create `petclinic-rancher.pem` key-pair for Rancher Server using AWS CLI
  
```bash
aws ec2 create-key-pair --region us-east-1 --key-name petclinic-rancher --query KeyMaterial --output text > ~/.ssh/petclinic-rancher.pem
chmod 400 ~/.ssh/petclinic-rancher.pem
```

* Launch an EC2 instance using `Ubuntu Server 20.04 LTS (HVM) (64-bit x86)` with `t3a.medium` type, 16 GB root volume,  `petclinic-rke-cluster-sg` security group, `petclinic-rke-role` IAM Role, `Name:Petclinic-Rancher-Cluster-Instance` tag and `petclinic-rancher.pem` key-pair. Take note of `subnet id` of EC2. 

* Attach a tag to the `nodes (intances)`, `subnets` and `security group` for Rancher with `Key = kubernetes.io/cluster/Petclinic-Rancher` and `Value = owned`.
  
* Log into `Petclinic-Rancher-Cluster-Instance` from Jenkins Server (Bastion host) and install Docker using the following script.

```bash
# Set hostname of instance
sudo hostnamectl set-hostname rancher-instance-1
# Update OS 
sudo apt-get update -y
sudo apt-get upgrade -y
# Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install and start Docker
# RKE is not compatible with the current Docker version (v23 hence we need to install an earlier version of Docker
sudo apt-get install docker-ce=5:20.10.24~3-0~ubuntu-jammy  docker-ce-cli=5:20.10.24~3-0~ubuntu-jammy containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu
newgrp docker
```

* Create a target groups with name of `petclinic-rancher-http-80-tg` with following setup and add the `rancher instances` to it.

```yml
Target type         : instance
Protocol            : HTTP
Port                : 80

<!-- Health Checks Settings -->
Protocol            : HTTP
Path                : /healthz
Port                : traffic port
Healthy threshold   : 3
Unhealthy threshold : 3
Timeout             : 5 seconds
Interval            : 10 seoconds
Success             : 200
```

* Create Application Load Balancer with name of `petclinic-rancher-alb` using `petclinic-rke-alb-sg` security group with following settings and add `petclinic-rancher-http-80-tg` target group to it.

```yml
Scheme              : internet-facing
IP address type     : ipv4

<!-- Listeners-->
Protocol            : HTTP
Port                : 80
Availability Zones  : Select AZs of RKE instances
Target group        : `petclinic-rancher-http-80-tg` target group

<!-- Add Listener-->
Protocol            : HTTPS
Port                : 443
Availability Zones  : Select AZs of RKE instances
Target group        : `petclinic-rancher-http-80-tg` target group

<!-- Secure listener settings -->
From ACM            : *.clarusway.us   # change with your dns name
```

* Configure ALB Listener of HTTP on `Port 80` to redirect traffic to HTTPS on `Port 443`.

* Create DNS A record for `rancher.clarusway.us` and attach the `petclinic-rancher-alb` application load balancer to it.

* Install RKE, the Rancher Kubernetes Engine, [Kubernetes distribution and command-line tool](https://rancher.com/docs/rke/latest/en/installation/)) on Jenkins Server.

```bash
curl -SsL "https://github.com/rancher/rke/releases/download/v1.4.11/rke_linux-amd64" -o "rke_linux-amd64"
sudo mv rke_linux-amd64 /usr/local/bin/rke
chmod +x /usr/local/bin/rke
rke --version
```

* Create `rancher-cluster.yml` with following content to configure RKE Kubernetes Cluster and save it under `infrastructure` folder.

```yml
nodes:
  - address: 172.31.82.64                # Change with the Private Ip of rancher server
    internal_address: 172.31.82.64       # Change with the Private Ip of rancher server
    user: ubuntu
    role:
      - controlplane
      - etcd
      - worker

# ignore_docker_version: true

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

ssh_key_path: ~/.ssh/petclinic-rancher.pem

# Required for external TLS termination with
# ingress-nginx v0.22+
ingress:
  provider: nginx
  options:
    use-forwarded-headers: "true"
```

* Run `rke` command to setup RKE Kubernetes cluster on EC2 Rancher instance *`Warning:` You should add rule to cluster sec group for Jenkins Server using its `IP/32` from SSH (22) and TCP(6443) before running `rke` command, because it is giving connection error.*

```bash
rke up --config ./rancher-cluster.yml
```

* Check if the RKE Kubernetes Cluster created successfully.

```bash
mkdir -p ~/.kube
mv ./kube_config_rancher-cluster.yml $HOME/.kube/config
mv ./rancher-cluster.rkestate $HOME/.kube/rancher-cluster.rkestate
chmod 400 ~/.kube/config
kubectl get nodes
kubectl get pods --all-namespaces
```

* Commit the change, then push the script to the remote repo.

``` bash
git add .
git commit -m 'added rancher setup files'
git push --set-upstream origin feature/STEP-23
git checkout release
git merge feature/STEP-23
git push origin release
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 24 - Install Rancher App on RKE Kubernetes Cluster
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Add ``helm chart repositories`` of Rancher.

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo list
```

* Create a ``namespace`` for Rancher.

```bash
kubectl create namespace cattle-system
```

* Install Rancher on RKE Kubernetes Cluster using Helm.

```bash
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.clarusway.us \
  --set tls=external \
  --set replicas=1 \
  --set global.cattle.psp.enabled=false
  
# Change DNS name
```

* Check if the Rancher Server is deployed successfully.
  
```bash
kubectl -n cattle-system get deploy rancher
kubectl -n cattle-system get pods
```

* If bootstrap pod is not initialized or you forget your admin password you can use the below command to reset your password.

```bash
export KUBECONFIG=~/.kube/config
kubectl --kubeconfig $KUBECONFIG -n cattle-system exec $(kubectl --kubeconfig $KUBECONFIG -n cattle-system get pods -l app=rancher | grep '1/1' | head -1 | awk '{ print $1 }') -- reset-password
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 25 - Prepare Nexus Server
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-25` branch from `release`.

``` bash
git checkout release
git branch feature/STEP-25
git checkout feature/STEP-25
```

* Set up a Nexus Server by using docker image.  To do so, prepare a [Terraform File for Nexus Server](./STEP-25-nexus-server-terraform-template) with following script and save it as `nexus-server.tf` under `infrastructure` folder. 

* Note: Terraform will will launch an t3a.medium (Nexus needs 8 GB of RAM) EC2 instance using the Amazon Linux 2023 AMI with security group allowing `SSH (22)` and `Nexus Port (8081)` connections.

``` bash
#! /bin/bash
# update os
yum update -y
# set server hostname as jenkins-server
hostnamectl set-hostname nexus-server
# install docker
yum install docker -y
# start docker
systemctl start docker
# enable docker service
systemctl enable docker
# add ec2-user to docker group
sudo usermod -aG docker ec2-user
newgrp docker
# create a docker volume for nexus persistent data
docker volume create --name nexus-data
# run the nexus container
docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
```

- Open your browser to load the repository manager: `http://<AWS public dns>:8081` and click `Sign in` upper right of the page. A box will pop up.

- Write `admin` for Username and paste the string which you copied from admin.password file for the password.

```bash
docker exec -it nexus cat /nexus-data/admin.password
```

- Use the content of the `initialpasswd.txt` file that is under the same directory of terrafom file. ("provisioner" block of the tf file copies the content of the  `admin.password` file in the container to the `initialpasswd.txt` in the local host.)

- Click the ``Sign in`` button to start the Setup wizard. Click Next through the steps to update your password.

- Click the ``Disable Anonymous Access box``.

- Click Finish to complete the wizard.

### Configure the app for Nexus Operation

- Nexus searchs for ``settings.xml`` in the `/home/ec2-user/.m2` directory. .m2 directory is created after running the first mvn command.
- Create the ``settings.xml`` file.

```bash
nano /home/ec2-user/.m2/settings.xml
```

- Your settings.xml file should look like this (Don't forget to change the URL of your repository and the password): 

```xml
<settings>
  <mirrors>
    <mirror>
      <!--This sends everything else to /public -->
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>http://<AWS private IP>:8081/repository/maven-public/</url>
    </mirror>
  </mirrors>
  <profiles>
    <profile>
      <id>nexus</id>
      <!--Enable snapshots for the built in central repo to direct -->
      <!--all requests to nexus via the mirror -->
      <repositories>
        <repository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
     <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
<activeProfiles>
    <!--make the profile active all the time -->
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>your-password</password> 
    </server>
  </servers>
</settings>
```

- Delete `repository` folder under `/home/ec2-user/.m2` to see if dependies download from the Nexus server.

- run the mvn command to see if it is worked.

``` bash
./mvnw clean
```

- Add distributionManagement element given below to your ``pom.xml`` file after `</dependencyManagement>` line. Include the endpoints to your maven-releases and maven-snapshots repos. Change localhost >>>> Private ip of your server.

```xml
<distributionManagement>
  <repository>
    <id>nexus</id>
    <name>maven-releases</name>
    <url>http://<AWS private IP>:8081/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>nexus</id>
    <name>maven-snapshots</name>
    <url>http://<AWS private IP>:8081/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>
```

- Run following command; Created artifact will be stored in the nexus-releases repository.

```bash
./mvnw clean deploy
```

- Note: if you want to redeploy the same artifact to release repository, you need to set Deployment policy : "Allow redeploy".
(nexus server --> server configuration --> repositories --> maven releases --> Deployment policy : ``Allow redeploy``)

``` bash
git add .
git commit -m 'added Nexus server terraform files'
git push --set-upstream origin feature/STEP-25
git checkout release
git merge feature/STEP-25
git push origin release
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 26 - Prepare a Staging Pipeline
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-26` branch from `release`.

``` bash
git checkout release
git branch feature/STEP-26
git checkout feature/STEP-26
```

* To provide access of Rancher to the cloud resources, create a `Cloud Credentials` on `Cluster Management` segment for AWS on Rancher and name it as `Petclinic-AWS-Training-Account`. As region select `us-east-1`.

* Create a Kubernetes cluster using Rancher (Cluster Management --> Clusters) with RKE and new nodes in AWS  and name it as `petclinic-cluster-staging`.

```yml
Cluster Type      : Amazon EC2
Name Prefix       : petclinic-k8s-instance
Count             : 3
etcd              : checked
Control Plane     : checked
Worker            : checked
```

* Create `petclinic-staging-ns` namespace on `petclinic-cluster-staging` with Rancher.

* Create a ``Jenkins Job`` and name it as `create-ecr-docker-registry-for-petclinic-staging` to create Docker Registry for `Staging` manually on AWS ECR.

```yml
- job name: create-ecr-docker-registry-for-petclinic-staging
- job type: Freestyle project
- Build:
      Add build step: Execute Shell
      Command:
```
``` bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-staging"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
  --repository-name ${APP_REPO_NAME} \
  --image-scanning-configuration scanOnPush=false \
  --image-tag-mutability MUTABLE \
  --region ${AWS_REGION}
```
* Click `save`.
* Click `Build Now`

* Prepare a script to create ECR tags for the staging docker images and name it as `prepare-tags-ecr-for-staging-docker-images.sh` and save it under `jenkins` folder.

``` bash
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
```

* Prepare a script to build the staging docker images tagged for ECR registry and name it as `build-staging-docker-images-for-ecr.sh` and save it under `jenkins` folder.

``` bash
docker build --force-rm -t "${IMAGE_TAG_ADMIN_SERVER}" "${WORKSPACE}/spring-petclinic-admin-server"
docker build --force-rm -t "${IMAGE_TAG_API_GATEWAY}" "${WORKSPACE}/spring-petclinic-api-gateway"
docker build --force-rm -t "${IMAGE_TAG_CONFIG_SERVER}" "${WORKSPACE}/spring-petclinic-config-server"
docker build --force-rm -t "${IMAGE_TAG_CUSTOMERS_SERVICE}" "${WORKSPACE}/spring-petclinic-customers-service"
docker build --force-rm -t "${IMAGE_TAG_DISCOVERY_SERVER}" "${WORKSPACE}/spring-petclinic-discovery-server"
docker build --force-rm -t "${IMAGE_TAG_HYSTRIX_DASHBOARD}" "${WORKSPACE}/spring-petclinic-hystrix-dashboard"
docker build --force-rm -t "${IMAGE_TAG_VETS_SERVICE}" "${WORKSPACE}/spring-petclinic-vets-service"
docker build --force-rm -t "${IMAGE_TAG_VISITS_SERVICE}" "${WORKSPACE}/spring-petclinic-visits-service"
docker build --force-rm -t "${IMAGE_TAG_GRAFANA_SERVICE}" "${WORKSPACE}/docker/grafana"
docker build --force-rm -t "${IMAGE_TAG_PROMETHEUS_SERVICE}" "${WORKSPACE}/docker/prometheus"
```

* Prepare a script to push the staging docker images to the ECR repo and name it as `push-staging-docker-images-to-ecr.sh` and save it under `jenkins` folder.

``` bash
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker push "${IMAGE_TAG_ADMIN_SERVER}"
docker push "${IMAGE_TAG_API_GATEWAY}"
docker push "${IMAGE_TAG_CONFIG_SERVER}"
docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"
docker push "${IMAGE_TAG_DISCOVERY_SERVER}"
docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
docker push "${IMAGE_TAG_VETS_SERVICE}"
docker push "${IMAGE_TAG_VISITS_SERVICE}"
docker push "${IMAGE_TAG_GRAFANA_SERVICE}"
docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"
```

* Install `Rancher CLI` on Jenkins Server.

```bash
curl -SsL "https://github.com/rancher/cli/releases/download/v2.8.0/rancher-linux-amd64-v2.8.0.tar.gz" -o "rancher-cli.tar.gz"
tar -zxvf rancher-cli.tar.gz
sudo mv ./rancher*/rancher /usr/local/bin/rancher
chmod +x /usr/local/bin/rancher
rancher --version
```
  
* Create Rancher API Key [Rancher API Key](https://rancher.com/docs/rancher/v2.x/en/user-settings/api-keys/#creating-an-api-key) to enable access to the `Rancher` server. Take note, `Access Key (username)` and `Secret Key (password)`.

- On jenkins server, select ***Manage Jenkins --> Manage Credentials --> Jenkins -->   Global credentials (unrestricted) --> Add Credentials***.

```yml
- credentials kind : Username with password
- username: Access Key
- password: Secret Key
- id: rancher-petclinic-credentials
```

* Prepare a Jenkinsfile for `petclinic-staging` pipeline and save it as `jenkinsfile-petclinic-staging` under `jenkins` folder.

``` groovy
pipeline {
    agent any
    environment {
        PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        APP_NAME="petclinic"
        APP_REPO_NAME="clarusway-repo/petclinic-app-staging"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        RANCHER_URL="https://rancher.clarusway.us"
        // Get the project-id from Rancher UI (projects/namespaces --> petclinic-cluster-staging namespace --> Edit yaml --> copy projectId )
        RANCHER_CONTEXT="petclinic-cluster:project-id" 
       //First part of projectID
        CLUSTERID="petclinic-cluster"
        RANCHER_CREDS=credentials('rancher-petclinic-credentials')
    }
    stages {
        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Staging Docker Images') {
            steps {
                echo 'Preparing Tags for Staging Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-staging-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
                }
            }
        }
        stage('Build App Staging Docker Images') {
            steps {
                echo 'Building App Staging Images'
                sh ". ./jenkins/build-staging-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-staging-docker-images-to-ecr.sh"
            }
        }
        stage('Deploy App on Petclinic Kubernetes Cluster'){
            steps {
                echo 'Deploying App on K8s Cluster'
                sh "rancher login $RANCHER_URL --context $RANCHER_CONTEXT --token $RANCHER_CREDS_USR:$RANCHER_CREDS_PSW"
                sh "envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml"
                sh "sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml"
                sh "rancher kubectl delete secret regcred -n petclinic-staging-ns || true"
                sh """
                rancher kubectl create secret generic regcred -n petclinic-staging-ns \
                --from-file=.dockerconfigjson=$JENKINS_HOME/.docker/config.json \
                --type=kubernetes.io/dockerconfigjson
                """
                sh "rm -f k8s/config"
                sh "rancher cluster kf $CLUSTERID > k8s/config"
                sh "chmod 400 k8s/config"
                sh "helm repo add stable-petclinic s3://petclinic-helm-charts-<put-your-name>/stable/myapp/"
                sh "helm package k8s/petclinic_chart"
                sh "helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic"
                sh "helm repo update"
                sh "AWS_REGION=$AWS_REGION helm upgrade --install petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} --namespace petclinic-staging-ns --kubeconfig k8s/config"
            }
        }
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }
    }
}
```

* Create an `A` record of `staging-petclinic.clarusway.us` in your hosted zone (in our case `clarusway.us`) using AWS Route 53 domain registrar and bind it to your `petclinic cluster`.

* Create a Staging ``Pipeline`` on Jenkins with name of `petclinic-staging` with following script and configure a `cron job` to trigger the pipeline every Sundays at midnight (`59 23 * * 0`) on `release` branch. `Petclinic staging pipeline` should be deployed on permanent staging-environment on `petclinic-cluster` Kubernetes cluster under `petclinic-staging-ns` namespace.

```yml
- job name: petclinic-staging
- job type: pipeline
- Build Triggers:
      Build periodically: 59 23 * * 0
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */release
- Pipeline:
      Script Path: jenkins/jenkinsfile-petclinic-staging
```
* Click `save`.
* Click `Build Now`

* Commit the change, then push the script to the remote repo.

``` bash
git add .
git commit -m 'added jenkinsfile petclinic-staging for release branch'
git push --set-upstream origin feature/STEP-26
git checkout release
git merge feature/STEP-26
git push origin release
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
## STEP 27 - Prepare a Production Pipeline
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-27` branch from `release`.

``` bash
git checkout release
git branch feature/STEP-27
git checkout feature/STEP-27
```

- Switch user to jenkins for creating eks cluster. Execute following commands as `jenkins` user.

```bash
sudo su - jenkins
```

- Create a `cluster.yaml` file under `/var/lib/jenkins` folder.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: petclinic-cluster
  region: us-east-1
availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]
managedNodeGroups:
  - name: ng-1
    instanceType: t3a.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 3
    volumeSize: 8
```

- Create an EKS cluster via `eksctl`. It will take a while.

```bash
eksctl create cluster -f cluster.yaml
```

- After the cluster is up, run the following command to install `ingress controller`.

```bash
export PATH=$PATH:$HOME/bin
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```


* Create a ``Jenkins Job`` and name it as `create-ecr-docker-registry-for-petclinic-prod` to create Docker Registry for `Production` manually on AWS ECR.

```yml
- job name: create-ecr-docker-registry-for-petclinic-prod
- job type: Freestyle project
- Build:
      Add build step: Execute Shell
      Command:
```
``` bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="clarusway-repo/petclinic-app-prod"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
  --repository-name ${APP_REPO_NAME} \
  --image-scanning-configuration scanOnPush=false \
  --image-tag-mutability MUTABLE \
  --region ${AWS_REGION}
```
* Click `save`.
* Click `Build Now`

* Prepare a script to create ECR tags for the production docker images and name it as `prepare-tags-ecr-for-prod-docker-images.sh` and save it under `jenkins` folder.

``` bash
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
MVN_VERSION=$(. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version)
export IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
export IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
export IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
```

* Prepare a script to build the production docker images tagged for ECR registry and name it as `build-prod-docker-images-for-ecr.sh` and save it under `jenkins` folder.

``` bash
docker build --force-rm -t "${IMAGE_TAG_ADMIN_SERVER}" "${WORKSPACE}/spring-petclinic-admin-server"
docker build --force-rm -t "${IMAGE_TAG_API_GATEWAY}" "${WORKSPACE}/spring-petclinic-api-gateway"
docker build --force-rm -t "${IMAGE_TAG_CONFIG_SERVER}" "${WORKSPACE}/spring-petclinic-config-server"
docker build --force-rm -t "${IMAGE_TAG_CUSTOMERS_SERVICE}" "${WORKSPACE}/spring-petclinic-customers-service"
docker build --force-rm -t "${IMAGE_TAG_DISCOVERY_SERVER}" "${WORKSPACE}/spring-petclinic-discovery-server"
docker build --force-rm -t "${IMAGE_TAG_HYSTRIX_DASHBOARD}" "${WORKSPACE}/spring-petclinic-hystrix-dashboard"
docker build --force-rm -t "${IMAGE_TAG_VETS_SERVICE}" "${WORKSPACE}/spring-petclinic-vets-service"
docker build --force-rm -t "${IMAGE_TAG_VISITS_SERVICE}" "${WORKSPACE}/spring-petclinic-visits-service"
docker build --force-rm -t "${IMAGE_TAG_GRAFANA_SERVICE}" "${WORKSPACE}/docker/grafana"
docker build --force-rm -t "${IMAGE_TAG_PROMETHEUS_SERVICE}" "${WORKSPACE}/docker/prometheus"
```

* Prepare a script to push the production docker images to the ECR repo and name it as `push-prod-docker-images-to-ecr.sh` and save it under `jenkins` folder.

``` bash
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker push "${IMAGE_TAG_ADMIN_SERVER}"
docker push "${IMAGE_TAG_API_GATEWAY}"
docker push "${IMAGE_TAG_CONFIG_SERVER}"
docker push "${IMAGE_TAG_CUSTOMERS_SERVICE}"
docker push "${IMAGE_TAG_DISCOVERY_SERVER}"
docker push "${IMAGE_TAG_HYSTRIX_DASHBOARD}"
docker push "${IMAGE_TAG_VETS_SERVICE}"
docker push "${IMAGE_TAG_VISITS_SERVICE}"
docker push "${IMAGE_TAG_GRAFANA_SERVICE}"
docker push "${IMAGE_TAG_PROMETHEUS_SERVICE}"
```

- Prepare a script to deploy the application on QA environment and save it as `deploy_app_on_prod_environment.sh` under `jenkins` folder.

```bash
echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml
AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-<put-your-name>/stable/myapp/ || echo "repository name already exists"
AWS_REGION=$AWS_REGION helm repo update
helm package k8s/petclinic_chart
AWS_REGION=$AWS_REGION helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic
kubectl create ns petclinic-prod-ns || echo "namespace petclinic-prod-ns already exists"
kubectl delete secret regcred -n petclinic-prod-ns || echo "there is no regcred secret in petclinic-prod-ns namespace"
kubectl create secret generic regcred -n petclinic-prod-ns \
    --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
AWS_REGION=$AWS_REGION helm repo update
AWS_REGION=$AWS_REGION helm upgrade --install \
    petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
    --namespace petclinic-prod-ns
```

- At this stage, we will use ``Amazon RDS`` instead of mysql pod and service. Create a mysql database on AWS RDS.

```yml
  - Engine options: MySQL
  - Version : 5.7.44
  - Templates: Free tier
  - DB instance identifier: petclinic
  - Master username: root
  - Master password: petclinic
  - Public access: Yes
  - Initial database name: petclinic
```

Not: Don't forget to open the 3306 port everywhere on the database security group.

- Delete `mysql-server-deployment.yaml` file from `k8s/petclinic_chart/templates` folder.

- Update `k8s/petclinic_chart/templates/mysql-server-service.yaml` as below.

```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert -f docker-compose.yml -o petclinic_chart/templates
    kompose.version: 1.31.2 (a92241f79)
  labels:
    io.kompose.service: mysql-server
  name: mysql-server
spec:
  type: ExternalName
  externalName: petclinic.cbanmzptkrzf.us-east-1.rds.amazonaws.com # Change this line with the endpoint of your RDS.
```

* Prepare a Jenkinsfile for `petclinic-prod` pipeline and save it as `jenkinsfile-petclinic-prod` under `jenkins` folder.

``` groovy
pipeline {
    agent any
    environment {
        PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        APP_NAME="petclinic"
        APP_REPO_NAME="clarusway-repo/petclinic-app-prod"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }
    stages {
        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Production Docker Images') {
            steps {
                echo 'Preparing Tags for Production Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_ADMIN_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:admin-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_API_GATEWAY="${ECR_REGISTRY}/${APP_REPO_NAME}:api-gateway-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CONFIG_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:config-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CUSTOMERS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:customers-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_DISCOVERY_SERVER="${ECR_REGISTRY}/${APP_REPO_NAME}:discovery-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_HYSTRIX_DASHBOARD="${ECR_REGISTRY}/${APP_REPO_NAME}:hystrix-dashboard-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VETS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:vets-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VISITS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:visits-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ECR_REGISTRY}/${APP_REPO_NAME}:prometheus-service"
                }
            }
        }
        stage('Build App Production Docker Images') {
            steps {
                echo 'Building App Production Images'
                sh ". ./jenkins/build-prod-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-prod-docker-images-to-ecr.sh"
            }
        }
        stage('Deploy App on Petclinic Kubernetes Cluster'){
            steps {
                echo 'Deploying App on K8s Cluster'
                sh ". ./jenkins/deploy_app_on_prod_environment.sh"
            }
        }
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }
    }
}
```

* Commit the change, then push the script to the remote repo.

``` bash
git add .
git commit -m 'added jenkinsfile petclinic-production for main branch'
git push --set-upstream origin feature/STEP-27
git checkout release
git merge feature/STEP-27
git push origin release
```

* Merge `release` into `main` branch to build and deploy the app on `Production environment` with pipeline.

```bash
git checkout main
git merge release
git push origin main
```

* Create a `Production Pipeline` on Jenkins with name of `petclinic-prod` with following script and configure a `github-webhook` to trigger the pipeline every `commit` on `main` branch. `Petclinic production pipeline` should be deployed on permanent prod-environment on `petclinic-cluster` Kubernetes cluster under `petclinic-prod-ns` namespace.

```yml
- job name: petclinic-prod
- job type: pipeline
- Source Code Management: Git
      Repository URL: https://github.com/[your-github-account]/petclinic-microservices.git
- Branches to build:
      Branch Specifier (blank for 'any'): */main
- Build triggers: GitHub hook trigger for GITScm polling
- Pipeline:
      Script Path: jenkins/jenkinsfile-petclinic-prod
```
* Click `save`.
* Click `Build Now`


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 28 - Setting Domain Name and TLS for Production Pipeline with Route 53
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Create `feature/STEP-28` branch from `main`.

``` bash
git checkout main
git branch feature/STEP-28
git checkout feature/STEP-28
```

* Create an `A` record of `petclinic.clarusway.us` in your hosted zone (in our case `clarusway.us`) using AWS Route 53 domain registrar and bind it to your `petclinic cluster`.

* Configure TLS(SSL) certificate for `petclinic.clarusway.us` using `cert-manager` on petclinic K8s cluster with the following steps.

- Switch user to jenkins for managing eks cluster. Execute following commands as `jenkins` user.

```bash
sudo su - jenkins
```

* Install the `cert-manager` on petclinic cluster. See [Cert-Manager info](https://cert-manager.io/docs/).

  * Create the namespace for cert-manager

  ```bash
    kubectl create namespace cert-manager
  ```

  * Add the Jetstack Helm repository.

  ```bash
  helm repo add jetstack https://charts.jetstack.io
  ```

  * Update your local Helm chart repository.

  ```bash
  helm repo update
  ```

  * Install the `Custom Resource Definition` resources separately

  ```bash
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml
  ```

  * Install the cert-manager Helm chart

  ```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.2
  ```

  * Verify that the cert-manager is deployed correctly.

  ```bash
  kubectl get pods --namespace cert-manager -o wide
  ```

* Create `ClusterIssuer` with name of `tls-cluster-issuer-prod.yml` for the production certificate through `Let's Encrypt ACME` (Automated Certificate Management Environment) with following content by importing YAML file on Ranhcer and save it under `/var/lib/jenkins` folder. *Note that certificate will only be created after annotating and updating the `Ingress` resource.*

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: callahan@clarusway.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
```

* Check if `ClusterIssuer` resource is created.

```bash
kubectl apply -f tls-cluster-issuer-prod.yml
kubectl get clusterissuers letsencrypt-prod -n cert-manager -o wide
```

- To manage EKS cluster from Rancher, start Rancher server and login.

- Next, attach policies `AmazonEKSClusterPolicy`, `AmazonEKSServicePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEKSVPCResourceController`  to Rancher server iam role. (`petclinic-tr-rke-role`)

- To import `petclinic-eks` to Rancher, go to the Rancher dashboard. Select tabs orderly; ``Cluster Management -> Import Existing -> Generic``
```yml
Cluster Name: petclinic-eks
```
``-> Create -> Registration -> copy kubectl command (Run the kubectl command below on an existing Kubernetes cluster running a supported Kubernetes version to import it into Rancher)``

* Issue production Let’s Encrypt Certificate by annotating and adding the `api-gateway` ingress resource with following through Rancher.

```yaml
metadata:
  name: api-gateway
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - petclinic.clarusway.us
    secretName: petclinic-tls
```

* Check and verify that the TLS(SSL) certificate created and successfully issued to `petclinic.clarusway.us` by checking URL of `https://petclinic.clarusway.us`

* Commit the change, then push the tls script to the remote repo.

``` bash
git add .
git commit -m 'added tls scripts for petclinic-production'
git push --set-upstream origin feature/STEP-28
git checkout main
git merge feature/STEP-28
git push origin main 
```

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
## STEP 29 - Monitoring with Prometheus and Grafana
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

* Change the port of Prometheus Service to `9090` and so that Grafana can scrape the data.

* Create a Kubernetes `NodePort` Service for Prometheus Server on Rancher to expose it.

- Go to the `Service Discovery -> Services -> prometheus -> edit yaml` page and make changes.

```yml
port: 9090
nodePort: 30002
type: NodePort
```
   
* Create a Kubernetes `NodePort` Service for Grafana Server on Rancher to expose it.

- Go to the `Service Discovery -> Services -> grafana -> edit yaml` page and make changes.

```yml
nodePort: 30003
type: NodePort
```

- Go to the worker nodes security group and open ports `30002 and 30003` to anywhere.

- Next, go to the browser and view monitoring services.

- Delete  EKS cluster via `eksctl`. It will take a while.

```bash
eksctl delete cluster -f cluster.yaml
```
