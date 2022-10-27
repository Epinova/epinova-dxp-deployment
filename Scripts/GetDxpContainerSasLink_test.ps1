Set-StrictMode -Version Latest 

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Remove-Module -Name "Az.Storage" -Verbose
Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. C:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1

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

#$sasLink = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Container "image-resizer-cache" -RetensionHours $retentionHours
$sasLink = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Container "baerum-assets"
Write-Host "Sas link object: $sasLink"
Write-Host "Sas link: $($sasLink.sasLink)"
Write-Host "------------------------------"

