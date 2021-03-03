Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"

# [string] $environment = "Preproduction" #Integration | Preproduction | Production
# [string] $downloadFolder = "E:\dev\temp\_blobDownloads"
# [int] $maxFilesToDownload = 30 # 0=All, 100=Max 100 downloads
# [string] $container = "indutrade-portal-assets"  #AppLogs | WebLogs | Blobs
# [bool] $overwriteExistingFiles = $true
# [int] $retentionHours = 24


#Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# Get a list of all containers for a environment so that we can download correct blobs.
$containers = Get-DxpStorageContainers -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration"
$containers
#$containers | Format-Table
$containers.storageContainers | Format-Table

#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "indutrade-portal-assets" -OverwriteExistingFiles 1 -RetentionHours 2

#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Production" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "AppLogs"
Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "WebLogs"