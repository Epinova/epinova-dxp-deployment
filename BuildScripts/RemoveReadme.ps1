
Write-Host "---Start---"

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $readmeFilePath = Join-Path -Path $d.FullName -ChildPath "ps_modules\readme.md"
    
    if (Test-Path $readmeFilePath){
        Write-Host $readmeFilePath
        Remove-Item -Path $readmeFilePath -Force
    }
    else {
        # Handle if we have directories for versions.
        $subdir = Get-ChildItem -Path $d.FullName -Directory
        foreach ($sd in $subdir){
            $readmeSubfilePath = Join-Path -Path $sd.FullName -ChildPath "ps_modules\readme.md"
            
            if (Test-Path $readmeSubfilePath){
                Write-Host $readmeSubfilePath
                Remove-Item -Path $readmeSubfilePath
            }
        }        
    }
}
Write-Host "---End---"