# 🚀 **DevOps Project: Book My Show App Deployment**  

Welcome to the **Book My Show App Deployment** project! This project demonstrates how to deploy a **Book My Show-clone application** using modern DevOps tools and practices, following a **DevSecOps** approach.  

---

## 🛠️ **Tools & Services Used**

| **Category**       | **Tools**                                                                                                                                                                                                 |
|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Version Control** | ![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)                                                                                                       |
| **CI/CD**           | ![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat-square&logo=jenkins&logoColor=white)                                                                                                    |
| **Code Quality**    | ![SonarQube](https://img.shields.io/badge/SonarQube-4E9BCD?style=flat-square&logo=sonarqube&logoColor=white)                                                                                              |
| **Containerization**| ![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)                                                                                                       |
| **Orchestration**   | ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)                                                                                          |
| **Security**        | ![OWASP](https://img.shields.io/badge/OWASP-000000?style=flat-square&logo=owasp&logoColor=white) ![Trivy](https://img.shields.io/badge/Trivy-00979D?style=flat-square&logo=trivy&logoColor=white)         |

---
## 🚦 **Project **

README.md
============================= 
1.1 Launch VM - Ubuntu 24.04, c7i-flex.large   Launching an EC2 Instance 
    Connect to the Jenkins Server   first then access it via ssh !! 

-->create a user in AWS-console  and create  the Keys(Access & Secret Keys) with the below permissions:

1.2. Creation of IAM user (To create EKS Cluster, its not recommended to create using Root Account)

--> Attach policies to the user 
    AmazonEC2FullAccess, AmazonEKS_CNI_Policy, AmazonEKSClusterPolicy, AmazonEKSWorkerNodePolicy,  AWSCloudFormationFullAccess
    AWSCloudFormationFullAccess, IAMFullAccess, AmazonVPCFullAccess, AmazonS3FullAccess, AmazonDynamoDBFullAccess

Attach the below inline policy also for the same user
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        }
    ]
}

Attach the below inline policy also for the same user
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"kms:CreateKey",
				"kms:DescribeKey",
				"kms:ListKeys",
				"kms:ListAliases",
				"kms:EnableKey",
				"kms:DisableKey",
				"kms:ScheduleKeyDeletion",
				"kms:CancelKeyDeletion",
				"kms:PutKeyPolicy",
				"kms:CreateAlias",
				"kms:UpdateAlias",
				"kms:DeleteAlias",
				"kms:TagResource",
				"kms:UntagResource",
				"kms:UpdateKeyDescription",
				"kms:GenerateDataKey*",
				"kms:Encrypt",
				"kms:Decrypt"
			],
			"Resource": "*"
		}
	]
}
          

create a file called vi resource.sh ----> Paste the below content(SCRIPT) ---->and Installation of Required Tools

1.2 Tools Installation OF TOOLS jdk,jenkins,k8s,trivy,docker,terraform,awscli,

*****************************here i used all installations in one go***************
#!/bin/bash
set -e # stop the script if any command fails

echo "🔹 Updating system packages..."
sudo apt update && sudo apt install -y net-tools jq unzip libatomic1

