Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Remove-Module -Name "Az.Storage" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"

 [string] $Environment = "Integration" #Integration | Preproduction | Production
# [string] $downloadFolder = "E:\dev\temp\_blobDownloads"
# [int] $maxFilesToDownload = 30 # 0=All, 100=Max 100 downloads
# [string] $container = "indutrade-portal-assets"  #AppLogs | WebLogs | Blobs
# [bool] $overwriteExistingFiles = $true
[int] $retentionHours = 2


Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# Get a list of all containers for a environment.
$containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
Write-Host "Containers:-------------------"
$containers.storageContainers | Format-Table
Write-Host "------------------------------"

