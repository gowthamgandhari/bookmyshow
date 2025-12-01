
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
                    sh ''' 
                    $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=bookmyshow \
                        -Dsonar.projectKey=bookmyshow
                    '''
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
                sh '''
                cd bookmyshow-app
                ls -la  # Verify package.json exists
                if [ -f package.json ]; then
                    rm -rf node_modules package-lock.json  # Remove old dependencies
                    npm install  # Install fresh dependencies
                else
                    echo "Error: package.json not found in bookmyshow-app!"
                    exit 1
                fi
                '''
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivy-fs-report.txt'
            }
        }

        stage('Docker Build') {
            steps {
                dir('bookmyshow-app'){
                    sh 'pwd'
                    sh 'ls -la'
                    sh 'docker build -t bms -f $WORKSPACE/bookmyshow-app/Dockerfile $WORKSPACE/bookmyshow-app'
                    // sh 'docker build -t bms -f Dockerfile .'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                //sh 'trivy image --scanners vuln bms-app > trivy-image-report.txt'
                 sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 bms'
                // sh 'trivy image --severity HIGH,CRITICAL --format json -o trivy-report.json bms'
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
                        sh '''
                        docker tag bms gowthamcloud268/bms:latest
                        docker push gowthamcloud268/bms:latest
                        '''
                    }
                }
            }
        }

        stage('Create S3 Backend Bucket') {
           steps {
               withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                   sh '''
                   aws s3api create-bucket --bucket bms-tf-state-bucket \
                   --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1 || true
                   
                   aws dynamodb create-table \
                   --table-name bms-tf-lock \
                   --attribute-definitions AttributeName=LockID,AttributeType=S \
                   --key-schema AttributeName=LockID,KeyType=HASH \
                   --billing-mode PAY_PER_REQUEST || true
                   '''
               }
           }
       }


        stage('Terraform EKS Init/fmt/validate & Apply') {
          when {
              expression { currentBuild.currentResult == 'SUCCESS' }
          }
          steps {
              withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                  dir('BMS-Application/Terraform-Code-for-EKS-Cluster/terraform') {
                      sh '''
                          terraform init
                          terraform fmt
                          terraform validate
                          terraform apply -auto-approve
                      '''
                  }
              }
          }
      }

        stage('Deploy to EKS') {
           steps {
               dir('BMS-Application') {
                   withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                       sh '''
                           echo "Waiting for EKS cluster to become active..."
                           aws eks wait cluster-active --name $EKS_CLUSTER_NAME
                           aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
                           kubectl apply -f deployment.yml
                           kubectl apply -f service.yml
                       '''
                   }
               }
           }
       }
    }

    post {
    success {
        emailext attachLog: true,
            subject: "SUCCESS: ${env.JOB_NAME}",
            body: "Build SUCCESS 🎯<br/>" +
                  "Project: ${env.JOB_NAME}<br/>" +
                  "Build Number: ${env.BUILD_NUMBER}<br/>" +
                  "URL: ${env.BUILD_URL}<br/>",
            to: 'gowthameswar88@gmail.com',
            attachmentsPattern: 'trivy-fs-report.txt'
    }

    failure {
        emailext attachLog: true,
            subject: "FAILED: ${env.JOB_NAME}",
            body: "Build FAILED ❌<br/>" +
                  "Project: ${env.JOB_NAME}<br/>" +
                  "Build Number: ${env.BUILD_NUMBER}<br/>" +
                  "Check Logs: ${env.BUILD_URL}",
            to: 'gowthameswar88@gmail.com',
            attachmentsPattern: 'trivy-fs-report.txt'
    }
    }
}
