
Write-Host "---Start---"

$module = (Get-Item -Path .\Modules\VstsTaskSdk).FullName

Write-Host $module

#Get-ChildItem -Path .\src -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $filePath = Join-Path -Path $d.FullName -ChildPath "ps_modules"
    
    if (Test-Path $filePath){
        Write-Host $filePath
        Copy-Item -Path $module -Destination $filePath -Recurse -Force
    }
}
Write-Host "---End---"