echo "🔹 Installing JDK (Temurin 21)..."
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/ {print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-21-jdk -y
/usr/bin/java --version

echo "🔹 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins --no-pager

echo "🔹 Installing Terraform..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y
terraform -version

echo "🔹 Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

echo "🔹 Installing AWS CLI..."
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
aws --version

echo "🔹 Installing Trivy..."
sudo apt-get install wget apt-transport-https gnupg -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
trivy --version

echo "🔹 Installing Docker..."
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER

echo "✅ All tools installed successfully!"

=======================================================================

Defaultly when we install Jenkins it creats the Jenkins user also:  so  We need to give the required Privelages to this Jenkins User so  

  sudo usermod -aG sudo jenkins     // adding Jenkins user into Sudo group
  sudo usermod -aG  docker jenkins  // adding Jenkins user into docker group
  sudo systemctl restart docker
  sudo chmod 666 /var/run/docker.sock
  sudo passwd jenkins
  giv ur paswd : abc@123
  confirm ur paswd : abc@123
  sudo su - Jenkins 
  Jenkins # aws configure   // here we have to  give our access & secret keys 

===============================================================================
=====================to add swap-memory  extra memory to our existing machine use this commands if you need. ============================================= 

Swap is not RAM, it’s disk space used as “extra virtual memory” when RAM is full. It helps your system run smoothly and prevents out-of-memory errors.

sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo bash -c 'echo "/swapfile swap swap defaults 0 0" >> /etc/fstab'

=============================  
2. SonarQube Setup  
=============================  
Connect to the Jenkins Server  
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community  
docker images  
docker ps  

Access SonarQube, after opening port 9000  
Default username and Password: admin  admin
Set new password as your requirement

--> For Sonar token Creation
    admin--> security --> users --> generate token with name sonar-token

--> For webhook configuration in sonar
    admin --> Confiagurations --> webhooks --> create 
    name:jenkins
    url: http://13.201.135.9:8080//sonarqube-webhook/  create


************************************  
Step 3: Access Jenkins Dashboard  
************************************  
Setup the Jenkins  

3.1. Plugins installation  in jenkins Console  
Install below plugins;  
Eclipse Temurin Installer, SonarQube scanner, NodeJS, Docker, Docker Commons, Docker Pipeline, Docker API, ThinBackup 
docker-build-step, Pipeline stage view, Email Extension Template, Kubernetes, Kubernetes CLI, pipeline-stage-view, BlueOcean 
 Kubernetes Client API, Kubernetes Credentials, Config File Provider, AWS Steps .

3.2. SonarQube Token Creation in jenkins console   
Configure the SonarQube server; in jenkins console   
Token: squ_69eb05b41575c699579c6ced901eaafae66d63a2  

we need to add a sonarqube-webhook also projects --> administartion --> groups -->  

3.3. Creation of Credentials 
     we need to create :  1.sonar-token, 2.emil-creds-from(App-password), 3.dockerhub-creds, 4. Access-keys 
3.4. Tools Configuration  
     we need to configure:  java21, nodejs16, sonar-scanner, docker, 

3.5 System Configuration in Jenkins  
     we need to configure: sonar-server in system & Email notifications , backup-path   

************************************  
Step 4: Email Integration  
************************************  
As soon as the build happens, i need to get an email notification to do that we have to configure our email.
Goto Gmail ---> Click on Icon on top right ---> Click on 'Your google account' ---> in search box at top, search for 'App  Passwords' and click on it, Enter password of gmail ---> Next ---> App name: jenkins ---> Create ---> You can see the password (ex: fxssvxsvfbartxnt) ---> Copy it ---> Make sure to remove the spaces in the password. Lets configure this password in Jenkins.

Goto the Jenkins console ---> Manage Jenkins ---> Security ---> Credentials ---> Under 'Stores scoped to Jenkins', Click on 'Global' under 'Domains' ---> Add credentials ---> A dia ---> Kind: Username with Password, Scope: Global, Username: <ProvideEmail ID>, Password: <PasteTheToken>, ID: email-creds, Description: email-creds ---> Create ---> You can see the email credentials got created.

Manage Jenkins ---> System ---> Scroll down to 'Extended Email Notification' ---> SMTP Server: smtp.gmail.com ---> SMTP Port: 465, Click on 'Advanced'  ---> Credentials: Select 'email creds' from drop down, 'Check' Use SSL and Use OAuth 2.0, Default content type: HTML

Scroll down to 'Email Notification' ---> SMTP Server: smtp.gmail.com ---> Click on 'Advanced'  ---> 'Check' Use SMTP Authentication, Username: <ProvideEmailID>, Password: <PasteThePasswordToken>, 'Check' Use SSL, SMTP Port: 465, Reply-to-email: <ProvideEmail>, Charset: UTF-8,, Check 'Test configuration by sending test e-mail', Test Email Recepient: <provide-email-id>, Click on 'Test Configuration' ---> You can see 'email sent' ---> Goto email and check for test email

Lets make another configuration to get an email when build fails/success ---> Goto 'Default Triggers' drop down (If you cannot find this, try searching using control+f ---> 'Check' Always, Failure-Any, Success ---> Apply ---> Save 

-------------------  
Install NPM  
-------------------  
apt install npm  

************************************
Step 5: Create Pipeline Job  
************************************
Before pasting the pipeline script, do the following changes in the script
1. In the stage 'Tag and Push to DockerHub', give your docker-hub username. Similar thing you should do in 'Deploy to container' stage.
2. In post actions stage in pipeline, make sure to give the email id you have configured in jenkins.

******************************************* PIPELINE CODE ****************************************************
                You can see the Jenkinsfile in this repo fr pipeline-as-Code....

THANK YOU......


---