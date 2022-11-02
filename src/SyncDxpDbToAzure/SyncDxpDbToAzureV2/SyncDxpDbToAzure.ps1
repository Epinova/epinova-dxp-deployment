[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DatabaseType,
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

    $DropPath,
    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment

    $databaseType = $DatabaseType
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
    $dropPath = $DropPath
    $timeout = $Timeout
    $zeroDowntimeMode = $ZeroDowntimeMode

    [Boolean]$runDatabaseBackup = [System.Convert]::ToBoolean($RunDatabaseBackup)

    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Inputs:"
    Write-Host "ClientKey:                  $clientKey"
    Write-Host "ClientSecret:               **** (it is a secret...)"
    Write-Host "ProjectId:                  $projectId"
    Write-Host "Environment:                $environment"
    Write-Host "DatabaseType:               $databaseType"
    Write-Host "SubscriptionId:             $subscriptionId"
    Write-Host "ResourceGroupName:          $resourceGroupName"
    Write-Host "StorageAccountName:         $storageAccountName"
    Write-Host "StorageAccountContainer:    $storageAccountContainer"
    Write-Host "SqlServerName:              $sqlServerName"
    Write-Host "SqlDatabaseName:            $sqlDatabaseName"
    Write-Host "SqlDatabaseLogin:           $sqlDatabaseLogin"
    Write-Host "SqlDatabasePassword:        **** (it is a secret...)"
    Write-Host "SqlSku:                     $sqlSku"

    Write-Host "DropPath:                   $dropPath"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Mount-PsModulesPath

    #Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    Get-InstalledModule -Name EpinovaAzureToolBucket

    Install-Module Az.Accounts -Scope CurrentUser -Force
    Install-Module Az.Storage -Scope CurrentUser -Force
    Install-Module Az.Sql -Scope CurrentUser -Force
    #Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.4.2 -Verbose
    #Install-Module -Name "EpinovaDxpToolBucket" -Verbose
    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    #Sync-DxpDbToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DatabaseType $databaseType -DownloadFolder $dropPath -Timeout $timeout -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku
    $retentionHours = 2
    [string]$filePath = Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DatabaseName $databaseType -DownloadFolder $dropPath -RetentionHours $retentionHours -Timeout $timeout
    Write-Host "Downloaded database: $filePath"

    if ($null -eq $filePath -or $filePath.Length -eq 0){
        Write-Host "We do not have any database to work with. Will exit."
        exit
    }
    
    $filePath = $filePath.Trim()
    $BlobName = $filePath.Substring($filePath.LastIndexOf("\") + 1)
    $BlobName
    
    $BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $filePath -BlobName $BlobName #-Debug
    $BacpacFilename
   
    if ($null -eq $BacpacFilename -or $BacpacFilename.Length -eq 0){
        Write-Host "We do not have any database uploaded. Will exit."
        exit
    }

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
