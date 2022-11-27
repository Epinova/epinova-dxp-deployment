
Write-Host "---Start---"

$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $filePath = Join-Path -Path $d.FullName -ChildPath "ps_modules\readme.md"
    
    if (Test-Path $filePath){
        Write-Host $filePath
        Remove-Item -Path $filePath -Force
    }
    else {
        # Handle if we have directories for versions.
        $subdir = Get-ChildItem -Path $d.FullName -Directory
        foreach ($sd in $subdir){
            $subfilePath = Join-Path -Path $sd.FullName -ChildPath "ps_modules\readme.md"
            
            if (Test-Path $subfilePath){
                Write-Host $subfilePath
                Remove-Item -Path $subfilePath
            }
        }        
    }
}
Write-Host "---End---"