
Write-Host "---Start---"

$module1 = (Get-Item -Path .\Modules\EpinovaDxpDeploymentUtil).FullName

Write-Host $module1

#Get-ChildItem -Path .\src -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $filePath = Join-Path -Path $d.FullName -ChildPath "ps_modules"
    
    if (Test-Path $filePath){
        Write-Host $filePath
        Copy-Item -Path $module1 -Destination $filePath -Recurse -Force
    }
}
Write-Host "---End---"