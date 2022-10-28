Set-StrictMode -Version Latest 
$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

. E:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"
[string] $DxpEnvironment = "Integration" #[ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
[string] $DxpDownloadFolder = "E:\dev\temp\_blobDownloads"

Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# Get a list of all containers for a environment so that we can download correct blobs.
# $containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $DxpEnvironment
# Write-Host "Containers:-------------------"
# $containers.storageContainers | Format-Table
# Write-Host "------------------------------"

$DxpContainer = "mysitemedia"

$files = Invoke-DxpBlobsDownload -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $DxpEnvironment -DownloadFolder $DxpDownloadFolder -MaxFilesToDownload 2 -Container $DxpContainer

$files

[string] $SubscriptionId = "e872f180-979f-xxx-aff7-3bbxxxx7f89" 
[string] $ResourceGroupName = "rg-my-group"
[string] $StorageAccountName = "my-storage"
[string] $StorageAccountContainer = "db-backups"

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

$StorageAccountContainer = "mysitemedia"

foreach ($file in $files) {
    $BlobName = $file.Replace($DxpDownloadFolder, "")
    if ($BlobName.StartsWith("\")){
        $BlobName = $BlobName.SubString(1, $BlobName.Length - 1)
    }
    #$BlobName

    $fileUploaded = Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $file -BlobName $BlobName #-Debug
    Write-Host "File is uploaded: $fileUploaded"
}
