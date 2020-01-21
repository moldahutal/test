pipeline {
    agent any
    triggers {
        // Trigger para ejecutar el pipeline cada 5 minutos entre las 9 y las 18 de lunes a viernes
        cron('H/5 9-18 * * 1-5')
    }
    stages {
        stage('1. Connecting to AUTUAT'){
            steps {
                bat 'sfdx force:auth:jwt:grant --clientid 3MVG9w8uXui2aB_rEa7IWhGCNoVWweg65EYZ2ycWxt8KBMrTBZ67SKR6m4KMO_MGpiPlJHCy8dUnsKYxoBdQP --jwtkeyfile server.key --username release.manager@telefonicab2b.com.autuat --setdefaultdevhubusername'
            }
        }
        stage('2. Copying Commited Files...') {
            steps { 
                bat 'powershell -NonInteractive -ExecutionPolicy Bypass -file Jenkinsfile.ps1'
            }
        }
        stage('3. Deploying...') {
            steps {
                // validate command
                // bat 'sfdx force:mdapi:deploy -c -w 60 -d "C:/Program Files (x86)/Jenkins/workspace/JenDemoWithSFDX_GitMoldaTest/folder_to_deploy/ToDeploy" -u release.manager@telefonicab2b.com.autuat'
                // deploy command
                bat 'sfdx force:mdapi:deploy -w 60 -d "C:/Program Files (x86)/Jenkins/workspace/JenDemoWithSFDX_GitMoldaTest/ToDeploy" -u release.manager@telefonicab2b.com.autuat'
            }
        }
    }
}
