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

    Initialize-EpiCload

    $retentionHours = 2
    Connect-DxpEpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId

    $exportDatabaseSplat = @{
        ClientKey      = $clientKey
        ClientSecret   = $clientSecret
        ProjectId      = $projectId
        Environment    = $environment
        DatabaseName   = $databaseType
        RetentionHours = $retentionHours
    }

    $filePath = ""
    $export = Start-EpiDatabaseExport @exportDatabaseSplat
    Write-Host "Database export has started:--------------------"
    Write-Host "Id:           $($export.id)"
    Write-Host "ProjectId:    $($export.projectId)"
    Write-Host "DatabaseName: $($export.databaseName)"
    Write-Host "Environment:  $($export.environment)"
    Write-Host "Status:       $($export.status)"
    Write-Host "------------------------------------------------"

    $exportId = $export.id 

    if ($export.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Export $exportId started $deployDateTime."
    } else {
        Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        exit
    }

    if ($export.status -eq "InProgress" -or $status.status -eq "Succeeded") {
        Write-Host "----------------PROGRESS-------------------------"
        $status = Invoke-DxpDatabaseExportProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseType -ExpectedStatus "Succeeded" -Timeout $timeout
        Write-Host "------------------------------------------------"
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Export $exportId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Database export $exportId has been successful."
            Write-Host "-------------DOWNLOAD----------------------------"
            Write-Host "Start download database $($status.downloadLink)"
            #$filePath = Join-Parts -Separator '\' -Parts $dropPath, $status.bacpacName
            if ($dropPath.Contains("\")){
                $filePath = "$dropPath\$($status.bacpacName)"
            } else {
                $filePath = "$dropPath/$($status.bacpacName)"
            }
            Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath
            Write-Host "Downloaded database to $filePath"
            Write-Host "------------------------------------------------"
            $filePath;
        }
        else {
            Write-Error "The database export has not been successful or the script has timedout. CurrentStatus: $($status.status)"
            exit
        }
    }
    else {
        Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        exit
    }    

    # #Initialize-EpiCload

    # Write-DxpHostVersion

    # Test-DxpProjectId -ProjectId $projectId

    # Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    # #Sync-DxpDbToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DatabaseType $databaseType -DownloadFolder $dropPath -Timeout $timeout -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -SqlServerName $sqlServerName -SqlDatabaseName $sqlDatabaseName -SqlDatabaseLogin $sqlDatabaseLogin -SqlDatabasePassword $sqlDatabasePassword -RunDatabaseBackup $runDatabaseBackup -SqlSku $sqlSku
    # $retentionHours = 2
    # [string]$filePath = Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DatabaseName $databaseType -DownloadFolder $dropPath -RetentionHours $retentionHours -Timeout $timeout
    #Write-Host "Downloaded database: $filePath"

    if ($null -eq $filePath -or $filePath.Length -eq 0){
        Write-Host "We do not have any database to work with. Will exit."
        exit
    }

    $filePath = $filePath.Trim()
    if ($dropPath.Contains("\")){
        $BlobName = $filePath.Substring($filePath.LastIndexOf("\") + 1)
    } else {
        $BlobName = $filePath.Substring($filePath.LastIndexOf("/") + 1)
    }

    Write-Host "------------------------------------------------"
    Write-Host "Downloaded database: $filePath"
    Write-Host "BlobName: $BlobName"
    Write-Host "------------------------------------------------"

    # Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    # Get-InstalledModule -Name EpinovaAzureToolBucket

    # #Install-Module Az -Scope CurrentUser -Force
    # Install-Module Az.Accounts -Scope CurrentUser -Force
    # Install-Module Az.Storage -Scope CurrentUser -Force
    # Install-Module Az.Sql -Scope CurrentUser -Force
    # #Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.4.2 -Verbose
    # #Install-Module -Name "EpinovaDxpToolBucket" -Verbose

    Import-Module Az.Storage -Global -PassThru -Force
    Get-InstalledModule -Name Az.Storage

    Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    Get-InstalledModule -Name EpinovaAzureToolBucket


    Write-Host "------------------------------------------------"
    Write-Host "Start upload bacpac to Azure."
    Write-Host "`$BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $filePath -BlobName $BlobName"
    $BacpacFilename = Send-Blob -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -FilePath $filePath -BlobName $BlobName #-Debug

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
