
Write-Host "---Start---"

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $filePath = Join-Path -Path $d.FullName -ChildPath "ps_modules\readme.md"
    
    if (Test-Path $filePath){
        Write-Host $filePath
        Remove-Item -Path $filePath -Force
    }
}
Write-Host "---End---"