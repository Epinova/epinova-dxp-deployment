<#


.DESCRIPTION
    Help functions for Epinova DXP deployment extension.
#>

Set-StrictMode -Version Latest

function Initialize-EpiCload{
    <#
    .SYNOPSIS
        Install the EpiCloud module and print version.

    .DESCRIPTION
        Install the EpiCloud module and print version.

    .EXAMPLE
        Initialize-EpiCload
    #>
    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Write-Host "Could not find EpiCloud."
        #Install-Module EpiCloud  -Scope CurrentUser -MinimumVersion 0.13.15 -Force -AllowClobber
        #Write-Host "Installed EpiCloud."
        Import-Module -Name "EpiCloud" -Verbose
        #Import-Module -Name "$PSScriptRoot/EpiCloud/EpiCloud.psd1" -Verbose -ErrorAction Stop
        Write-Host "Import EpiCloud."
    }
    #Get-Module -Name EpiCloud -ListAvailable
    $version = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
    Write-Host "EpiCloud            [$version]" 
    if ($null -eq $version -or "" -eq $version) {
        Write-Error "Could not get version for the installed module EpiCloud"
    }
}

function Write-DxpHostVersion() {
    <#
    .SYNOPSIS
        Write the PowerShell host version in the host.

    .DESCRIPTION
        Write the PowerShell host version in the host.

    .EXAMPLE
        Write-DxpHostVersion

        Will print out the PowerShell host version in the host. Ex: @{Version=5.1.14393.3866}
    #>
    #$version = Get-Host | Select-Object Version
    #Write-Host "PowerShell          $version" 
    $PSVersionTable
}

function Test-IsGuid {
        <#
    .SYNOPSIS
        Test a GUID.

    .DESCRIPTION
        Test a specified GUID and return true/false if it is valid GUID.

    .PARAMETER ObjectGuid
        The GUID that you want to test.

    .EXAMPLE
        Test-IsGuid -ObjectGuid $projectId

        Test if the value in the parameter $projectId is a valid GUID or not.
    #>
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ObjectGuid
	)
	
	# Define verification regex
	[regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

	# Check guid against regex
	return $ObjectGuid -match $guidRegex
}

function Test-DxpProjectId
{
    <#
    .SYNOPSIS
        Test a DXP project id.

    .DESCRIPTION
        Test a specified project Id if it is a valid GUID and return true/false.

    .PARAMETER ProjectId
        The provided ProjectId that you want to test.

    .EXAMPLE
        Test-DxpProjectId -ProjectId $projectId

        Test if the value in the parameter $projectId is a valid DXP project id.
    #>
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ProjectId
	)
	
    if ($true -ne (Test-IsGuid -ObjectGuid $ProjectId)){
        Write-Error "The provided ProjectId $ProjectId is not a guid value."
        exit 1
    }
}

function Get-DxpDateTimeStamp{
    <#
    .SYNOPSIS
        Create DateTime stamp in correct format.

    .DESCRIPTION
        Create DateTime stamp in yyyy-MM-ddTHH:mm:ss format.

    .EXAMPLE
        Get-DxpDateTimeStamp

        You will get the DateTime now in the format ex: '2021-02-20T14:34:22'.
    #>
    $dateTimeNow = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    return $dateTimeNow
}

function Invoke-DxpProgress {
    <#
    .SYNOPSIS
        Write the progress of a operation in the Episerver DXP environment to the host.

    .DESCRIPTION
        Write the progress of a operation in the Episerver DXP environment to the host.

    .PARAMETER ProjectId
        Project id for the project in Episerver DXP.

    .PARAMETER DeploymentId
        Deployment id for the specific deployment in Episerver DXP that you want to show the progress for.

    .PARAMETER PercentComplete
        The initialized percentComplete value that we got from the invoke of the operation.

    .PARAMETER ExpectedStatus
        The expectedStatus that the deployment should get when done/before timeout.

    .PARAMETER Timeout
        The maximum time that the progress should run. When the script has timeout if will stop.

    .EXAMPLE
        $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

    .EXAMPLE
        $status = Invoke-DxpProgress -Projectid '644b6926-39b1-42a1-93d6-3771cdc4a04e' -DeploymentId '817b5df3-21cd-4080-adbd-6c211b71f34d' -PercentComplete 0 -ExpectedStatus 'Success' -Timeout 1800

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DeploymentId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int] $PercentComplete,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExpectedStatus,

        [Parameter(Mandatory = $true)]
        [int] $Timeout
    )

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    $failedApiCalls = 0
    while ($PercentComplete -le 100) {
        try {
            $status = Get-EpiDeployment -ProjectId $ProjectId -Id $DeploymentId
            if ($PercentComplete -ne $status.percentComplete) {
                $PercentComplete = $status.percentComplete
                Write-Host $PercentComplete "%. Status: $($status.status). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
            }
            if ($PercentComplete -le 100 -or $status.status -ne $ExpectedStatus) {
                Start-Sleep 5
            }
            if ($sw.Elapsed.TotalSeconds -ge $Timeout) { break }
            if ($status.status -eq "Failed") { break }
            if ($status.percentComplete -eq 100 -and $status.status -eq $ExpectedStatus) { break }
    
        } catch {
            Write-Host "WARNING: Something in the progress failed. Exception caught : $($_.Exception.ToString())"
            $failedApiCalls = $failedApiCalls + 1;
            if ($failedApiCalls -gt 4){
                Write-Error "There are more then 4 failed calls to DXP API. We will stop the progress."
                break
            }
        }
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDeployment -ProjectId $ProjectId -Id $DeploymentId
    Write-Host "Deployment          $DeploymentId"
    Write-Host "Status:             $($status.status)."
    Write-Host "PercentComplete:    $($status.percentComplete)."
    Write-Host "StartTime:          $($status.startTime)."
    Write-Host "EndTime:            $($status.endTime)."

    if ($null -ne $status.deploymentErrors -and $status.deploymentErrors.Length -ne 0){
        Write-Host "Errors:         $($status.deploymentErrors)"
    }
    if ($null -ne $status.deploymentWarnings -and $status.deploymentWarnings.Length -ne 0){
        Write-Host "Warnings:       $($status.deploymentWarnings)"
    }

    return $status
}

function Connect-DxpEpiCloud{
    <#
    .SYNOPSIS
        Adds credentials (ClientKey and ClientSecret) for all functions
        in EpiCloud module to be used during the session/context.

    .DESCRIPTION
        Connect to the EpiCloud.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .EXAMPLE
        Connect-DxpEpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId

    .EXAMPLE
        Connect-DxpEpiCloud -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e' -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [String] $ProjectId
    )
    Connect-EpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId
}

function Get-DxpEnvironmentDeployments{
    <#
    .SYNOPSIS
        Get the latest deployments for the specified environment.

    .DESCRIPTION
        Get the latest deployments for the specified environment.

    .PARAMETER ProjectId
        Project id for the project in Episerver DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployments = Get-DxpEnvironmentDeployments -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployments = Get-DxpEnvironmentDeployments -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $getEpiDeploymentSplat = @{
        ProjectId    = $ProjectId
    }

    $deployments = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.parameters.targetEnvironment -eq $TargetEnvironment }

    return $deployments
}

function Get-DxpLatestEnvironmentDeployment{
    <#
    .SYNOPSIS
        Get the latest deployment for the specified environment.

    .DESCRIPTION
        Get the latest deployment for the specified environment.

    .PARAMETER ProjectId
        Project id for the project in Episerver DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployment = Get-DxpLatestEnvironmentDeployment -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployment = Get-DxpLatestEnvironmentDeployment -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $deployments = Get-DxpEnvironmentDeployments -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    $deployment = $null
    if ($deployments -is [array]){
        if ($deployments.Count -gt 1){
        
            $deployment = $deployments[0]
        } else {
            $deployment = $deployments
        }
    }
     else {
        if ($null -ne $deployments){
            $deployment = $deployments
        }
    }

    return $deployment
}

function Get-DxpAwaitingEnvironmentDeployment{
    <#
    .SYNOPSIS
        Get the latest deployment in status 'AwaitingVerification' for the specified environment.

    .DESCRIPTION
        Get the latest deployment in status 'AwaitingVerification' for the specified environment.

    .PARAMETER ProjectId
        Project id for the project in Episerver DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployment = Get-DxpAwaitingEnvironmentDeployment -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployment = Get-DxpAwaitingEnvironmentDeployment -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $getEpiDeploymentSplat = @{
        ProjectId    = $ProjectId
    }

    $deployment = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $TargetEnvironment }

    return $deployment
}

function Invoke-DxpExportProgress {
    <#
    .SYNOPSIS
        Start a export of a database from DXP.

    .DESCRIPTION
        Start a export of a database from DXP.

    .PARAMETER ProjectId
        Project id for the project in Episerver DXP.

    .PARAMETER ExportId
        .

    .PARAMETER Environment
        The environment that the database should be exported from.

    .PARAMETER DatabaseName
        The name of the database that should be downloaded. cms or commerce.

    .PARAMETER ExpectedStatus
        The status that we expect when the export is done. 'Succeeded'

    .PARAMETER Timeout
        The timeout. How long time the script will wait for the export to be finished.

    .EXAMPLE
        $status = ExportProgress -Projectid $projectId -ExportId $exportId -Environment $environment -DatabaseName $databaseName -ExpectedStatus "Succeeded" -Timeout $timeout


    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExportId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ExpectedStatus,

        [Parameter(Mandatory = $true)]
        [int] $Timeout
    )
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    $currentStatus = ""
    $iterator = 0
    while ($currentStatus -ne $ExpectedStatus) {
        $status = Get-EpiDatabaseExport -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
        $currentStatus = $status.status
        if ($iterator % 6 -eq 0) {
            Write-Host "Status: $($currentStatus). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($currentStatus -ne $ExpectedStatus) {
            Start-Sleep 10
        }
        if ($sw.Elapsed.TotalSeconds -ge $Timeout) { break }
        if ($currentStatus -eq $ExpectedStatus) { break }
        $iterator++
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDatabaseExport -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
    Write-Host $status
    return $status
}

function Install-AzureStorage {
    <#
    .SYNOPSIS
        Install correct version of Azure.Storage.

    .DESCRIPTION
        Install correct version of Azure.Storage.

    .EXAMPLE
        Install-AzureStorage
    #>
    # Write-Host "SuppressAzureRmModulesRetiringWarning"
    # Set-Item -Path Env:\SuppressAzureRmModulesRetiringWarning -Value $true

    if ($null -eq (Get-Module -Name "Az.Storage")) {
        Install-Module -Name Az.Storage -Scope CurrentUser -Repository PSGallery -MinimumVersion 3.7.0 -Force -AllowClobber
    }

    # if ($null -eq (Get-Module -Name "Azure.Storage")) {
    #     Write-Host "Installing Azure.Storage Powershell Module -MinimumVersion 4.4.0"
    #     Install-Module -Name Azure.Storage -Scope CurrentUser -Repository PSGallery -MinimumVersion 4.4.0 -Force -AllowClobber
    # }
}

function Mount-PsModulesPath {
    <#
    .SYNOPSIS
        Add task ps_modules folder to env:PSModulePath.

    .DESCRIPTION
        Add task ps_modules folder to env:PSModulePath.

    .EXAMPLE
        Mount-ModulePath
    #>
    if ($true -eq $IsWindows){
        if (-not ($env:PSModulePath.Contains("$PSScriptRoot\ps_modules"))){
            $taskModulePath = "$PSScriptRoot\ps_modules"
        }
    }
    else {
        #Linux/MacOS
        if (-not ($env:PSModulePath.Contains("$PSScriptRoot/ps_modules"))){
            $taskModulePath = "$PSScriptRoot/ps_modules"
        }

    }
    $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$taskModulePath"
    Write-Host "Added $taskModulePath to env:PSModulePath" 
}

function Mount-EpinovaDxpDeploymentUtil {
    <#
    .SYNOPSIS
        Load EpinovaDxpDeploymentUtil.ps1.

    .DESCRIPTION
        Load EpinovaDxpDeploymentUtil.ps1.

    .EXAMPLE
        Mount-EpinovaDxpDeploymentUtil
    #>
    if ($true -eq $IsWindows){
        . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"
    }
    else {
        #Linux/MacOS
        . "$PSScriptRoot/ps_modules/EpinovaDxpDeploymentUtil.ps1"

    }
}