Write-Host "---Start---"
$srcRootPath = (Get-Item * | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
      $filePath = Join-Path -Path $d.FullName -ChildPath "task.json"
      if (Test-Path $filePath){
        #Write-Host "FilePath: $filePath"

        $a = Get-Content $filePath -raw | ConvertFrom-Json
        
        $newFriendlyName = "$($a.friendlyName)-TEST"
        $a.friendlyName = "$newFriendlyName"

        $newName = "$($a.name)-TEST"
        $a.name = "$newName"
        
        $a | ConvertTo-Json -depth 32| set-content $filePath
        Write-Host "Updated: $filePath"
      }
}
Write-Host "---End---"
