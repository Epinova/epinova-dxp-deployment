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
        Import-Module -Name "EpiCloud" -MinimumVersion 1.2.0 -Verbose
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
    } else {
        Write-Host "ProjectId is a GUID."
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
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

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
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

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
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

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
        Project id for the project in Optimizely (formerly known as Episerver) DXP.

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
    Write-Host "SuppressAzureRmModulesRetiringWarning"
    Set-Item -Path Env:\SuppressAzureRmModulesRetiringWarning -Value $true

    if ($null -eq (Get-Module -Name "Azure.Storage")) {
        Write-Host "Installing Azure.Storage Powershell Module -MinimumVersion 4.4.0"
        Install-Module -Name Azure.Storage -Scope CurrentUser -Repository PSGallery -MinimumVersion 4.4.0 -Force -AllowClobber
    }
}

function Import-AzStorageModule {
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
        "Az"
    }
    else {
        throw "'Az.Storage' module is required to run this cmdlet."
    }
}

function Install-AzStorage {
    <#
    .SYNOPSIS
        Install correct version of Az.Storage.

    .DESCRIPTION
        Install correct version of Az.Storage.

    .EXAMPLE
        Install-AzStorage
    #>
    if ($null -eq (Get-Module -Name "Az.Storage")) {
        #Import-Module -Name "Az.Storage" -Verbose
        Install-Module -Name Az.Storage -Scope CurrentUser -Repository PSGallery -MinimumVersion 3.7.0 -Force -AllowClobber
    }
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

    CheckWishes

    $taskModulePath = $PSScriptRoot
    if (-not ($env:PSModulePath.Contains($taskModulePath))) {
        $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$taskModulePath"
        Write-Host "Added $taskModulePath to env:PSModulePath" 
    }
}

function CheckWishes{
    $now = Get-Date
    if ((($now.Day -eq 24) -and ($now.Month -eq 12)) -or (($now.Day -eq 25) -and ($now.Month -eq 12))){        
        PrintChristmasWish
    }
    if ((($now.Day -eq 31) -and ($now.Month -eq 12)) -or (($now.Day -eq 1) -and ($now.Month -eq 1))){
        PrintNewYearWish
    }
}
function PrintChristmasWish{

    Write-Host "                                                 |"
    Write-Host "                                                -+-"
    Write-Host "                                                 A"
    Write-Host "                                                /=\        "
    Write-Host "                                              i/ O \i     "
    Write-Host "                                              /=====\     "
    Write-Host "                                              /  i  \     "
    Write-Host "                                            i/ O * O \i   "
    Write-Host "                                            /=========\   "
    Write-Host "                                            /  *   *  \    "
    Write-Host "                                          i/ O   i   O \i   "
    Write-Host "                                          /=============\    "
    Write-Host "                                          /  O   i   O  \     "
    Write-Host "                                        i/ *   O   O   * \i"
    Write-Host "                                        /=================\"
    Write-Host "                                               |___|"
    Write-Host "   _____                               _________ .__          .__          __                          "
    Write-Host "  /     \   __________________ ___.__. \_   ___ \|  |_________|__| _______/  |_  _____ _____    ______ "
    Write-Host " /  \ /  \_/ __ \_  __ \_  __ <   |  | /    \  \/|  |  \_  __ \  |/  ___/\   __\/     \\__  \  /  ___/ "
    Write-Host "/    Y    \  ___/|  | \/|  | \/\___  | \     \___|   Y  \  | \/  |\___ \  |  | |  Y Y  \/ __ \_\___ \  "
    Write-Host "\____|__  /\___  >__|   |__|   / ____|  \______  /___|  /__|  |__/____  > |__| |__|_|  (____  /____  > "
    Write-Host "        \/     \/              \/              \/     \/              \/             \/     \/     \/  "
    Write-Host "                                  _____                       "
    Write-Host "                                _/ ____\______  ____   _____  "
    Write-Host "                                \   __\\_  __ \/  _ \ /     \ "
    Write-Host "                                 |  |   |  | \(  <_> )  Y Y  \"
    Write-Host "                                 |__|   |__|   \____/|__|_|  /"
    Write-Host "                                                           \/ "
    Write-Host "                         ___________      .__                                                                                  " 
    Write-Host "                         \_   _____/_____ |__| ____   _______  _______                                                          "
    Write-Host "                          |    __)_\____ \|  |/    \ /  _ \  \/ /\__  \                                                          "
    Write-Host "                          |        \  |_> >  |   |  (  <_> )   /  / __ \_                                                       "
    Write-Host "                         /_______  /   __/|__|___|  /\____/ \_/  (____  /                                                       "
    Write-Host "                                 \/|__|           \/                  \/          "
}

