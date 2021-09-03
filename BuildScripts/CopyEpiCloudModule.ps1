
Write-Host "---Start---"

$module = (Get-Item -Path .\Modules\EpiCloud).FullName

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
    else {
        # Handle if we have directories for versions.
        $subdir = Get-ChildItem -Path $d.FullName -Directory
        foreach ($sd in $subdir){
            $subfilePath = Join-Path -Path $sd.FullName -ChildPath "ps_modules"
            
            if (Test-Path $subfilePath){
                Write-Host $subfilePath
                Copy-Item -Path $module -Destination $subfilePath -Recurse -Force
            }
        }        
    }
}
Write-Host "---End---"