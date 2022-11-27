
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
        #if ($subdir.EndsWith("V1") -or $subdir.EndsWith("V2")){
            foreach ($sd in $subdir){
                $subfilePath = Join-Path -Path $sd.FullName -ChildPath "ps_modules"
                
                if (Test-Path $subfilePath){
                    Write-Host $subfilePath
                    Copy-Item -Path $module -Destination $subfilePath -Recurse -Force
                }
            }
        #}        
    }
}

#$module = (Get-Item -Path .\Modules\EpiCloudv1).FullName
#Write-Host $module
##Get-ChildItem -Path .\src -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
#$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
#$dir = Get-ChildItem -Path $srcRootPath -Directory
#foreach ($d in $dir){
#    # Handle if we have directories for versions.
#    $subdir = Get-ChildItem -Path $d.FullName -Directory
#    if ($subdir.EndsWith("V3")){
#        foreach ($sd in $subdir){
#            $subfilePath = Join-Path -Path $sd.FullName -ChildPath "ps_modules"
#            
#            if (Test-Path $subfilePath){
#                Write-Host $subfilePath
#                Copy-Item -Path $module -Destination $subfilePath -Recurse -Force
#                $oldName = Join-Path -Path $subfilePath -ChildPath "EpiCloudv1"
#                $newName = Join-Path -Path $subfilePath -ChildPath "EpiCloud"
#                Rename-Item $oldName $newName
#            }
#        }        
#    }
#}
Write-Host "---End---"