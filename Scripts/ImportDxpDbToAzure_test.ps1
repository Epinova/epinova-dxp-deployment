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
# $ResourceGroupName = ""
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
Write-Host "-----------------------------------------------------------"




#Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
#Get-InstalledModule -Name EpinovaAzureToolBucket
# $sourceContainerName = "bacpacs"
 $blob = "epicms_Integration_20221214123122.bacpac"
# $sasToken = "?sv=2018-03-28&sr=b&sig=xxxVMFhQPGxl7ch7VHHwikryYysqStVfRUYqW4tg14EIJQ%3D&st=2022-12-14T12%3A34%3A25Z&se=2022-12-15T12%3A34%3A25Z&sp=r"


$databaseExist = $false
try {
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -ErrorAction SilentlyContinue
    if ($null -ne $databaseResult) {
        $databaseExist = $true
        Write-Host "Destination database $SqlDatabaseName exist."
    } else {
        Write-Host "Destination database $SqlDatabaseName does not exist."
    }
} catch {
    Write-Host "Destination database $SqlDatabaseName does not exist."
    $error.clear()
}


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
 
if ($true -eq $databaseExist -and $true -eq $RunDatabaseBackup) {
    Backup-Database -SubscriptionId $SubscriptionId `
        -ResourceGroupName $ResourceGroupName `
        -SqlServerName $SqlServerName `
        -SqlDatabaseName $SqlDatabaseName `
        -SqlDatabaseLogin $SqlDatabaseLogin `
        -SqlDatabasePassword $SqlDatabasePassword `
        -StorageAccountName $storageAccountName `
        -StorageAccountContainer $StorageAccountContainer

    Unpublish-Database -ResourceGroupName $ResourceGroupName `
        -SqlServerName $SqlServerName `
        -SqlDatabaseName $SqlDatabaseName
}

$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $ResourceGroupName `
     -ServerName $sqlServerName `
     -DatabaseName $sqlDatabaseName `
     -DatabaseMaxSizeBytes 10GB `
     -StorageKeyType "SharedAccessKey" `
     -StorageKey "?sv=2018-03-28&sr=b&sig=VMFhQPGxl7ch7VHHwikryYysqStVfRUYqW4tg14EIJQ%3D&st=2022-12-14T12%3A34%3A25Z&se=2022-12-15T12%3A34%3A25Z&sp=r" `
     -StorageUri "https://ehos01mstrn567v.blob.core.windows.net/bacpacs/epicms_Integration_20221214123122.bacpac" `
     -Edition "Standard" `
     -ServiceObjectiveName "S3" `
     -AdministratorLogin "$SqlDatabaseLogin" `
     -AdministratorLoginPassword $(ConvertTo-SecureString -String $sqlDatabasePassword -AsPlainText -Force)

    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write("Importing ${$blob}: ")
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
    Write-Host "Database '$SqlDatabaseName' is imported."

    # Check the SKU on destination database after copy. 
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $sqlServerName -DatabaseName $sqlDatabaseName
    $databaseResult
 
    # Scale down to S0 after import is complete
    Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -DatabaseName $sqlDatabaseName -ServerName $sqlServerName -RequestedServiceObjectiveName $sqlSku #-Edition "Standard"


# ####################################################################################

# Write-Host "---THE END---"