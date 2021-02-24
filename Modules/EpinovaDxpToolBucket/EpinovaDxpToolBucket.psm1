<#


.DESCRIPTION
    Help functions for Epinova DXP vs Azure Portal.
#>

Set-StrictMode -Version Latest

# PRIVATE METHODS
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

function Add-TlsSecurityProtocolSupport {
    <#
    .SYNOPSIS
    This helper function adds support for TLS protocol 1.1 and/or TLS 1.2

    .DESCRIPTION
    This helper function adds support for TLS protocol 1.1 and/or TLS 1.2

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [Bool] $EnableTls11 = $true,
        [Parameter(Mandatory=$false)]
        [Bool] $EnableTls12 = $true
    )

    # Add support for TLS 1.1 and TLS 1.2
    if (-not [Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls11) -AND $EnableTls11) {
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls11
    }

    if (-not [Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12) -AND $EnableTls12) {
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }
}

function Test-DownloadFolder {
    <#
    .SYNOPSIS
        Test the downloadfolder if it exist.

    .DESCRIPTION
        Test the downloadfolder if it exist.

    .PARAMETER DownloadFolder
        The provided folder where the blobs will be downloaded.

    .EXAMPLE
        Test-DownloadFolder -DownloadFolder $DownloadFolder

    #>
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$DownloadFolder
	)
    if ((Test-Path $DownloadFolder -PathType Container) -eq $false) {
        Write-Error "Download folder $DownloadFolder does not exist."
        exit
    }
}

function Test-EnvironmentParam{
<#
    .SYNOPSIS
        ...

    .DESCRIPTION
        ...

    .PARAMETER Environment
        ...

    .EXAMPLE
        Test-EnvironmentParam -Environment $Environment

    #>
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$Environment
	)    
    
    if ($Environment -eq "Integration" -or $Environment -eq "Preproduction" -or $Environment -eq "Production") {
        Write-Host "Environment param ok."
    }
    else {
        Write-Error "The environment $Environment that you have specified does not exist. Ok environments: Integration | Preproduction | Production"
        exit
    }
}

# END PRIVATE METHODS

function Test-DxpProjectId {
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
	
    if ((Test-IsGuid -ObjectGuid $ProjectId) -ne $true){
        Write-Error "The provided ProjectId is not a guid value."
        exit
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
    $version = Get-Host | Select-Object Version
    Write-Host $version
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

    .PARAMETER projectId
        Project id for the project in Episerver DXP.

    .PARAMETER deploymentId
        Deployment id for the specific deployment in Episerver DXP that you want to show the progress for.

    .PARAMETER percentComplete
        The initialized percentComplete value that we got from the invoke of the operation.

    .PARAMETER expectedStatus
        The expectedStatus that the deployment should get when done/before timeout.

    .PARAMETER timeout
        The maximum time that the progress should run. When the script has timeout if will stop.

    .EXAMPLE
        $status = Invoke-DxpProgress -projectid $projectId -deploymentId $deploymentId -percentComplete $percentComplete -expectedStatus $expectedStatus -timeout $timeout

    .EXAMPLE
        $status = Invoke-DxpProgress -projectid '644b6926-39b1-42a1-93d6-3771cdc4a04e' -deploymentId '817b5df3-21cd-4080-adbd-6c211b71f34d' -percentComplete 0 -expectedStatus 'Success' -timeout 1800

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $deploymentId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int] $percentComplete,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $expectedStatus,
        [Parameter(Mandatory = $true)]
        [int] $timeout
    )

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    while ($percentComplete -le 100) {
        $status = Get-EpiDeployment -ProjectId $projectId -Id $deploymentId
        if ($percentComplete -ne $status.percentComplete) {
            $percentComplete = $status.percentComplete
            Write-Host $percentComplete "%. Status: $($status.status). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($percentComplete -le 100 -or $status.status -ne $expectedStatus) {
            Start-Sleep 5
        }
        if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
        if ($status.percentComplete -eq 100 -and $status.status -eq $expectedStatus) { break }
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDeployment -ProjectId $projectId -Id $deploymentId
    $status
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

function Import-AzureStorageModule {
    <#
    .SYNOPSIS
        Load module Az.Storage.

    .DESCRIPTION
        Load module Az.Storage.

    .EXAMPLE
        Import-AzureStorageModule

    #>
    $azModuleLoaded = Get-Module -Name "Az.Storage"

    if (-not ($azureModuleLoaded -or $azModuleLoaded)) {
        try {
            $null = Import-Module -Name "Az.Storage" -ErrorAction Stop
            $azModuleLoaded = $true
        }
        catch {
            Write-Verbose "Tried to find 'Az.Storage', module couldn't be imported."
        }
    }

    if ($azModuleLoaded) {
        "Az module loaded."
    }
    else {
        throw "'Az.Storage' module is required to run this cmdlet."
    }
}

function Get-DxpProjectBlobs{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientKey,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ClientSecret,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Integration','Preproduction','Production')]
        [string] $Environment = "Integration", #Integration | Preproduction | Production
        [Parameter(Mandatory=$false)]
        [string] $DownloadFolder = $PSScriptRoot, 
        [Parameter(Mandatory=$false)]
        [int] $MaxFilesToDownload = 0, # 0=All, 100=Max 100 downloads
        [Parameter(Mandatory=$false)]
        [string] $Container = "Blobs",  #AppLogs | WebLogs | Blobs
        [Parameter(Mandatory=$false)]
        [bool] $OverwriteExistingFiles = $true,
        [Parameter(Mandatory=$false)]
        [int] $RetentionHours = 2
    )

    Write-Host "Inputs:"
    Write-Host "ClientKey: $ClientKey"
    Write-Host "ClientSecret: **** (it is a secret...)"
    Write-Host "ProjectId: $ProjectId"
    Write-Host "Environment: $Environment"
    Write-Host "DownloadFolder: $DownloadFolder"
    Write-Host "MaxFilesToDownload: $MaxFilesToDownload"
    Write-Host "Container: $Container"
    Write-Host "OverwriteExistingFiles: $OverwriteExistingFiles"
    Write-Host "RetentionHours: $RetentionHours"

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $ProjectId
    Test-DownloadFolder -DownloadFolder $DownloadFolder
    Test-EnvironmentParam -Environment $Environment


    #return 
}

Export-ModuleMember -Function @( 'Get-DxpProjectBlobs', 'Write-DxpHostVersion', 'Get-DxpDateTimeStamp', 'Invoke-DxpProgress', 'Connect-DxpEpiCloud', 'Import-AzureStorageModule', 'Test-DxpProjectId' )