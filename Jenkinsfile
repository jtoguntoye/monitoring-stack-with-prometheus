pipeline {
    agent any
    environment {
    TF_IN_AUTOMATION='true'
    }
    stages {
        stage('Init') {
            steps {
                sh 'ls'
                sh 'terraform init -no-color'
            }
        }
        stage{
            steps{
            
            sh 'terraform plan -no-color'
            
            }
        }
    }
}