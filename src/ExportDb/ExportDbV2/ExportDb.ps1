[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DatabaseName,
    $RetentionHours,
    $Timeout
)
try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment
    $databaseName = $DatabaseName
    $retentionHours = $RetentionHours
    $timeout = $Timeout

    # 30 min timeout
    ####################################################################################
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "Environment:        $environment"
    Write-Host "DatabaseName:       $databaseName"
    Write-Host "RetentionHours:     $retentionHours"
    Write-Host "Timeout:            $timeout"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Mount-PsModulesPath

    Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $exportDatabaseSplat = @{
        ProjectId          = $projectId
        Environment = $environment
        DatabaseName          = $databaseName
        RetentionHours = $retentionHours
    }

    $export = Start-EpiDatabaseExport @exportDatabaseSplat
    Write-Host "Database export has started:"
    Write-Host "Id:             $($export.id)"
    Write-Host "ProjectId:      $($export.projectId)"
    Write-Host "DatabaseName:   $($export.databaseName)"
    Write-Host "Environment:    $($export.environment)"
    Write-Host "Status:         $($export.status)"

    $exportId = $export.id

    if ($export.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Export $exportId started $deployDateTime."

        $status = Invoke-DxpExportProgress -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseName -ExpectedStatus "Succeeded" -Timeout $timeout

        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Export $exportId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Database export $exportId has been successful."
        }
        else {
            Write-Warning "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable ExportId: $exportId"
    Write-Host "##vso[task.setvariable variable=ExportId;]$($exportId)"
    Write-Host "Setvariable DbExportDownloadLink: $($status.downloadLink)"
    Write-Host "##vso[task.setvariable variable=DbExportDownloadLink;]$($status.downloadLink)"
    ####################################################################################
    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