function PrintNewYearWish{
    Write-Host "                          ..............*.....o..°"
    Write-Host "                          .....*.....o..°..........o..°"
    Write-Host "                          *.......*....o..° °.........o..°*"
    Write-Host "                          ....*....o..°........o..°........o..°...*"
    Write-Host "                          °...................*............*.....o..°"
    Write-Host "                          °.....*....o..°______________.*.....o..°"
    Write-Host "                          `$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$.....o......o."
    Write-Host "                          `$`$______________________`$`$..o..°*"
    Write-Host "                          `$`$__________`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$`$"
    Write-Host "                          _s`$`$________`$`$________`$`$____________`$`$"
    Write-Host "                          ___s`$`$______`$`$______`$`$______________`$`$"
    Write-Host "                          _____s`$`$______`$`$__`$`$______________`$`$s"
    Write-Host "                          _______s`$`$______`$`$______________`$`$s"
    Write-Host "                          _________s`$`$`$`$`$`$__`$`$__________`$`$s"
    Write-Host "                          ____________`$`$_____s`$`$______`$`$s"
    Write-Host "                          ____________`$`$_______s`$`$`$`$`$`$s"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          ____________`$`$__________`$`$"
    Write-Host "                          __________`$`$`$`$`$`$________`$`$"
    Write-Host "                          ______`$`$`$`$`$`$`$`$`$`$`$`$`$`$____`$`$"
    Write-Host "                          ______________________`$`$`$`$`$`$"
    Write-Host "                          __________________`$`$`$`$`$`$`$`$`$`$`$`$`$`$"
    Write-Host "                          -:¦:-____-:¦:-__ __-:¦:-______-:¦:-"
    Write-Host "  ___ ___                                                                                 "
    Write-Host " /   |   \_____  ______ ______ ___.__.   ____   ______  _  __  ___.__. ____ _____ _______ "
    Write-Host "/    ~    \__  \ \____ \\____ <   |  |  /    \_/ __ \ \/ \/ / <   |  |/ __ \\__  \\_  __ \"
    Write-Host "\    Y    // __ \|  |_> >  |_> >___  | |   |  \  ___/\     /   \___  \  ___/ / __ \|  | \/"
    Write-Host " \___|_  /(____  /   __/|   __// ____| |___|  /\___  >\/\_/    / ____|\___  >____  /__|   "
    Write-Host "       \/      \/|__|   |__|   \/           \/     \/          \/         \/     \/       "
    Write-Host "                                  _____                       "
    Write-Host "                                _/ ____\______  ____   _____  "
    Write-Host "                                \   __\\_  __ \/  _ \ /     \ "
    Write-Host "                                 |  |   |  | \(  <_> )  Y Y  \"
    Write-Host "                                 |__|   |__|   \____/|__|_|  /"
    Write-Host "                                                           \/ "
    Write-Host "                      ___________      .__                                                                                  " 
    Write-Host "                      \_   _____/_____ |__| ____   _______  _______                                                          "
    Write-Host "                       |    __)_\____ \|  |/    \ /  _ \  \/ /\__  \                                                          "
    Write-Host "                       |        \  |_> >  |   |  (  <_> )   /  / __ \_                                                       "
    Write-Host "                      /_______  /   __/|__|___|  /\____/ \_/  (____  /                                                       "
    Write-Host "                              \/|__|           \/                  \/          "


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

function Test-PackageFile {
    <#
    .SYNOPSIS
        Test package file

    .DESCRIPTION
        Test if package file is empty/null.

    .PARAMETER PackageFile

    .PARAMETER DropPath

    .PARAMETER PackageFile

    .EXAMPLE
        $packageFile = Get-ChildItem -Path $dropPath -Filter *.cms.*.nupkg
        Test-PackageFile -PackageType "cms" -DropPath $dropPath -PackageFile $packageFile
    #>
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$PackageType,
		[Parameter(Mandatory = $true)]
		[string]$DropPath,
		[Parameter(Mandatory = $true)]
		[System.IO.FileSystemInfo]$PackageFile
	)

    if ($null -eq $PackageFile){
        Write-Host "Following files found in location $DropPath : $(Get-ChildItem -Path $DropPath -File)"
        Write-Host "##vso[task.logissue type=error]Could not find the $PackageType package in location $DropPath."
        Write-Error "Could not find the $PackageType package in location $DropPath." -ErrorAction Stop
        exit 1
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

    .PARAMETER PackageType
        
    .PARAMETER DropPath

    .PARAMETER PackageLocation
        SAS link

    .EXAMPLE
        Publish-Package -PackageType "cms" -DropPath $dropPath -PackageLocation $packageLocation
    #>	
    param
	(
		[Parameter(Mandatory = $true)]
		[string]$PackageType,
		[Parameter(Mandatory = $true)]
		[string]$DropPath,
		[Parameter(Mandatory = $true)]
		[string]$PackageLocation 
	)

    $uploadedPackage = ""
    $packageFileInfo = Get-ChildItem -Path $DropPath -Filter "*.$PackageType.*.nupkg"
    
    Write-Host "Loaded $PackageType package:    $packageFileInfo"
    
    Test-PackageFile -PackageType $PackageType -DropPath $DropPath -PackageFile $packageFileInfo

    Test-PackageFileName -PackageFile $packageFileInfo

    $packageFileName = $packageFileInfo.Name
    
    Write-Host "$PackageType package '$packageFileName' start upload..."
    try{
        Add-EpiDeploymentPackage -SasUrl $PackageLocation -Path $packageFileInfo.FullName
        Write-Host "$PackageType package '$packageFileName' is uploaded."
        $uploadedPackage = $packageFileInfo.Name
    }
    catch{
        $errMsg = $_.Exception.ToString()
        if ($errMsg.Contains("is already linked to a deployment and cannot be overwritten")){
            Write-Host "$PackageType package '$packageFileName' already exist in container."
            $uploadedPackage = $packageFileName
        } else {
            Write-Error $errMsg
        }
    }

    return $uploadedPackage
}

function Invoke-DxpDatabaseExportProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ClientSecret,

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
    $status = $null
    while ($currentStatus -ne $expectedStatus) {
        $status = Get-EpiDatabaseExport -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
        $currentStatus = $status.status
        if ($iterator % 6 -eq 0) {
            Write-Host "Database backup status: $($currentStatus). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($currentStatus -ne $ExpectedStatus) {
            Start-Sleep 10
        }
        if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
        if ($currentStatus -eq $ExpectedStatus) { break }
        $iterator++
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    if ($null -ne $status){
        Write-Host "################################################"
        Write-Host "Database export:"
        Write-Host "Status:       $($status.status)"
        Write-Host "BacpacName:   $($status.bacpacName)"
        Write-Host "DownloadLink: $($status.downloadLink)"
    }
    return $status
}

function Invoke-DxpDatabaseDownload{
    <#
    .SYNOPSIS
        Download DXP project DB.

    .DESCRIPTION
        Download DXP project DB. You can specify the environment from where the database should be exported from.
        Will return with the file path to where database is downloaded.

    .PARAMETER ClientKey
        Your DXP ClientKey that you can generate in the paas.episerver.net portal.

    .PARAMETER ClientSecret
        Your DXP ClientSecret that you can generate in the paas.episerver.net portal.

    .PARAMETER ProjectId
        The DXP project id that is related to the ClientKey/Secret.

    .PARAMETER Environment
        The environment that holds the blobs that you want to download.

    .PARAMETER DatabaseName
        The type of database you want to download from Optimizely DXP. epicms / epicommerce

    .PARAMETER DownloadFolder
        The local download folder where you want to download the DB backup file.

    .PARAMETER Timeout
        The number of seconds that you will let the script run until it will timeout. Default 1800 (ca 30 minutes)

    .EXAMPLE
        Invoke-DxpDatabaseDownload -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -DatabaseName $DatabaseName -DownloadFolder $DownloadFolder -RetentionHours $RetentionHours -Timeout $Timeout

    .EXAMPLE
        Invoke-DxpDatabaseDownload -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' -DatabaseName 'epicms' -DownloadFolder "c:\temp" -RetentionHours 2 -Timeout 1800

    .EXAMPLE
        $filePath = Invoke-DxpDatabaseDownload -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -DatabaseName $DatabaseName -DownloadFolder $DownloadFolder -RetentionHours $RetentionHours -Timeout $Timeout

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $Environment,

        [Parameter(Mandatory=$true)]
        [ValidateSet('epicms','epicommerce')]
        [string] $DatabaseName,

        [Parameter(Mandatory=$true)]
        [string] $DownloadFolder,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 168)]
        [int] $RetentionHours = 2,

        [Parameter(Mandatory = $false)]
        [int] $Timeout = 1800
    )

    Write-Host "Invoke-DxpDatabaseDownload - Inputs:-------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "DatabaseName:           $databaseName"
    Write-Host "DownloadFolder:         $DownloadFolder"
    Write-Host "RetentionHours:         $RetentionHours"
    Write-Host "Timeout:                $timeout"
    Write-Host "------------------------------------------------"

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $ProjectId
    Test-DownloadFolder -DownloadFolder $DownloadFolder

    #Import-EpiCloud
    Initialize-EpiCload

    Connect-DxpEpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId

    $exportDatabaseSplat = @{
        ClientKey      = $ClientKey
        ClientSecret   = $ClientSecret
        ProjectId      = $ProjectId
        Environment    = $Environment
        DatabaseName   = $DatabaseName
        RetentionHours = $RetentionHours
    }

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
        $status = Invoke-DxpDatabaseExportProgress -ClientKey $ClientKey -ClientSecret $ClientSecret -Projectid $ProjectId -ExportId $ExportId -Environment $Environment -DatabaseName $DatabaseName -ExpectedStatus "Succeeded" -Timeout $timeout
        Write-Host "------------------------------------------------"
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Export $exportId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Database export $exportId has been successful."
            Write-Host "-------------DOWNLOAD----------------------------"
            Write-Host "Start download database $($status.downloadLink)"
            #$filePath = Join-Parts -Separator '\' -Parts $DownloadFolder, $status.bacpacName
            $filePath = "$DownloadFolder\$($status.bacpacName)"
            Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath
            Write-Host "Downloaded database to $filePath"
            Write-Host "------------------------------------------------"
            return $filePath;
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
}


