$targetDir = 'ToDeploy'
$commitedFiles = @(git log -1 --name-only)
if (!($commitedFiles -match "package.xml")) { "Error, el ultimo commit no contiene un package.xml"; exit 1 }
if (Test-Path $targetDir) { Remove-item $targetDir -Recurse -Force -ErrorAction SilentlyContinue }
if (!(Test-Path $targetDir)) { New-Item $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
for ($i=6; $i -lt $commitedFiles.Length; $i++) {
    $file = $commitedFiles[$i]
    if ($file -match '%Jenkinsfile%') { continue }
    $dest = "$targetDir" + $file.Substring(0, $file.LastIndexOf('/')).Replace('folder_to_deploy','').Replace('//','/')
    "Copiando de -> $file a -> $dest"
    if (!(Test-Path $dest)) { New-Item $dest -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
    Copy-Item $file $dest -Force -ErrorAction SilentlyContinue
}
