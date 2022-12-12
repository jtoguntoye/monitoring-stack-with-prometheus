pipeline {
    agent any
    environment {
       TF_IN_AUTOMATION='true'
       TF_CLI_CONFIG_FILE=credentials('Terraform-cloud')
       AWS_SHARED_CREDENTIALS_FILE='/home/ubuntu/.aws/credentials'
    }
    stages {
        stage('Init') {
            steps {
                sh 'ls'
                
                sh 'terraform init -no-color'
            }
        }
        stage('Plan'){
            steps{
            sh 'terraform plan -no-color'
            }
        }
        stage('Apply'){
            steps{
            sh 'terraform apply -auto-approve -no-color'
            }
        }
        stage ('EC2 Await') {
        steps{
         sh 'aws ec2 wait instance-status-ok --region eu-west-3'
          }
        }
        
        stage('Ansible bootstrapping') {
        steps{
         ansiblePlaybook(credentialsId: 'ssh_key', inventory: 'aws_hosts', playbook: 'playbooks/main_playbook.yml')
        }
        }
        stage('Destroy'){
            steps{
            sh 'terraform destroy -auto-approve -no-color'
            }
        }
        
    }
}