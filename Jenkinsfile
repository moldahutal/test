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
                bat 'sfdx force:source:deploy -p .'
            }
        }
    }
}
