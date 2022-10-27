Set-StrictMode -Version Latest 
$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

. C:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1

# [string] $clientKey = "xxx"
# [string] $clientSecret = "xxx"
# [string] $projectId = "xxx"
[string] $DxpEnvironment = "Integration" #[ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
[string] $DxpDatabaseDownloadFolder = "C:\dev\temp\_blobDownloads"

Set-ExecutionPolicy -Scope CurrentUser Unrestricted

#Install-Module EpiCloud -Scope CurrentUser -MinimumVersion 1.2.0 -Force -AllowClobber
Get-Module -Name EpiCloud -ListAvailable
$ClientKey
$ClientSecret
$ProjectId
$DxpEnvironment
Import-Module EpiCloud
$containers = Get-EpiStorageContainer -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $DxpEnvironment

# Get a list of all containers for a environment so that we can download correct blobs.
#$containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $DxpEnvironment
Write-Host "Containers:-------------------"
$containers.storageContainers | Format-Table
Write-Host "------------------------------"

# $files = Invoke-DxpBlobsDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DownloadFolder $downloadFolder -MaxFilesToDownload 2 -Container "AppLogs"

# # Temp set the downloaded database.
# $filePath = "C:\dev\temp\_blobDownloads\epicms_Integration_20221027082506.bacpac"

# if ($null -eq $filePath -or $filePath.Length -eq 0){
#     Write-Host "We do not have any database to work with. Will exit."
#     exit
# }

# [string] $SubscriptionId = "e872f180-979f-xxx-aff7-3bbxxxx7f89" 
# [string] $ResourceGroupName = "rg-my-group"
# [string] $StorageAccountName = "my-storage"
# [string] $ContainerName = "db-backups"

# . C:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

# $BacpacFilename = Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $ContainerName -FilePath $filePath #-Debug

# #$BacpacFilename = "epicms_Integration_20221027082506.bacpac"
# $BacpacFilename

# $SqlServerName = "your-sql-server"
# $SqlDatabaseName = "your-sql-databasename"
# $SqlDatabaseLogin = "sa"
# $SqlDatabasePassword = "l#tm#inmyd@tabaseplease!"
# $RunDatabaseBackup = $true
# $SqlSku = "Basic"

# # Override with real settings
# . C:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_ImportBacpacDatabase.ps1

# Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku
