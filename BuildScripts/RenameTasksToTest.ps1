Write-Host "---Start---"

function UpdateJson($jsonFilePath){
  $a = Get-Content $jsonFilePath -raw | ConvertFrom-Json

  $newFriendlyName = "$($a.friendlyName)-TEST"
  $a.friendlyName = "$newFriendlyName"

  $newName = "$($a.name)-TEST"
  $a.name = "$newName"

  $a | ConvertTo-Json -depth 32| set-content $jsonFilePath
  Write-Host "Updated: $jsonFilePath"
}

$srcRootPath = (Get-Item * | Where-Object {$_.FullName.EndsWith("src")})

Write-Host "Root: $srcRootPath"

$tasksfiles = Get-ChildItem -Path $srcRootPath -Filter task.json -Recurse -ErrorAction SilentlyContinue -Force
foreach ($taskfile in $tasksfiles){
  $filePath = $taskfile.FullName
  Write-Host "Load task file: $filePath"
  if (Test-Path $filePath){
    UpdateJson $filePath
  }
  else {
      # Handle if we have directories for versions.
      $subdir = Get-ChildItem -Path $d.FullName -Directory
      foreach ($sd in $subdir){
          #Write-Host "$($sd.FullName)"
          $subfilePath = Join-Path -Path $sd.FullName -ChildPath "task.json"
        
          if (Test-Path $subfilePath){
              #Write-Host $subfilePath
              UpdateJson $subfilePath
          }
      }
  }
}

Write-Host "---End---"
