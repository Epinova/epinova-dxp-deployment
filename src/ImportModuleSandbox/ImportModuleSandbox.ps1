Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    # $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    # $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    # $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    # $environment = Get-VstsInput -Name "Environment" -Require -ErrorAction "Stop"
    # $databaseName = Get-VstsInput -Name "DatabaseName" -Require -ErrorAction "Stop"
    # $retentionHours = Get-VstsInput -Name "RetentionHours" -AsInt -Require -ErrorAction "Stop"
    # $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    # 30 min timeout
    ####################################################################################
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Write-Host "Inputs:"
    # Write-Host "ClientKey:          $clientKey"
    # Write-Host "ClientSecret:       **** (it is a secret...)"
    # Write-Host "ProjectId:          $projectId"
    # Write-Host "Environment:        $environment"
    # Write-Host "DatabaseName:       $databaseName"
    # Write-Host "RetentionHours:     $retentionHours"
    # Write-Host "Timeout:            $timeout"

    #. "$PSScriptRoot\EpinovaDxpDeploymentUtil.ps1"

    # TEMP code
    #Write-Host "Installing Azure.Storage Powershell Module"
    #Install-Module -Name Azure.Storage -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    #Install-Module -Name Az.Storage -Scope CurrentUser -Repository PSGallery -Force -AllowClobber

    
    #if (-not ($env:PSModulePath.Contains("$PSScriptRoot\ps_modules"))){
    #    $env:PSModulePath = "$PSScriptRoot\ps_modules;" + $env:PSModulePath   
    #}


    Write-Host $PSVersionTable.PSVersion

    Write-Host "Start test ...v1.12.14"

    Get-Module -ListAvailable
    #Script     2.1.0      Azure.Storage

    $azureModuleLoaded = Get-Module -Name "Azure.Storage"
    if ($azureModuleLoaded -eq $null) { Write-Host "$azureModuleLoaded=null" }
    else {
        $azureModuleLoaded
        Write-Host $azureModuleLoaded.Version
        Write-Host $azureModuleLoaded.Version.Major
    }
    $azModuleLoaded = Get-Module -Name "Az.Storage"
    if ($azModuleLoaded -eq $null) { Write-Host "$azModuleLoaded=null" }
    else {
        $azModuleLoaded
        Write-Host $azModuleLoaded.Version
        Write-Host $azModuleLoaded.Version.Major
    }

    if (-not ($azureModuleLoaded -or $azModuleLoaded)) {
        try {
            $null = Import-Module -Name "Az.Storage" -Scope CurrentUser -Repository PSGallery -MinimumVersion 3.5.0 -ErrorAction Stop
            #$null = Import-Module -Name "Az.Storage" -ErrorAction Stop
            $azModuleLoaded = $true
            Write-Host "Az.Storage is imported."
        }
        catch {
            Write-Host "Tried to find 'Az.Storage', module couldn't be imported."
        }
    }

    #$result1 = Get-InstalledModule -Name "Azure.Storage"
    #Write-Host $result1.Version
    #$result2 = Get-InstalledModule -Name "Az.Storage"
    #Write-Host $result2.Version

    if (-not ($azureModuleLoaded -or $azModuleLoaded)) {
        try {
            #Import-Module -Name "Azure.Storage" -ErrorAction Stop
            #$null = Import-Module -Name "Azure.Storage" -MinimumVersion 4.4.0 -ErrorAction Stop
            $null = Import-Module -Name "Azure.Storage" -MinimumVersion 4.4.0 -Scope CurrentUser -Repository PSGallery -ErrorAction Stop
            $azureModuleLoaded = $true
            Write-Host "Azure.Storage is imported."
        }
        catch {
            Write-Host "Tried to find 'Azure.Storage', module couldn't be imported."
        }
    }

    if ($azModuleLoaded) {
        Write-Host "Az"
    }
    elseif ($azureModuleLoaded) {
        $azureModuleLoaded = Get-Module -Name "Azure.Storage"
        if ($azureModuleLoaded.Version.Major -lt 4 -or ($azureModuleLoaded.Version.Major -eq 4 -and $azureModuleLoaded.Version.Minor -lt 4)) {
            # Previous versions of Azure.Storage do not support SAS links with write-only permission.
            throw "'Azure.Storage' version 4.4.0 or greater is required."
        }
        Write-Host "Azure"
    }
    else {
        throw "'Az.Storage' or 'Azure.Storage' module is required to run this cmdlet."
    }

    Write-Host "End test ..."

    #Initialize-EpiCload

    # Write-DxpHostVersion

    # Test-DxpProjectId -ProjectId $projectId

    # Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    # $exportDatabaseSplat = @{
    #     ProjectId          = $projectId
    #     Environment = $environment
    #     DatabaseName          = $databaseName
    #     RetentionHours = $retentionHours
    # }

    # $export = Start-EpiDatabaseExport @exportDatabaseSplat
    # Write-Host "Database export has started:"
    # Write-Host "Id:             $($export.id)"
    # Write-Host "ProjectId:      $($export.projectId)"
    # Write-Host "DatabaseName:   $($export.databaseName)"
    # Write-Host "Environment:    $($export.environment)"
    # Write-Host "Status:         $($export.status)"

    # $exportId = $export.id

    # if ($export.status -eq "InProgress") {
    #     $deployDateTime = Get-DxpDateTimeStamp
    #     Write-Host "Export $exportId started $deployDateTime."

    #     $status = Invoke-DxpExportProgress -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseName -ExpectedStatus "Succeeded" -Timeout $timeout

    #     $deployDateTime = Get-DxpDateTimeStamp
    #     Write-Host "Export $exportId ended $deployDateTime"

    #     if ($status.status -eq "Succeeded") {
    #         Write-Host "Database export $exportId has been successful."
    #     }
    #     else {
    #         Write-Warning "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
    #         Write-Host "##vso[task.logissue type=error]The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)"
    #         Write-Error "The database export has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
    #         exit 1
    #     }
    # }
    # else {
    #     Write-Warning "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
    #     Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
    #     Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment." -ErrorAction Stop
    #     exit 1
    # }
    # Write-Host "Setvariable ExportId: $exportId"
    # Write-Host "##vso[task.setvariable variable=ExportId;]$($exportId)"
    # Write-Host "Setvariable DbExportDownloadLink: $($status.downloadLink)"
    # Write-Host "##vso[task.setvariable variable=DbExportDownloadLink;]$($status.downloadLink)"
    ####################################################################################
    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}

