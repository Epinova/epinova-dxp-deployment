Set-StrictMode -Version Latest 

#Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpDeploymentUtil.ps1
. C:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

[string] $Environment = "Integration" #Integration | Preproduction | Production


Set-ExecutionPolicy -Scope CurrentUser Unrestricted

$dropPath = $PSScriptRoot
$packageFileInfo = Get-ChildItem -Path $dropPath -Filter "*.cms.app.*.nupkg"

#$packageFileInfo
$sufix = $Environment.Substring(0, [Math]::Min($Environment.Length, 3)) + (Get-Date.Millisecond)

$newFileName = $packageFileInfo.Name.Replace(".nupkg", "_$($sufix).nupkg")

Rename-Item -Path $packageFileInfo.FullName -NewName $newFileName

$packageFileInfo = Get-ChildItem -Path $dropPath -Filter "*.cms.app.*.nupkg"

$packageFileInfo

# Get a list of all containers for a environment.
#$containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
#Write-Host "Containers:-------------------"
#$containers.storageContainers | Format-Table
#Write-Host "------------------------------"

