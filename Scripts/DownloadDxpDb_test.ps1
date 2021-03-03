Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"

Set-ExecutionPolicy -Scope CurrentUser Unrestricted
#Get-DxpProjectBlobs -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DatabaseName "epicms" -DownloadFolder "E:\dev\temp\_blobDownloads" -RetentionHours 2 -Timeout 1800