Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Rmove-Module -Name "Az.Storage" -Verbose
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
# [int] $retentionHours = 24


Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
#     Install-Module EpiCloud -Scope CurrentUser -Force
# }
#$connectResult = Connect-EpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId
#$connectResult

    # $storageContainerSplat = @{
    #     ClientKey      = $ClientKey
    #     ClientSecret   = $ClientSecret
    #     ProjectId      = $ProjectId
    #     Environment    = "Integration"
    # }

    # #$containers = $null
    # $containers = Get-EpiStorageContainer @storageContainerSplat
    #$containers = Get-EpiStorageContainer -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment "Integration"

# Get a list of all containers for a environment so that we can download correct blobs.
$containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
#$containers
#$containers | Format-Table
Write-Host "Containers:-------------------"
$containers.storageContainers | Format-Table
Write-Host "------------------------------"

#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "indutrade-portal-assets" -OverwriteExistingFiles 1 -RetentionHours 2

#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Production" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "AppLogs"
#$Files = $null
Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $Environment -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 2 -Container "azure-web-logs"
#$files = Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $Environment -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 2 -Container "azure-web-logs"
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
#$files
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
#$files | Select-Object -Last 1 | Format-Table
#$Files |Format-Table
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
#$files[-1]
#$Files[0]
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
#Get-Content -Path $files[0]