$targetDir = 'ToDeploy'
$commitedFiles = @(git log -1 --name-only)

if (!($commitedFiles -match "package.xml")) { "Error, el ultimo commit no contiene un package.xml"; exit 1 }
if (Test-Path $targetDir) { Remove-item $targetDir -Recurse -Force -ErrorAction SilentlyContinue }
if (!(Test-Path $targetDir)) { New-Item $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
for ($i=6; $i -lt $commitedFiles.Length; $i++) {
    $file = $commitedFiles[$i]
    # Evito los archivos JenkinsFile y los archivos meta
    if (($file -match 'Jenkinsfile') -or ($file -match '-meta.xml')) { continue }
    # Para evitar problemas con los archivos que necesitan otros archivos quito la extension y copio todo lo que se llame igual
    $file = $file.Replace((Get-ChildItem $file).Extension,'')
    $dest = "$targetDir" + $file.Substring(0, $file.LastIndexOf('/')).Replace('folder_to_deploy','').Replace('//','/')
    "Copiando de -> $file* a -> $dest"
    if (!(Test-Path $dest)) { New-Item $dest -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
    Copy-Item $file*.* $dest -Force -ErrorAction SilentlyContinue
}
