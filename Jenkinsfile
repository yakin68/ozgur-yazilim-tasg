pipeline {
    agent any
    environment {
        APP_NAME="ozguryzl"
        APP_REPO_NAME="ozgur-yzl-repo/${APP_NAME}"
        AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR="${APP_NAME}-kube-master-${BUILD_NUMBER}"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}.pem"
        ANSIBLE_HOST_KEY_CHECKING="False"
    }
    stages {
        stage('Check S3 Bucket') {
            steps {
                script {
                    try {
                        sh 'aws s3api head-bucket --bucket ${APP_NAME}-helm-charts-repo --region us-east-1'
                        echo 'Bucket already exists'
                    } catch (Exception e) {
                        echo 'Bucket does not exist. Creating...'
                        sh 'aws s3api create-bucket --bucket ${APP_NAME}-helm-charts-repo --region us-east-1'
                        sh 'aws s3api put-object --bucket ${APP_NAME}-helm-charts-repo --key stable/myapp/'
                    }
                }
            }
        }
        stage('Create ECR Private Repo') {
            steps {
                echo "Creating ECR Private Repo for ${APP_NAME}"
                sh '''
                aws ecr describe-repositories --repository-name ${APP_REPO_NAME} --region $AWS_REGION || \
                    aws ecr create-repository \
                    --repository-name ${APP_REPO_NAME} \
                    --image-scanning-configuration scanOnPush=true \
                    --image-tag-mutability MUTABLE \
                    --region  $AWS_REGION
                '''
                }
        }
        stage('Package application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_OZGURYZL="${ECR_REGISTRY}/${APP_REPO_NAME}:${APP_NAME}-v${MVN_VERSION}-b${BUILD_NUMBER}"
                }
            }
        }
        stage('Build App Docker Images') {
            steps {
                echo 'Building ${APP_NAME} App Dev Images'
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
        stage('Push Helm chart to S3') {
            steps {
                echo "Pushing helm chart"
                sh "envsubst < k8s/ozguryzl_chart/values-template.yaml > k8s/ozguryzl_chart/values.yaml"
                sh "sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/ozguryzl_chart/Chart.yaml"
                sh "helm plugin install https://github.com/hypnoglow/helm-s3.git || true"
                sh "AWS_REGION=us-east-1 helm s3 init s3://${APP_NAME}-helm-charts-repo/stable/myapp || true"
                sh "AWS_REGION=us-east-1 helm repo add stable-${APP_NAME} s3://${APP_NAME}-helm-charts-repo/stable/myapp/ || true"
                sh "helm package k8s/ozguryzl_chart"
                sh "helm s3 push --force ozguryzl_chart-${BUILD_NUMBER}.tgz stable-${APP_NAME}"
            }
        }        
        stage('Create Key Pair for Ansible') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                sh "aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${ANS_KEYPAIR}.pem"
                sh "chmod 400 ${ANS_KEYPAIR}.pem"
            }
        }
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
                    env.id = sh(script: 'aws ec2 describe-instances --filters Name=tag-value,Values=master Name=tag-value,Values=kube-master Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text',  returnStdout:true).trim()
                    sh 'aws ec2 wait instance-status-ok --instance-ids $id'
                }
            }
        }
        stage('Deploy App on Kubernetes cluster'){
            steps {
                echo 'Deploying App on Kubernetes'
                sh "envsubst < ansible/playbooks/dev-ozguryzl-deploy-template > ansible/playbooks/dev-ozguryzl-deploy.yaml"
                sh "pip show botocore"
                sh "pip show boto3"
                sh "python3 --version"
                sh "ansible --version"
                sh "ansible-playbook --version"
                sh "ansible-inventory --graph"
                sh "ansible-galaxy --version"
                sh "ansible-inventory --graph -v -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml"
                sh "ansible -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml all -m ping"
                timeout(time:5, unit:'DAYS') 
                sh "ansible-playbook -i ./ansible/inventory/dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/dev-ozguryzl-deploy.yaml"
            }
        } 

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
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
            echo 'Delete the Image Repository on ECR'
        }
        failure {
            sh """
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION}\
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
            echo "Delete existing key pair using AWS CLI"
            sh "aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}"
            sh "rm -rf ${ANS_KEYPAIR}.pem"
         

        }
    }
}