##################################################################################
function Get-DefaultStorageAccount{
    <#
        .SYNOPSIS
            List all resources for a resource group and grab the first StorageAccount it can find.
    
        .DESCRIPTION
            List all resources for a resource group and grab the first StorageAccount it can find.  
            Will only work if connection to Azure already exist.
    
        .PARAMETER ResourceGroupName
            The resource group where we will look for the StorageAccount.

        .PARAMETER StorageAccountName
            The name of the StorageAccount.

        .EXAMPLE
            Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
    
        #>
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ResourceGroupName,

            [Parameter(Mandatory = $false)]
            [string] $StorageAccountName
        )
        if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName) {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
            #$storageAccount #For debuging
            if ($storageAccount -is [array]){
                if ($storageAccount.Count -ne 1) {
                    if ($storageAccount.Count -gt 1) {
                        Write-Warning "Found more then 1 StorageAccount in ResourceGroup: $ResourceGroupName."
                    }
                    if ($storageAccount.Count -eq 0) {
                        Write-Warning "Could not find a StorageAccount in ResourceGroup: $ResourceGroupName."
                    }
                    exit
                }
            }
        } else {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
            if ($null -eq $storageAccount) {
                Write-Error "Did not find StorageAccount in ResourceGroup: $ResourceGroupName."
                exit
            }
        }
        return $storageAccount
}

function Get-StorageAccountContainer{
    <#
        .SYNOPSIS
            Get the container for the specified StorageAccount.
    
        .DESCRIPTION
            Get the container for the specified StorageAccount.  
            Will only work if connection to Azure aleasy exist.

        .PARAMETER StorageAccount
            The StorageAccount where the container should exist.

        .PARAMETER ContainerName
            The container name.
    
        .EXAMPLE
            Get-StorageAccountContainer -StorageAccount $StorageAccount -ContainerName $ContainerName

        .EXAMPLE
            $storageAccount = Get-DefaultStorageAccount ResourceGroupName $ResourceGroupName
            Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $ContainerName

        #>
        param(
            [Parameter(Mandatory)]
            [object]$StorageAccount,
            [Parameter(Mandatory)]
            [string]$ContainerName
        )
        $storageContainer = Get-AzRmStorageContainer -StorageAccount $StorageAccount -ContainerName $ContainerName
        #$storageContainer
        if ($null -eq $storageContainer) {
            Write-Warning "Could not find a StorageAccount container '$($storageContainer.Name)' in ResourceGroup: $($StorageAccount.ResourceGroupName))."
            exit
        } else {
            Write-Host "Connected to destination StorageAccount container $($storageContainer.Name)"
        }

        return $storageContainer
}

function Import-BacpacDatabase{
    <#
    .SYNOPSIS
        Import a bacpac file, from storageaccount container, to a database in Azure.
    .DESCRIPTION
        Import a bacpac file, from storageaccount container, to a database in Azure.

    .PARAMETER SubscriptionId
        Your Azure SubscriptionId where your resources are located.

    .PARAMETER ResourceGroupName
        The resource group contains the Azure SQL Server and storage account where the bacpac file is loacated.

    .PARAMETER StorageAccountName
        The StorageAccount name where the bacpac file is located.

    .PARAMETER StorageAccountContainer
        The container name where the bacpac file is located.

    .PARAMETER BacpacFilename
        The name on the bacpac file.

    .PARAMETER SqlServerName
        The name on Azure SQL Server that contains the database.

    .PARAMETER SqlDatabaseName
        The name on the database that will be generated from the bacpac.

    .PARAMETER SqlDatabaseLogin
        The sa login to the Azure SQL Server.

    .PARAMETER SqlDatabasePassword
        The password for the login to the Azure SQL Server.

    .PARAMETER RunDatabaseBackup


    .PARAMETER SqlSku
        Specifies which SQL SKU you want to generate. If not specified it will create a "basic" SQL Server. Allowed SKU 'Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4'

    .EXAMPLE
        Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku

    .EXAMPLE
        Import-BacpacDatabase -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountContainer $StorageAccountContainer -BacpacFilename $BacpacFilename -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -RunDatabaseBackup $RunDatabaseBackup -SqlSku $SqlSku

    #>
    [cmdletbinding()]
     param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [string] $StorageAccountContainer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $BacpacFilename,

        [Parameter(Mandatory = $false)]
        [string] $SqlServerName,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseName,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabaseLogin,
 
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SqlDatabasePassword,

        [Parameter(Mandatory = $true)]
        [bool] $RunDatabaseBackup,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Free', 'Basic', 'S0', 'S1', 'P1', 'P2', 'GP_Gen4_1', 'GP_S_Gen5_1', 'GP_Gen5_2', 'GP_S_Gen5_2', 'BC_Gen4_1', 'BC_Gen5_4')]
        [string] $SqlSku = "Basic"
    )

    Connect-AzureSubscriptionAccount

    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName){
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName
        $storageAccountName = $storageAccount.StorageAccountName
    } else {
        $storageAccount = Get-DefaultStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
        $storageAccountName = $storageAccount.StorageAccountName
    }
    Write-Host "Found StorageAccount '$storageAccountName'"

    if ($null -eq $StorageAccountContainer -or "" -eq $StorageAccountContainer){
        $storageContainer = Get-StorageAccountContainer -StorageAccount $storageAccount -ContainerName $StorageAccountContainer
        $storageContainerName = $storageContainer.Name
    } else {
        $storageContainerName = $StorageAccountContainer
    }
    Write-Host "Found StorageAccount container '$storageContainerName'"
    
    if ($null -eq $SqlServerName -or "" -eq $SqlServerName) {
        $SqlServerName = Get-DefaultSqlServer -ResourceGroupName $ResourceGroupName
    }
    Write-Host "Found SqlServer '$SqlServerName'"


    $databaseExist = $false
    try {
        $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName -ErrorAction SilentlyContinue
        if ($null -ne $databaseResult) {
            $databaseExist = $true
            Write-Host "Destination database $SqlDatabaseName exist."
        } else {
            Write-Host "Destination database $SqlDatabaseName does not exist."
        }
    } catch {
        Write-Host "Destination database $SqlDatabaseName does not exist."
        $error.clear()
    }

    Write-Host "Import-BacpacDatabase - Inputs:-----------------"
    Write-Host "SubscriptionId:           $SubscriptionId"
    Write-Host "ResourceGroupName:        $ResourceGroupName"
    Write-Host "StorageAccountName:       $storageAccountName"
    Write-Host "StorageAccountContainer:  $storageContainerName"
    Write-Host "BacpacFilename:           $BacpacFilename"
    Write-Host "SqlServerName:            $SqlServerName"
    Write-Host "SqlDatabaseName:          $SqlDatabaseName"
    Write-Host "SqlDatabaseLogin:         $SqlDatabaseLogin"
    Write-Host "SqlDatabasePassword:      **** (it is a secret...)"
    Write-Host "SqlSku:                   $SqlSku"
    Write-Host "------------------------------------------------"

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
 
    if ($true -eq $databaseExist -and $true -eq $RunDatabaseBackup) {
        Backup-Database -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -SqlDatabaseLogin $SqlDatabaseLogin -SqlDatabasePassword $SqlDatabasePassword -StorageAccountName $storageAccountName -StorageAccountContainer $StorageAccountContainer

        Unpublish-Database -ResourceGroupName $ResourceGroupName -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName
    }
    
    $importRequest = New-AzSqlDatabaseImport -ResourceGroupName $ResourceGroupName `
     -ServerName $SqlServerName `
     -DatabaseName $SqlDatabaseName `
     -DatabaseMaxSizeBytes 10GB `
     -StorageKeyType "StorageAccessKey" `
     -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -StorageAccountName $storageAccountName).Value[0] `
     -StorageUri "https://$storageAccountName.blob.core.windows.net/$storageContainerName/$BacpacFilename" `
     -Edition "Standard" `
     -ServiceObjectiveName "S3" `
     -AdministratorLogin "$SqlDatabaseLogin" `
     -AdministratorLoginPassword $(ConvertTo-SecureString -String $SqlDatabasePassword -AsPlainText -Force)
 
    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write("Importing")
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
    Write-Host "Database '$SqlDatabaseName' is imported."

    # Check the SKU on destination database after copy. 
    $databaseResult = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $SqlDatabaseName
    $databaseResult
 
    # Scale down to S0 after import is complete
    Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -DatabaseName $SqlDatabaseName -ServerName $SqlServerName -RequestedServiceObjectiveName $SqlSku #-Edition "Standard"
 }

 function Get-DxpStorageContainers{
    <#
    .SYNOPSIS
        List storage containers in a DXP environment.

    .DESCRIPTION
        List storage containers in a DXP environment.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER Environment
        The environment where we should check for storage containers.

    .PARAMETER Container
        The name of the container that you want. If it does not exist it will try ti figure out which container you want.

    .EXAMPLE
        Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment

    .EXAMPLE
        Get-DxpStorageContainers -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' 

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $Environment
    )

    Write-Host "Get-DxpStorageContainers - Inputs:--------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "------------------------------------------------"

    try {
        $containers = Get-EpiStorageContainer -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
    }
    catch {
        Write-Error "Could not get storage container information from Epi. Make sure you have specified correct ProjectId/Environment"
        Write-Error $_.Exception.ToString()
        exit
    }

    if ($null -eq $containers){
        Write-Error "Could not get Epi DXP storage containers. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    return $containers
}

 function Get-DxpStorageContainerSasLink{
    <#
    .SYNOPSIS
        ...

    .DESCRIPTION
        ...

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER Environment
        The environment where we should check for storage containers.

    .PARAMETER Containers
        List of containers that we should look for the one that match the next parameter Container.

    .PARAMETER Container
        The name of the container that you want. If it does not exist it will try ti figure out which container you want.

    .EXAMPLE
        Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $Containers -Container $Container -RetentionHours $RetentionHours

    .EXAMPLE
        Get-DxpStorageContainerSasLink -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' -Containers $Containers -Container "mysitemedia" -RetentionHours 2

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
        [string] $Environment,

        [Parameter(Mandatory = $false)]
        [object] $Containers,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Container,

        [Parameter(Mandatory = $false)]
        [int] $RetentionHours = 2

    )

    if ($null -eq $Containers){
        $Containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment
    }

    $linkSplat = @{
        ClientKey = $ClientKey
        ClientSecret = $ClientSecret
        ProjectId = $ProjectId
        Environment = $Environment
        StorageContainer = $Containers.storageContainers
        RetentionHours = $RetentionHours
    }

    $linkResult = Get-EpiStorageContainerSasLink @linkSplat

    $sasLink = $null
    foreach ($link in $linkResult){
        if ($link.containerName -eq $Container) {
            Write-Host "Found Sas link for container   : $Container"
            $sasLink = $link
        } else {
            Write-Host "Ignore container   : $($link.containerName)"
        }
    }

    return $sasLink
}

#  function Sync-DxpBlobsToAzure{
#     <#
#     .SYNOPSIS
#         Sync/Harmonize DXP blobs to a Azure storage account container.

#     .DESCRIPTION
#         Sync/Harmonize DXP blobs to a Azure storage account container.

#     .PARAMETER ClientKey
#         Your DXP ClientKey that you can generate in the paas.episerver.net portal.

#     .PARAMETER ClientSecret
#         Your DXP ClientSecret that you can generate in the paas.episerver.net portal.

#     .PARAMETER ProjectId
#         The DXP project id that is related to the ClientKey/Secret.

#     .PARAMETER Environment
#         The environment that holds the blobs that you want to download.

#     .PARAMETER DxpContainer
#         The container in DXP environment that contains the blobs

#     .PARAMETER Timeout
#         The number of seconds that you will let the script run until it will timeout. Default 1800 (ca 30 minutes)

#     .PARAMETER SubscriptionId
#         Your Azure SubscriptionId where your resources are located.

#     .PARAMETER ResourceGroupName
#         The resource group contains the Azure SQL Server and storage account where the bacpac file is loacated.

#     .PARAMETER StorageAccountName
#         The StorageAccount name where the bacpac file is located.

#     .PARAMETER StorageAccountContainer
#         The container name where the bacpac file is located.

#     .PARAMETER CleanBeforeCopy
#         Set to true if you want thw script to remove all blobs in destination container before we start copy over all blobs.

#     .EXAMPLE
#         Sync-DxpBlobsToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DxpContainer $DxpContainer -Timeout 1800 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer -CleanBeforeCopy $true

#     #>
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory=$true)]
#         [ValidateNotNullOrEmpty()]
#         [String] $ClientKey,

#         [Parameter(Mandatory=$true)]
#         [ValidateNotNullOrEmpty()]
#         [String] $ClientSecret,

#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string] $ProjectId,

#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
#         [string] $Environment,

#         [Parameter(Mandatory=$true)]
#         [ValidateNotNullOrEmpty()]
#         [string] $DxpContainer,

#         [Parameter(Mandatory = $false)]
#         [int] $Timeout = 1800,

#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string] $SubscriptionId,

#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string] $ResourceGroupName,

#         [Parameter(Mandatory = $false)]
#         [string] $StorageAccountName,

#         [Parameter(Mandatory = $false)]
#         [string] $StorageAccountContainer,

#         [Parameter(Mandatory = $false)]
#         [bool] $CleanBeforeCopy

#     )

#     Write-Host "Sync-DxpBlobsToAzure - Inputs:------------------"
#     Write-Host "ClientKey:                $ClientKey"
#     Write-Host "ClientSecret:             **** (it is a secret...)"
#     Write-Host "ProjectId:                $ProjectId"
#     Write-Host "Environment:              $Environment"
#     Write-Host "DxpContainer:             $DxpContainer"
#     Write-Host "Timeout:                  $Timeout"
#     Write-Host "SubscriptionId:           $SubscriptionId"
#     Write-Host "ResourceGroupName:        $ResourceGroupName"
#     Write-Host "StorageAccountName:       $StorageAccountName"
#     Write-Host "StorageAccountContainer:  $StorageAccountContainer"
#     Write-Host "CleanBeforeCopy:          $CleanBeforeCopy"
#     Write-Host "------------------------------------------------"    

#     Test-DxpProjectId -ProjectId $ProjectId
    
#     $RetentionHours = 2 # Set the retantion hours to 2h. Should be good enough to sync the blobs

#     $sasLinkInfo = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $null -Container $DxpContainer -RetentionHours $RetentionHours
#     if ($null -eq $sasLinkInfo) {
#         Write-Error "Did not get a SAS link to container $DxpContainer."
#         exit
#     }
#     Write-Host "Found SAS link info: ---------------------------"
#     Write-Host "projectId:                $($sasLinkInfo.projectId)"
#     Write-Host "environment:              $($sasLinkInfo.environment)"
#     Write-Host "containerName:            $($sasLinkInfo.containerName)"
#     Write-Host "sasLink:                  $($sasLinkInfo.sasLink)"
#     Write-Host "expiresOn:                $($sasLinkInfo.expiresOn)"
#     Write-Host "------------------------------------------------"
#     $SourceSasLink = $sasLinkInfo.sasLink

#     Copy-BlobsWithSas -SourceSasLink $SourceSasLink -DestinationSubscriptionId $SubscriptionId -DestinationResourceGroupName $ResourceGroupName -DestinationStorageAccountName $StorageAccountName -DestinationContainerName $StorageAccountContainer -CleanBeforeCopy $CleanBeforeCopy

#     Write-Host "All blobs is now synced"
# }

# function Get-StorageAccountNameFromSasLink {
#     <#
#     .SYNOPSIS
#         Break out the storage account value from SAS link.

#     .DESCRIPTION
#         Break out the storage account value from SAS link.

#     .PARAMETER SasLink
#         The SAS link.

#     .EXAMPLE
#         Get-StorageAccountNameFromSasLink -SasLink $SasLink

#     #>
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [ValidateNotNullOrEmpty()]
#         [string] $SasLink
#     )

#     if ($sasLink.Contains("&sr=b&")) {
#         Write-Host "Blob copy"
#         $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\/(.*)\?" | Out-Null
#         $blob = $Matches[3]
#         Write-Host "Blob:                           $blob"
#         $blobCopy = $true
#     } elseif ($sasLink.Contains("&sr=c&")) {
#         Write-Host "Container copy"
#         $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\?" | Out-Null
#     } else {
#         Write-Error "Not supported sr (Storage Resource). Only support sr=b|c."
#         exit
#     }
#     $storageAccountName = $Matches[1]
#     Write-Host "StorageAccountName:       $storageAccountName"

#     $containerName = $Matches[2]
#     Write-Host "ContainerName:            $containerName"

#     $sasLink -match "(\?.*)" | Out-Null
#     $sasToken = $Matches[0]
#     Write-Host "SAS token:                      $sasToken"
    
#     return $storageAccountName
# }

class SasInfo{
    [string]$SasLink
    [bool]$IsBlobLink
    [bool]$IsContainerLink
    [string]$StorageAccountName
    [string]$ContainerName
    [string]$SasToken
    [string]$PathLink
    [string]$Blob
}

function Get-SasInfo {
    <#
    .SYNOPSIS
        Break out the blob name from SAS link.

    .DESCRIPTION
        Break out the blob name from SAS link.

    .PARAMETER SasLink
        The SAS link.

    .EXAMPLE
        Get-BlobNameFromSasLink -SasLink $SasLink

    #>
    [CmdletBinding()]
    [OutputType([SasInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SasLink
    )

    Write-Host "[SasInfo]"
    Write-Host "SasLink:                  $sasLink"
    $sasInfo = [SasInfo]::new()
    $sasInfo.SasLink = $sasLink
    if ($sasLink.Contains("&sr=b&")) {
        $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\/(.*)\?" | Out-Null
        $blob = $Matches[3]
        Write-Host "Blob:                     $blob"
        $sasInfo.Blob = $blob
        $sasInfo.IsBlobLink = $true
        Write-Host "IsBlobLink:               $true"
        Write-Host "IsContainerLink:          $false"
    } elseif ($sasLink.Contains("&sr=c&")) {
        $sasLink -match "https:\/\/(.*).blob.core.*\/(.*)\?" | Out-Null
        $sasInfo.IsContainerLink = $true
        Write-Host "IsBlobLink:               $false"
        Write-Host "IsContainerLink:          $true"
    } else {
        Write-Error "Not supported sr (Storage Resource). Only support sr=b|c."
        exit
    }
    $storageAccountName = $Matches[1]
    Write-Host "StorageAccountName:       $storageAccountName"
    $sasInfo.StorageAccountName = $storageAccountName

    $containerName = $Matches[2]
    Write-Host "ContainerName:            $containerName"
    $sasInfo.ContainerName = $containerName

    $sasLink -match "(\?.*)" | Out-Null
    $sasToken = $Matches[0]
    Write-Host "SasToken:                 $sasToken"
    $sasInfo.SasToken = $sasToken

    $sasInfo.PathLink = $sasLink.Replace($sasToken, "")
    Write-Host "PathLink:                 $($sasInfo.PathLink)"
    
    return $sasInfo
}
