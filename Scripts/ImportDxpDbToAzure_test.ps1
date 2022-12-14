Set-StrictMode -Version Latest 
#$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
#Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose
Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose
Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose -Force
#Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose
Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose




# $dbExportDownloadLink = ""
# $SubscriptionId = ""
# $resourceGroupName = ""
# $StorageAccountName = ""
# $StorageAccountContainer = "db-backups"
# $sqlServerName = ""
# $sqlDatabaseName = "ImporttestFromDevOps"
# $sqlDatabaseLogin = ""
# $sqlDatabasePassword = ""
# $sqlSku = "Basic"
# $runDatabaseBackup = $false
# $timeout = 1800
# $destinationConnectionString = ""

Set-ExecutionPolicy -Scope CurrentUser Unrestricted

Write-Host "Inputs:"
Write-Host "DbExportDownloadLink:       $dbExportDownloadLink"
Write-Host "SubscriptionId:             $subscriptionId"
Write-Host "ResourceGroupName:          $resourceGroupName"
Write-Host "StorageAccountName:         $storageAccountName"
Write-Host "StorageAccountContainer:    $storageAccountContainer"
Write-Host "SqlServerName:              $sqlServerName"
Write-Host "SqlDatabaseName:            $sqlDatabaseName"
Write-Host "SqlDatabaseLogin:           $sqlDatabaseLogin"
Write-Host "SqlDatabasePassword:        **** (it is a secret...)"
Write-Host "SqlSku:                     $sqlSku"
Write-Host "RunDatabaseBackup:          $runDatabaseBackup"
Write-Host "Timeout:                    $timeout"
Write-Host "-----------------------------------------------------------"

#. "E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpDeploymentUtil.ps1"
. "C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpDeploymentUtil.ps1"

$sasInfo = Get-SasInfo -SasLink $dbExportDownloadLink

#Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
#Get-InstalledModule -Name EpinovaAzureToolBucket

Connect-AzAccount -SubscriptionId $subscriptionId
$context = Get-AzContext -ListAvailable | Where-Object { $_.Name.Contains($subscriptionId) }
$context
Select-AzContext -Name $context.Name | Out-Null
# Set-AzContext $context

$databaseExist = $false
try {
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $sqlDatabaseName -ErrorAction SilentlyContinue
    if ($null -ne $databaseResult) {
        $databaseExist = $true
        Write-Host "Destination database $sqlDatabaseName exist."
    } else {
        Write-Host "Destination database $sqlDatabaseName does not exist."
    }
} catch {
    Write-Host "Destination database $sqlDatabaseName does not exist."
    $error.clear()
}


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
 
if ($true -eq $databaseExist) {
    if ($true -eq $runDatabaseBackup) {
        Backup-Database -SubscriptionId $subscriptionId `
            -ResourceGroupName $resourceGroupName `
            -SqlServerName $sqlServerName `
            -SqlDatabaseName $sqlDatabaseName `
            -SqlDatabaseLogin $sqlDatabaseLogin `
            -SqlDatabasePassword $sqlDatabasePassword `
            -StorageAccountName $storageAccountName `
            -StorageAccountContainer $storageAccountContainer
    }

    Remove-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $sqlDatabaseName
    Write-Host "Removed existing database $sqlDatabaseName."
}


$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
     -ServerName $sqlServerName `
     -DatabaseName $sqlDatabaseName `
     -DatabaseMaxSizeBytes 10GB `
     -StorageKeyType "SharedAccessKey" `
     -StorageKey $sasInfo.SasToken `
     -StorageUri $sasInfo.PathLink `
     -Edition "Standard" `
     -ServiceObjectiveName "S3" `
     -AdministratorLogin "$sqlDatabaseLogin" `
     -AdministratorLoginPassword $(ConvertTo-SecureString -String $sqlDatabasePassword -AsPlainText -Force)

if ($null -ne $importRequest){
    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write("Importing $($sasInfo.Blob): ")
    $lastStatusMessage = ""
    while ($importStatus.Status -eq "InProgress")
    {
        Start-Sleep -s 10
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        if ($lastStatusMessage -ne $importStatus.StatusMessage) {
            $lastStatusMessage = $importStatus.StatusMessage
            $progress = $lastStatusMessage.Replace("Running, Progress = ", "")
            [Console]::Write($progress)
        }
        [Console]::Write(".")
    }
    [Console]::WriteLine("")
    $importStatus
    Write-Host "Database '$sqlDatabaseName' is imported."

    # Check the SKU on destination database after copy. 
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $sqlDatabaseName
    $databaseResult
 
    # Scale down to S0 after import is complete
    Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -DatabaseName $sqlDatabaseName -ServerName $sqlServerName -RequestedServiceObjectiveName $sqlSku #-Edition "Standard"

}


####################################################################################

Write-Host "---THE END---"