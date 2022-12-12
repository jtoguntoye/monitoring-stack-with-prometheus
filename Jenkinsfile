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
                sh 'cat $BRANCH_NAME.tfvars'
                sh 'terraform init -no-color'
            }
        }
        stage('Plan'){
            steps{
            sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
        
       
        
        stage ('Validate Terraform apply') {
        
         when {
           beforeInput true
           branch "dev"
        }
        input{
        message "Do you want to apply this plan"
        ok "Apply plan"
        }
        steps{
           echo 'Apply Accepted'   
         }
        }
        stage('Apply'){
            steps{
            sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
        
        stage('Inventory') {
          steps {
                sh '''printf \\
                    "\\n$(terraform output -json instance_ips | jq -r \'.[]\')" \\
                    >> aws_hosts'''
            }
        }
        
         stage('EC2 Wait') {
            steps {
                sh '''aws ec2 wait instance-status-ok \\
                    --instance-ids $(terraform output -json instance_ids | jq -r \'.[]\') \\
                    --region eu-west-3'''
            }
        }
        
        stage ('Manually approve Ansible playbook run') {
        
        when {
           beforeInput true
           branch "dev"
        }
        input{
        message "Do you want to run the playbook"
        ok "Run playbook"
        }
        steps{
           echo 'Accepted'   
         }
        }
        stage('Ansible bootstrapping') {
        steps{
         ansiblePlaybook(credentialsId: 'ssh-key', inventory: 'aws_hosts', playbook: 'playbooks/main_playbook.yml')
          }
        }
        
        stage ('Manually approve Terraform destroy') {
        input{
        message "Do you want to Destroy infrastructure"
        ok "Approve Terraform destroy"
        }
        steps{
           echo 'Approved'   
         }
        }
        stage('Destroy'){
            steps{
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
        
    }
    
     post {
        always {
            deleteDir() /* clean up our workspace */
        }
        success {
            echo 'I succeeded!'
        }
       
        failure {
            echo 'Pipeline failed'
        }
        aborted {
        sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
}