Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Remove-Module -Name "Az.Storage" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"

 [string] $Environment = "Production" #Integration | Preproduction | Production
# [string] $downloadFolder = "E:\dev\temp\_blobDownloads"
# [int] $maxFilesToDownload = 30 # 0=All, 100=Max 100 downloads
# [string] $container = "indutrade-portal-assets"  #AppLogs | WebLogs | Blobs
# [bool] $overwriteExistingFiles = $true
# [int] $retentionHours = 24


Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# Get a list of all containers for a environment so that we can download correct blobs.
$containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
Write-Host "Containers:-------------------"
$containers.storageContainers | Format-Table
Write-Host "------------------------------"

$downloadFolder = "$PSScriptRoot\Downloads"
if ((Test-Path -Path $downloadFolder) -ne $true)
{
    New-Item -Path $downloadFolder -ItemType "directory"
}

#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "indutrade-portal-assets" -OverwriteExistingFiles 1 -RetentionHours 2

$files = Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Production" -DownloadFolder $downloadFolder -MaxFilesToDownload 2 -Container "AppLogs"
#Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $Environment -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 2 -Container "azure-web-logs"
#$files = Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $Environment -DownloadFolder $downloadFolder -MaxFilesToDownload 2 -Container "azure-web-logs"
Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
$files
Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
Start-Sleep -s 5
#$files | Select-Object -Last 1 | Format-Table
#$Files |Format-Table
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
#$files[-1]
#$Files[0]
#Write-Host "€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
Get-Content -Path $files[0] | Format-Table
Get-Content -Path $files[1]