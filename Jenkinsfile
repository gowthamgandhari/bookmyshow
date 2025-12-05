pipeline {
    agent any

    tools {
        jdk 'jdk21'
        nodejs 'nodejs23'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        EKS_CLUSTER_NAME = 'BookMyShow-eks'
        AWS_REGION = 'ap-south-1'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
    
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/gowthamgandhari/bookmyshow.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=bookmyshow \
                        -Dsonar.projectKey=bookmyshow
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                    cd bookmyshow-app
                    ls -la
                    if [ -f package.json ]; then
                        rm -rf node_modules package-lock.json
                        npm install
                    else
                        echo "Error: package.json not found in bookmyshow-app!"
                        exit 1
                    fi
                """
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivy-fs-report.txt'
            }
        }

        stage('Docker Build') {
            steps {
                dir('bookmyshow-app') {
                    sh 'pwd'
                    sh 'ls -la'
                    sh 'docker build -t bms .'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 bms'
            }
        }
        
        stage('Manual Approval') {
            steps {
                input(message: 'Approve deployment?', ok: 'Proceed')
            }
        }
        
        stage('Docker Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-creds') {
                        sh """
                            docker tag bms gowthamcloud268/bms:latest
                            docker push gowthamcloud268/bms:latest
                        """
                    }
                }
            }
        }

        stage('Create S3 Backend Bucket') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
        
                    // Create S3 bucket only if it does NOT already exist
                    sh """
                        if aws s3api head-bucket --bucket bms-tf-state-bucket 2>/dev/null; then
                            echo "S3 bucket already exists. Skipping creation."
                        else
                            echo "Creating S3 bucket..."
                            aws s3api create-bucket \
                                --bucket bms-tf-state-bucket \
                                --region ap-south-1 \
                                --create-bucket-configuration LocationConstraint=ap-south-1
                        fi
                    """
        
                    // Create DynamoDB table only if it does NOT already exist
                    sh """
                        if aws dynamodb describe-table --table-name bms-tf-lock 2>/dev/null; then
                            echo "DynamoDB table already exists. Skipping creation."
                        else
                            echo "Creating DynamoDB table..."
                            aws dynamodb create-table \
                                --table-name bms-tf-lock \
                                --attribute-definitions AttributeName=LockID,AttributeType=S \
                                --key-schema AttributeName=LockID,KeyType=HASH \
                                --billing-mode PAY_PER_REQUEST
                        fi
                    """
                }
            }
        }

        stage('Debug Terraform Path') {
            steps {
                sh '''
                    echo "Current directory: $(pwd)"
                    ls -R BMS-APPLICATION/Terraform-Code-for-EKS-Cluster/terraform
                '''
            }
        }

        stage('Terraform EKS Init/fmt/validate & Apply') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    dir('BMS-APPLICATION/Terraform-Code-for-EKS-Cluster/terraform') {
                        sh """
                            sh 'ls -la'
                            terraform init
                            terraform fmt
                            terraform validate
                            terraform apply -auto-approve
                        """
                    }
                }
            }
        }

        stage('Deploy to EKS') {
           steps {
               dir('BMS-APPLICATION') {
                   withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                       sh """
                           echo "Waiting for EKS cluster to become active..."
                           aws eks wait cluster-active --name $EKS_CLUSTER_NAME
                           aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
                           kubectl apply -f deployment.yml
                           kubectl apply -f service.yml
                       """
                    }
                }
            }
        }
    }

    post {
        always {
            emailext(
                attachLog: true,
                subject: "BUILD STATUS: ${currentBuild.currentResult} - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """<b>Project:</b> ${env.JOB_NAME}<br/>
                         <b>Build Number:</b> ${env.BUILD_NUMBER}<br/>
                         <b>Status:</b> ${currentBuild.currentResult}<br/>
                         <b>URL:</b> ${env.BUILD_URL}""",
                to: 'gowthameswar88@gmail.com',
                recipientProviders: [
                    [$class: 'DevelopersRecipientProvider'],
                    [$class: 'RequesterRecipientProvider']
                ],
    
                attachmentsPattern: 'trivy-fs-report.txt'
            )
        }
    }
}
