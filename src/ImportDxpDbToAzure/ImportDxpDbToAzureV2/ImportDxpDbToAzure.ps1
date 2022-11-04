[CmdletBinding()]
Param(
    $BacpacFilePath,
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
    $bacpacFilePath = $BacpacFilePath
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
    Write-Host "BacpacFilePath:             $bacpacFilePath"
    Write-Host "SubscriptionId:             $subscriptionId"
    Write-Host "ResourceGroupName:          $resourceGroupName"
    Write-Host "StorageAccountName:         $storageAccountName"
    Write-Host "StorageAccountContainer:    $storageAccountContainer"
    Write-Host "SqlServerName:              $sqlServerName"
    Write-Host "SqlDatabaseName:            $sqlDatabaseName"
    Write-Host "SqlDatabaseLogin:           $sqlDatabaseLogin"
    Write-Host "SqlDatabasePassword:        **** (it is a secret...)"
    Write-Host "SqlSku:                     $sqlSku"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"


    $bacpacFilePath = $bacpacFilePath.Trim()
    if ($bacpacFilePath.Contains("\")){
        $BlobName = $bacpacFilePath.Substring($bacpacFilePath.LastIndexOf("\") + 1)
    } else {
        $BlobName = $bacpacFilePath.Substring($bacpacFilePath.LastIndexOf("/") + 1)
    }

    Write-Host "------------------------------------------------"
    Write-Host "Downloaded database: $bacpacFilePath"
    Write-Host "BlobName: $BlobName"
    Write-Host "------------------------------------------------"

    Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    Get-InstalledModule -Name EpinovaAzureToolBucket

    Write-Host "------------------------------------------------"
    Write-Host "Start upload bacpac to Azure."
    Write-Host "`$BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $filePath -BlobName $BlobName"
    $BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $filePath -BlobName $BlobName #-Debug
    ###########################################################################################################
    

    Write-Host "BacpacFilename: $BacpacFilename"
   
    if ($null -eq $BacpacFilename -or $BacpacFilename.Length -eq 0){
        Write-Host "We do not have any database uploaded. Will exit."
        exit
    }

    Write-Host "Import-BacpacDatabase -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -BacpacFilename $BlobName -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku"
    Import-BacpacDatabase -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -BacpacFilename $BlobName -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku
    
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
