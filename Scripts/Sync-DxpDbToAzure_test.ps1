Set-StrictMode -Version Latest 
$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose
Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose
Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

. E:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1
[string] $DxpEnvironment = "Integration" #[ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
[string] $DxpDatabaseName = "epicms" #[ValidateSet('epicms','epicommerce')]
[string] $DxpDatabaseDownloadFolder = "E:\dev\temp\_blobDownloads"

[string] $SubscriptionId = "e872f180-979f-xxx-aff7-3bbxxxx7f89" 
[string] $ResourceGroupName = "rg-my-group"
[string] $StorageAccountName = "my-storage"
[string] $StorageAccountContainer = "db-backups"

. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_SendBlob.ps1

$SqlServerName = "your-sql-server"
$SqlDatabaseName = "your-sql-databasename"
$SqlDatabaseLogin = "sa"
$SqlDatabasePassword = "l#tm#inmyd@tabaseplease!"
$RunDatabaseBackup = $true
$SqlSku = "Basic"

# Override with real settings
. E:\dev\temp\PowerShellSettingFiles\EpinovaAzureToolBucket_ImportBacpacDatabase.ps1

Set-ExecutionPolicy -Scope CurrentUser Unrestricted

Sync-DxpDbToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DatabaseType $DxpDatabaseName -DownloadFolder $DxpDatabaseDownloadFolder -Timeout 1800 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku
