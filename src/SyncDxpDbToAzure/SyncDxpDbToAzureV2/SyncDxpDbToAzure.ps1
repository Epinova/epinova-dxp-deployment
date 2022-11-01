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

    $DropPath
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

    Install-Module EpinovaDxpToolBucket -Scope CurrentUser -Force

    Get-InstalledModule -Name EpinovaDxpToolBucket

    #Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.4.2 -Verbose
    #Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    Sync-DxpDbToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DatabaseType $databaseType -DownloadFolder $dropPath -Timeout $timeout -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku

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
