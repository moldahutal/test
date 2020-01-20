                <#$commitedFiles  = @()
                $commitedFiles += "commit a72106fd142bca9a130ccb6ea199c06664bcb5bd"
                $commitedFiles += "Author: DavidM <54707551+moldahutal@users.noreply.github.com>"
                $commitedFiles += "Date:   Fri Jan 17 12:24:14 2020 +0100"
                $commitedFiles += ""
                $commitedFiles += "    new test"
                $commitedFiles += ""
                $commitedFiles += "folder_to_deploy/classes/TBS_OT_OrderFlowMethods.cls"
                $commitedFiles += "folder_to_deploy/classes/TBS_OT_OrderFlowMethods.cls-meta.xml"
                $commitedFiles += "folder_to_deploy/layouts/BI_Sede__c-CPQ_LEX_Direccion.layout"
                $commitedFiles += "folder_to_deploy/layouts/TBS_OT_SOF__c-TBS_OT_InternetResale.layout"
                $commitedFiles += "folder_to_deploy/layouts/TBS_OT_SOF__c-TBS_OT_LANwLANSite.layout"
                $commitedFiles += "folder_to_deploy/layouts/TBS_OT_SOF__c-TBS_OT_MPLSVPNSite.layout"
                $commitedFiles += "folder_to_deploy/package.xml"
                $commitedFiles += ""#>

                #cls
                $targetDir = 'ToDeploy'
                $commitedFiles = @(git log -1 --name-only)
                if (!($commitedFiles -match "package.xml")) { "Error, el ultimo commit no contiene un package.xml"; exit 1 }
                if (Test-Path $targetDir) { Remove-item $targetDir -Recurse -Force -ErrorAction SilentlyContinue }
                if (!(Test-Path $targetDir)) { New-Item $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                for ($i=6; $i -lt $commitedFiles.Length; $i++) {
                    $file = $commitedFiles[$i]
                    "file -> $file"
                    $dest = "$targetDir" + $file.Substring(0, $file.LastIndexOf('/')).Replace('folder_to_deploy','').Replace('//','/')
                    "dest -> $dest"
                    if (!(Test-Path $dest)) { New-Item $dest -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
                    Copy-Item $file $dest -Force -ErrorAction SilentlyContinue
                }