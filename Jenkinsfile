pipeline {
    agent any
    stages {
        stage('Connect to Salesforce APP - AUTUAT'){
            steps {
                bat 'sfdx force:auth:jwt:grant --clientid 3MVG9w8uXui2aB_rEa7IWhGCNoVWweg65EYZ2ycWxt8KBMrTBZ67SKR6m4KMO_MGpiPlJHCy8dUnsKYxoBdQP --jwtkeyfile server.key --username release.manager@telefonicab2b.com.autuat --setdefaultdevhubusername'
            }
        }
        stage('Build') {
            steps { 
                bat 'sfdx force:mdapi:deploy -c -d "C:/Program Files (x86)/Jenkins/workspace/JenDemoWithSFDX_GitMoldaTest/folder_to_deploy" -u release.manager@telefonicab2b.com.autuat'
            }
        }
    }
}
