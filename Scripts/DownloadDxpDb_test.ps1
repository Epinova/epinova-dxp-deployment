Set-StrictMode -Version Latest 

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

. E:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"

Set-ExecutionPolicy -Scope CurrentUser Unrestricted
Get-DxpProjectBlobs -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment "Integration" -DownloadFolder "F:\temp\forsea\dxp-inte-new" -MaxFilesToDownload 0 -Container "mysitemedia" -OverwriteExistingFiles 1 -RetentionHours 2
#$filePath = Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DatabaseName "epicms" -DownloadFolder "F:\temp\forsea\dxp-inte-new" -RetentionHours 2 -Timeout 1800
#$filePath