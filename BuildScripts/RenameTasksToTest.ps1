Write-Host "---Start---"
$srcRootPath = (Get-Item * | Where-Object {$_.FullName.EndsWith("src")})

Write-Host "Root: $srcRootPath"

$tasksfiles = Get-ChildItem -Path $srcRootPath -Filter task.json -Recurse -ErrorAction SilentlyContinue -Force
foreach ($taskfile in $tasksfiles){
  $filePath = $taskfile.FullName
  Write-Host "Load task file: $filePath"
  if (Test-Path $filePath){
    $a = Get-Content $filePath -raw | ConvertFrom-Json
    $newFriendlyName = "$($a.friendlyName)-TEST"
    $a.friendlyName = "$newFriendlyName"
    Write-Host "Set friendlyName: $newFriendlyName"
    $newName = "$($a.name)-TEST"
    $a.name = "$newName"
    Write-Host "Set name: $newName"

    $a | ConvertTo-Json -depth 32| set-content $filePath
    Write-Host "Save changes to: $filePath"
  }
}

Write-Host "---End---"
