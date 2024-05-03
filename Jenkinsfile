pipeline {
    agent any
    environment {
        APP_NAME="ozguryzl"
        APP_REPO_NAME="ozgur-yzl-repo/${APP_NAME}"
        AWS_ACCOUNT_ID=sh(script:'aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        AWS_REGION="us-east-1"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR="${APP_NAME}-kube-master-${BUILD_NUMBER}"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
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

        stage('Destroy the infrastructure'){
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve terminate'
                }
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