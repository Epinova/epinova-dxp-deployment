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
[string] $DxpDatabaseName = "epicms" #[ValidateSet('epicms','epicommerce')]
[string] $DxpDatabaseDownloadFolder = "E:\dev\temp\_blobDownloads"

Set-ExecutionPolicy -Scope CurrentUser Unrestricted
#$filePath = Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DatabaseName $DxpDatabaseName -DownloadFolder $DxpDatabaseDownloadFolder -RetentionHours 2 -Timeout 1800
#Write-Host "Downloaded database: $filePath"

# Temp set the downloaded database.
$filePath = "E:\dev\temp\_blobDownloads\epicms_Integration_20210303134513.bacpac"

if ($null -eq $filePath -or $filePath.Length -eq 0){
    Write-Host "We do not have any database to work with. Will exit."
    exit
}

[string] $SubscriptionId = "e872f180-979f-xxx-aff7-3bbxxxx7f89" 
[string] $ResourceGroupName = "rg-my-group"
[string] $StorageAccountName = "my-storage"
[string] $StorageAccountContainer = "db-backups"

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

#Install-Module Az.Storage -RequiredVersion 9.0.1
$BlobName = $filePath.Substring($filePath.LastIndexOf("\") + 1)
$BlobName

$BacpacFilename = Send-Blob -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -FilePath $filePath -BlobName $BlobName #-Debug

#$BacpacFilename = "epicms_Integration_20210303134513.bacpac"
$BacpacFilename

$SqlServerName = "your-sql-server"
$SqlDatabaseName = "your-sql-databasename"
$SqlDatabaseLogin = "sa"
$SqlDatabasePassword = "l#tm#inmyd@tabaseplease!"
$RunDatabaseBackup = $true
$SqlSku = "Basic"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_ImportBacpacDatabase.ps1

Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BlobName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku
#Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku
