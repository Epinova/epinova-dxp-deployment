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
    Uninstall-Module -Name EpiCloud -AllVersions -Force
    #if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
    #    Write-Host "Could not find EpiCloud."
        #Install-Module EpiCloud  -Scope CurrentUser -MinimumVersion 0.13.15 -Force -AllowClobber
        #Write-Host "Installed EpiCloud."
        #Import-Module -Name "EpiCloud" -MinimumVersion 1.2.0 -Verbose
        Install-Module -Name "EpiCloud" -MinimumVersion 1.2.0 -Force
        #Import-Module -Name "$PSScriptRoot/EpiCloud/EpiCloud.psd1" -Verbose -ErrorAction Stop
        Write-Host "Import EpiCloud v1.2.0"
    #}
    #Get-Module -Name EpiCloud -ListAvailable
    #$version = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
    #Write-Host "EpiCloud            [$version]" 
    #if ($null -eq $version -or "" -eq $version) {
    #    Write-Error "Could not get version for the installed module EpiCloud"
    #}
    Write-Host Get-EpiCloudVersion
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
	[OutputType([System.Void])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ProjectId
	)
	
    if (!(Test-IsGuid -ObjectGuid $ProjectId)) {
        Write-Error "The provided ProjectId $ProjectId is not a guid value."
        exit 1
    }
}

function Get-DxpDateTimeStamp {
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
        Write the progress of a operation in the Optimizely (formerly known as Episerver) DXP environment to the host.

    .DESCRIPTION
        Write the progress of a operation in the Optimizely (formerly known as Episerver) DXP environment to the host.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

    .PARAMETER DeploymentId
        Deployment id for the specific deployment in Optimizely (formerly known as Episerver) DXP that you want to show the progress for.

    .PARAMETER PercentComplete
        The initialized percentComplete value that we got from the invoke of the operation.

    .PARAMETER ExpectedStatus
        The expectedStatus that the deployment should get when done/before timeout.

    .PARAMETER Timeout
        The maximum time that the progress should run. When the script has timeout if will stop.

    .EXAMPLE
        $status = Invoke-DxpProgress -ClientKey $ClientKey -ClientSecret $ClientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

    .EXAMPLE
        $status = Invoke-DxpProgress -ClientKey $ClientKey -ClientSecret $ClientSecret -Projectid '644b6926-39b1-42a1-93d6-3771cdc4a04e' -DeploymentId '817b5df3-21cd-4080-adbd-6c211b71f34d' -PercentComplete 0 -ExpectedStatus 'Success' -Timeout 1800

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
            $status = Get-EpiDeployment -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Id $DeploymentId
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

    $status = Get-EpiDeployment -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Id $DeploymentId
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

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.
        
    .PARAMETER ProjectId
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployments = Get-DxpEnvironmentDeployments -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployments = Get-DxpEnvironmentDeployments -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

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
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $getEpiDeploymentSplat = @{
        ClientKey    = $ClientKey
        ClientSecret = $ClientSecret
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

    .PARAMETER ClientKey
        The Optimizely DXP project ClientKey.

    .PARAMETER ClientSecret
        The Optimizely DXP project ClientSecret.

        .PARAMETER ProjectId
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployment = Get-DxpLatestEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployment = Get-DxpLatestEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[string]$ClientKey,
		
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[string]$ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $deployments = Get-DxpEnvironmentDeployments -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

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

    .PARAMETER ClientKey
        The Optimizely DXP project ClientKey.

    .PARAMETER ClientSecret
        The Optimizely DXP project ClientSecret.

    .PARAMETER ProjectId
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

    .PARAMETER TargetEnvironment
        The target environment that should match the deployment.

    .EXAMPLE
        $deployment = Get-DxpAwaitingEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment

    .EXAMPLE
        $deployment = Get-DxpAwaitingEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -TargetEnvironment 'Integration'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[string]$ClientKey,
		
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[string]$ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetEnvironment
    )

    $getEpiDeploymentSplat = @{
        ClientKey    = $ClientKey
        ClientSecret = $ClientSecret
        ProjectId    = $ProjectId
    }

    $deployment = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $TargetEnvironment }

    return $deployment
}

function Invoke-WarmupRequest {
    <#
    .SYNOPSIS
        Make a request against a URL to warm it up.

    .DESCRIPTION
        Make a request against a URL to warm it up.

    .PARAMETER RequestUrl
        The URL that should be warmed-up.

    .EXAMPLE
        Invoke-WarmupRequest -RequestUrl "https://epinova.se/news-and-stuff"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $RequestUrl
    )
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $RequestUrl -UseBasicParsing -MaximumRedirection 1 | Out-Null #-Verbose:$false
        
    } catch {
        #$_.Exception.Response
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Could not request $RequestUrl. Something went wrong. $statusCode"
        Write-Host $_.Exception.Message
    }
    $ProgressPreference = 'Continue'
}

function Invoke-WarmupSite{
    <#
    .SYNOPSIS
        Warm a site.

    .DESCRIPTION
        Will make a request to the specified URL. Take all links it can find and make a request for each link to warm up the site.

    .PARAMETER Url
        The URL that should be warmed-up.

    .EXAMPLE
        Invoke-WarmupSite -Url "https://epinova.se"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Url
    )

    if ($Url.EndsWith("/")) {
        $Url = $Url.Substring(0, $Url.Length - 1)
    }

    $iterator = 0

    while ($iterator -lt 10) {
        try {
            Write-Host "Invoke-WebRequest -Uri $Url"
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Verbose:$false -MaximumRedirection 1 -TimeoutSec 120
            $iterator = 999
            if ($null -ne $response){ 
                foreach ($link in $response.Links){
                    if ($null -ne $link -and $null -ne $link.href) {
                        if ($link.href.StartsWith("/") -and $false -eq $link.href.StartsWith("//")){
                            $newUrl = $Url + $link.href
                            Write-Host $newUrl
                            Invoke-WarmupRequest -requestUrl $newUrl
                        } elseif ($link.href.StartsWith($Url)) {
                            Write-Host $link.href
                            Invoke-WarmupRequest -requestUrl $link.href
                        } #else { #Used for debuging
                        #    Write-Warning "Not: $($link.href)" 
                        #}
                    }
                }
                Write-Host "Warm up site $Url - done."
            } else {
                Write-Warning "Could not request $Url. response = null"
            }
        } catch {
            Write-Warning "Could not warmup $Url"
            Write-Host $_.Exception.Message
            if ($iterator -lt 9){
                Write-Host "Will try again ($iterator)"
            } else {
                Write-Host "Will stop trying to warm up the web application."
            }
            $iterator++
        }
    }
}

function Test-PackageFileName {
    <#
    .SYNOPSIS
        Test package file name

    .DESCRIPTION
        Test if package file name contains any spaces. If so it will throw a exception.

    .PARAMETER PackageFile
        The FileSystemInfo that should be checked.

    .EXAMPLE
        $packageFile = Get-ChildItem -Path $dropPath -Filter *.cms.*.nupkg
        Test-PackageFileName -PackageFile $packageFile
    #>	
    param
	(
		[Parameter(Mandatory = $true)]
		[System.IO.FileSystemInfo]$PackageFile
	)

    if ($true -eq $PackageFile.Name.Contains(" ")) {
        $newName = $PackageFile.Name.Replace(" " , "")
        Write-Error "Package name contains space(s). Due to none support for spaces in EpiCloud API, you need to change the package name '$($PackageFile.Name)' => '$newName'."
    }
}

function Publish-Package {
    <#
    .SYNOPSIS
        Publish package to DXP storage account

    .DESCRIPTION
        Load the specified type of package, checks for errors, if none, upload package to DXP storage.

    .PARAMETER FilePath
        The path to the file that should be uploaded.

    .PARAMETER PackageLocation
        SAS link

    .EXAMPLE
        Publish-Package -PackageType "cms" -DropPath $dropPath -PackageLocation $packageLocation
    #>	
    param
	(
        [Parameter(Mandatory = $true)]
		[string]$FilePath,

        [Parameter(Mandatory = $true)]
		[string]$PackageLocation 
	)

    $uploadedPackage = ""
    $packageFileInfo = Get-Item -Path $FilePath
    Write-Host "Loaded package:    $packageFileInfo"

    Test-PackageFileName -PackageFile $packageFileInfo

    $packageFileName = $packageFileInfo.Name
    $packagePath = $packageFileInfo.FullName
    Write-Host "Package '$packageFileName' start upload..."
    Write-Verbose "Package '$packagePath' start upload..."

    try{
        Add-EpiDeploymentPackage -SasUrl $PackageLocation -Path $packageFileInfo.FullName
        Write-Host "Package '$packageFileName' is uploaded."
        Write-Verbose "Package '$packagePath' is uploaded."
        $uploadedPackage = $packageFileInfo.Name
    }
    catch{
        $errMsg = $_.Exception.ToString()
        if ($errMsg.Contains("is already linked to a deployment and cannot be overwritten")){
            Write-Host "Package '$packageFileName' already exist in container."
            $uploadedPackage = $packageFileName
        } else {
            Write-Error $errMsg
        }
    }

    return $uploadedPackage
}

function Get-EpiCloudVersion {
    $epiCloudVersion = ""
    try{
        $epiCloudModule = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
        $epiCloudVersion = "v$($epiCloudModule.Version.Major).$($epiCloudModule.Version.Minor).$($epiCloudModule.Version.Build)"
    } catch {
        Write-Verbose "Could not get EpiCloud version : $($_.Exception.ToString())"
        Write-Host "Could not get EpiCloud version."

    }
    return $epiCloudVersion
}

function Initialize-EpinovaDxpScript {
<#
    .SYNOPSIS
        Print info and check some values before connection to the EpiCloud.

    .DESCRIPTION
        Print info and check some values before connection to the EpiCloud.

    .PARAMETER ClientKey
        The Optimizely DXP project ClientKey.

    .PARAMETER ClientSecret
        The Optimizely DXP project ClientSecret.

    .PARAMETER ProjectId
        The Optimizely DXP project id. (Guid)

    .EXAMPLE
        Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId
    #>	
    param
	(
		[Parameter(Mandatory = $true)]
		[string]$ClientKey,
		[Parameter(Mandatory = $true)]
		[string]$ClientSecret,
		[Parameter(Mandatory = $true)]
		[string]$ProjectId
	)    
    
    #Mount-PsModulesPath

    Initialize-EpiCload
    
    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId
}