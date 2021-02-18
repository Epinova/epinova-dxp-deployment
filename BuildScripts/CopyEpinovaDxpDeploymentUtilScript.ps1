
Write-Host "---Start---"

$script = (Get-Item -Path .\Modules\EpinovaDxpDeploymentUtil.ps1).FullName

Write-Host $script

#Get-ChildItem -Path .\src -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $psmodulesPath = Join-Path -Path $d.FullName -ChildPath "ps_modules"
    $filePath = $d.FullName
    
    if (Test-Path $psmodulesPath){
        Write-Host "Copy script to $filePath"
        Copy-Item -Path $script -Destination $filePath -Recurse -Force
    }
}
Write-Host "---End---"