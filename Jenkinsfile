pipeline {
    agent any
    stages {
        stage('1. Connecting to AUTUAT'){
            steps {
                bat 'sfdx force:auth:jwt:grant --clientid 3MVG9w8uXui2aB_rEa7IWhGCNoVWweg65EYZ2ycWxt8KBMrTBZ67SKR6m4KMO_MGpiPlJHCy8dUnsKYxoBdQP --jwtkeyfile server.key --username release.manager@telefonicab2b.com.autuat --setdefaultdevhubusername'
            }
        }
        stage('2. Copying Commited Files...') {
            steps { 
                bat '
                powershell -NonInteractive -ExecutionPolicy Bypass -Command "
                $commitedFiles = @(git log -1 --name-only)
                if (Test-Path ToDeploy) { Remove-item ToDeploy -Recurse -Force -ErrorAction SilentlyContinue }
                if (!(Test-Path ToDeploy)) { New-Item ToDeploy -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                for ($i=6; $i -lt $commitedFiles.Length -1; $i++) {
                    $file = $commitedFiles[$i]
                    $targetDir = "ToDeploy"
                    $dest = "ToDeploy/" + $file.Substring(0, $file.LastIndexOf("/"))
                    if (!(Test-Path $dest)) { New-Item $dest -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                    Copy-Item $file $dest -Force -ErrorAction SilentlyContinue
                }
                
                "'
                bat 'sfdx force:mdapi:deploy -c -w 60 -d "C:/Program Files (x86)/Jenkins/workspace/JenDemoWithSFDX_GitMoldaTest/folder_to_deploy/ToDeploy" -u release.manager@telefonicab2b.com.autuat'
            }
        }
        stage('3. Deploying...') {
            steps { 
                bat 'sfdx force:mdapi:deploy -w 60 -d "C:/Program Files (x86)/Jenkins/workspace/JenDemoWithSFDX_GitMoldaTest/folder_to_deploy/ToDeploy" -u release.manager@telefonicab2b.com.autuat'
            }
        }
    }
}
