[CmdletBinding()]
Param(
    $DbExportDownloadLink,
    $SubscriptionId,
    $ResourceGroupName,
    $StorageAccountName,
    $StorageAccountContainer,
    $SqlServerName,
    $SqlDatabaseName,
    $RunDatabaseBackup,
    $SqlDatabaseLogin,
    $SqlDatabasePassword,
    $SqlSku,

    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $dbExportDownloadLink = $DbExportDownloadLink
    $subscriptionId = $SubscriptionId
    $resourceGroupName = $ResourceGroupName
    $storageAccountName = $StorageAccountName
    $storageAccountContainer = $StorageAccountContainer
    $sqlServerName = $SqlServerName
    $sqlDatabaseName = $SqlDatabaseName
    $sqlDatabaseLogin = $SqlDatabaseLogin
    $sqlDatabasePassword = $SqlDatabasePassword
    $sqlSku = $SqlSku
    [Boolean]$runDatabaseBackup = [System.Convert]::ToBoolean($RunDatabaseBackup)
    $timeout = $Timeout
    $zeroDowntimeMode = $ZeroDowntimeMode
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

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
    Write-Host "RunVerbose:                 $runVerbose"


    Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    Get-InstalledModule -Name EpinovaAzureToolBucket

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    $sasInfo = Get-SasInfo -SasLink $dbExportDownloadLink

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

    # Write-Host "------------------------------------------------"
    # Write-Host "Start upload bacpac to Azure."
    # Write-Host "`$BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $bacpacFilePath -BlobName $BlobName"
    # $BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $bacpacFilePath -BlobName $BlobName #-Debug
    # ###########################################################################################################

    # Copy-BlobsWithSas -SourceSasLink $dbExportDownloadLink -DestinationSubscriptionId $SubscriptionId -DestinationResourceGroupName $ResourceGroupName -DestinationStorageAccountName $StorageAccountName -DestinationContainerName $StorageAccountContainer -CleanBeforeCopy $false

    # . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"
    # $sasInfo = Get-SasInfo -SasLink $dbExportDownloadLink

    # $BacpacFilename = $sasInfo.Blob

    # Write-Host "BacpacFilename: $BacpacFilename"
   
    # if ($null -eq $BacpacFilename -or $BacpacFilename.Length -eq 0){
    #     Write-Host "We do not have any database uploaded. Will exit."
    #     exit
    # }

    # Write-Host "Import-BacpacDatabase -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku"
    # Import-BacpacDatabase -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku
    
    ####################################################################################

    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}

if ($runVerbose){
    ## To Set Verbose output
    $PSDefaultParameterValues['*:Verbose'] = $false
}
