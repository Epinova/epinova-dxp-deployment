Set-StrictMode -Version Latest 
#$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose
Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose
Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose -Force
#Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose
Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

$dbExportDownloadLink = ""
$SubscriptionId = ""
$ResourceGroupName = ""
$StorageAccountName = ""
$StorageAccountContainer = "db-backups"
$sqlServerName = ""
$sqlDatabaseName = "ImporttestFromDevOps"
$sqlDatabaseLogin = ""
$sqlDatabasePassword = ""
$sqlSku = "Basic"
$runDatabaseBackup = $false
$timeout = 1800


Set-ExecutionPolicy -Scope CurrentUser Unrestricted

Write-Host "Inputs:"
Write-Host "DbExportDownloadLink:       $dbExportDownloadLink"
Write-Host "SubscriptionId:             $SubscriptionId"
Write-Host "ResourceGroupName:          $ResourceGroupName"
Write-Host "StorageAccountName:         $StorageAccountName"
Write-Host "StorageAccountContainer:    $StorageAccountContainer"
Write-Host "SqlServerName:              $sqlServerName"
Write-Host "SqlDatabaseName:            $sqlDatabaseName"
Write-Host "SqlDatabaseLogin:           $sqlDatabaseLogin"
Write-Host "SqlDatabasePassword:        **** (it is a secret...)"
Write-Host "SqlSku:                     $sqlSku"
Write-Host "RunDatabaseBackup:          $runDatabaseBackup"

Write-Host "Timeout:                    $timeout"




#Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
#Get-InstalledModule -Name EpinovaAzureToolBucket
$sourceContainerName = "bacpacs"
$blob = "epicms_Integration_20221213192244.bacpac"

$sourceContext = New-AzStorageContext -StorageAccountName "ehos01mstrn567v" -SASToken "?sv=2018-03-28&sr=b&sig=c1NqrGbQwInEYoWIGQEcgkBDJLk2RhwFIlyhcoSBAdY%3D&st=2022-12-13T19%3A25%3A48Z&se=2022-12-14T19%3A25%3A48Z&sp=r" -ErrorAction Stop
    if ($null -eq $sourceContext) {
        Write-Error "Could not create a context against source storage account ehos01mstrn567v"
        exit
    }
#Write-Host $sourceContext.ConnectionString
$sourceBlob = Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext -Blob $blob
if ($null -ne $sourceBlob){
    Write-Host "Found source blob $($sourceBlob.Name)"
} else {
    Write-Host "Found no source blob"
    exit
}
#Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext -Blob $blob

#$destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$destinationContext = New-AzStorageContext -ConnectionString "DefaultEndpointsProtocol=https;AccountName=bwoffshoreintra;AccountKey=N91hwoEL74xDlMrLcVdq/gs0AG3tr7+hZtH3BWfVYXk6dFokjfHXKNUb47vgAM7nWeeIQZWADNKyobgiA1MuQg=="
# if ($null -eq $destinationStorageAccount) {
#     Write-Error "Could not create a context against destination storage account $StorageAccountName"
#     exit
# }
# $destinationContext = $destinationStorageAccount.Context 


$existingBlob = Get-AzStorageBlob -Container $StorageAccountContainer -Context $destinationContext -Blob $blob -ErrorAction Ignore
if ($null -ne $existingBlob){
    Write-Host "Delete blob $($existingBlob.Name)"
    (Get-AzStorageBlob -Container $StorageAccountContainer -Context $destinationContext -Blob $blob) | Remove-AzStorageBlob
} else {
    Write-Host "Found no existing blob $blob"
}


Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext -Blob $blob | Start-AzStorageBlobCopy -DestContainer $StorageAccountContainer -Context $destinationContext -Force
Write-Host "Sleep for 10 sec to see that the blob is created."
Start-Sleep -s 10
$blobInfo = Get-AzStorageBlob -Container $StorageAccountContainer -Context $destinationContext -Blob $blob
if ($null -ne $blobInfo) {
     Write-Host "Blob size: $($blobInfo.Length)"
#     [Console]::Write("Copying.")
#     while ($blobInfo.Length -eq 0) {
#         Start-Sleep -s 10
#         $blobInfo = Get-AzStorageBlob -Container $StorageAccountContainer -Context $destinationContext -Blob $blob
#         [Console]::Write(".")
#     }
#     [Console]::WriteLine("")
}





#Copy-BlobsWithSas -SourceSasLink $dbExportDownloadLink -DestinationSubscriptionId $SubscriptionId -DestinationResourceGroupName $ResourceGroupName -DestinationStorageAccountName $StorageAccountName -DestinationContainerName $StorageAccountContainer -CleanBeforeCopy $false

# . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"
# $sasInfo = Get-SasInfo -SasLink $dbExportDownloadLink

# $BacpacFilename = $sasInfo.Blob

# Write-Host "BacpacFilename: $BacpacFilename"

# if ($null -eq $BacpacFilename -or $BacpacFilename.Length -eq 0){
#     Write-Host "We do not have any database uploaded. Will exit."
#     exit
# }

# Write-Host "Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku"
# Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku

# ####################################################################################

# Write-Host "---THE END---"