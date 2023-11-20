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
    This helper function adds support for TLS 1.2

    .DESCRIPTION
    This helper function adds support for TLS 1.2

    #>

    # # Add support for TLS 1.2
    # if (-not [Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12) -AND $EnableTls12) {
    #     [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    # }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
function Test-DatabaseName{
    <#
    .SYNOPSIS
        Test that the database name is correct.

    .DESCRIPTION
        Test that the database name is correct.

    .PARAMETER DatabaseName
        The database name that you want to test.

    .EXAMPLE
        Test-DatabaseName -DatabaseName $DatabaseName

    #>
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$DatabaseName
	)

    if ($databaseName -eq "epicms" -or $databaseName -eq "epicommerce") {
        Write-Host "DatabaseName param ok."
    }
    else {
        Write-Error "The database $databaseName that you have specified is not valid. Ok databaseName: epicms | epicommerce"
        exit
    } 
}
function Test-ContainerName{
    <#
    .SYNOPSIS
        Test if the container exist and if not it will figure out a container to use..

    .DESCRIPTION
        Test if the container exist and if not it will figure out a container to use..

    .PARAMETER Container
        The shortname of the container.

    .EXAMPLE
        Format-ContainerName -Container $Container

    #>
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[object]$Containers,
		[Parameter(Mandatory = $true)]
		[string]$Container
	)  

    if ($Container -eq "AppLogs"){
        $Container = "azure-application-logs"
    } elseif ($Container -eq "WebLogs"){
        $Container = "azure-web-logs"
    } elseif ($Container -eq "Blobs"){
        $Container = "mysitemedia"
    } 

    if ($false -eq $Containers.storageContainers.Contains($Container))
    #if ($false -eq $Containers.Contains($Container))
    {
        Write-Host "Containers does not contain $Container. Will try to figure out the correct one."
        Write-Host "Found the following containers for your project:"
        Write-Host "---------------------------------------------------"
        foreach ($tempContainer in $Containers.storageContainers){
        #foreach ($tempContainer in $Containers){
            Write-Host "$tempContainer"
        }
        Write-Host "---------------------------------------------------"
        if ($Container -eq "mysitemedia" -and $Containers.storageContainers.Length -eq 3) {
        #if ($Container -eq "mysitemedia" -and $Containers.Length -eq 3) {
            $exclude = @("azure-application-logs", "azure-web-logs")
            $lastContainer = $Containers.storageContainers | Where-Object { $_ -notin $exclude }
            #$lastContainer = $Containers | Where-Object { $_ -notin $exclude }
            if ($lastContainer.Length -ne 0) {
                $Container = $lastContainer
                Write-Host "Found '$Container' and going to use that as the blob container."
            } else {
                Write-Host "After trying to figure out which is the blob container. We still can not find it."
                Write-Error "Expected blob container '$Container' but we can not find it. Check the specified container above and try to specify one of them."
                exit
            }
        } else {
            if ($Container -eq "azure-application-logs" -or $Container -eq "azure-web-logs"){
                Write-Error "Expected log container '$Container' but we could not find it."
            } else {
                Write-Error "Expected container '$Container' but we can not find it. Check the found containers above and try to specify one of them as param -container."
            }
            exit
        }
    }

    return $Container
}
function Import-Az{
    <#
    .SYNOPSIS
        Install-Module Az.

    .DESCRIPTION
        Install-Module Az.

    .EXAMPLE
        Import-Az
    #>
    if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
        Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
            'Az modules installed at the same time is not supported.')
    } else {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }
}

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

function Get-StorageAccountName{
    <#
    .SYNOPSIS
        Get StorageAccountName from a SAS link.

    .DESCRIPTION
        Get StorageAccountName from a SAS link.
        The SasLink you will get by using Get-DxpStorageContainerSasLink

    .PARAMETER SasLink
        The SasLink that contain the information about StorageAccountName.

    .EXAMPLE
        Get-StorageAccountName -SasLink $sasLink
    #>
    [OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[object]$SasLink
	)
	
    $fullSasLink = $SasLink.sasLink
    $fullSasLink -match "https:\/\/(.*).blob.core" | Out-Null
    $storageAccountName = $Matches[1]

    Write-Host "StorageAccountName : $storageAccountName"

    return $storageAccountName
}

function Get-SasToken{
    <#
    .SYNOPSIS
        Get the SasToken from a SAS link.

    .DESCRIPTION
        Get the SasToken from a SAS link.
        The SasLink you will get by using Get-DxpStorageContainerSasLink

    .PARAMETER SasLink
        The SasLink that contain the information about the Sas token.

    .EXAMPLE
        Get-SasToken -SasLink $sasLink
    #>
    [OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[object]$SasLink
	)
	
    $fullSasLink = $SasLink.sasLink
    $fullSasLink -match "(\?.*)" | Out-Null
    $sasToken = $Matches[0]

    if ($null -eq $sasToken -or $sasToken.Length -eq 0) {
        Write-Warning "Did not found container $container in the list. Look in the log and see if your blob container have another name then mysitemedia. If so, specify that name as param -container. Example: Ignore container: projectname-assets. Then set -container 'projectname-assets'"
        exit
    }

    Write-Host "SAS token          : $sasToken"

    return $sasToken
}

function Join-Parts {
    <#
    .SYNOPSIS
        Join parts.

    .DESCRIPTION
        Join parts. Used for creating a URI for example

    .PARAMETER Parts
        Array of string that should be join.

    .PARAMETER Separator
        The separator character that should join the parts.

    .EXAMPLE
        $filePath = Join-Parts -Separator '\' -Parts $DownloadFolder, $blobContent.Name
        Result 'c:\temp\myblob.txt'
    #>
    [OutputType([string])]
    param
    (
        $Parts = $null,
        [string]$Separator = ''
    )

    ($Parts | Where-Object { $_ } | ForEach-Object { ([string]$_) } | Where-Object { $_ } ) -join $Separator 
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

    #$status = Get-EpiDatabaseExport -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Id $ExportId -Environment $Environment -DatabaseName $DatabaseName
    if ($null -ne $status){
        Write-Host "################################################"
        Write-Host "Database export:"
        Write-Host "Status:       $($status.status)"
        Write-Host "BacpacName:   $($status.bacpacName)"
        Write-Host "DownloadLink: $($status.downloadLink)"
    }
    return $status
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
function Import-AzureStorageModule {
    <#
    .SYNOPSIS
        Load module Az.Storage.

    .DESCRIPTION
        Load module Az.Storage.

    .EXAMPLE
        Import-AzureStorageModule

    #>
    $azureModuleLoaded = $false
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
        Write-Host "Az module loaded."
    }
    else {
        Write-Error "'Az.Storage' module is required to run this cmdlet."
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

function Invoke-DownloadStorageAccountFiles{
    <#
    .SYNOPSIS
        Download files from the specified storageaccount and specified container.

    .DESCRIPTION
        Download files from the specified storageaccount and specified container.

    .PARAMETER StorageAccountName
        The storage account name the you want to download from.

    .PARAMETER SasToken
        SAS token needed for the access to the storage account.

    .PARAMETER DownloadFolder
        The folder on disc where you want to download your files.

    .PARAMETER Container
        List of containers that we should look for the one that match the next parameter Container.

    .PARAMETER MaxFilesToDownload
        The max number of files you want to download. 0=All. X=Download X number of files.

    .PARAMETER OverwriteExistingFiles
        True/False if you want to overwrite if there is any existing files in the download folder.

    .EXAMPLE
        Invoke-DownloadStorageAccountFiles -StorageAccountName $StorageAccountName -SasToken $SasToken -DownloadFolder $DownloadFolder -Container $Container -MaxFilesToDownload $MaxFilesToDownload -OverwriteExistingFiles $OverwriteExistingFiles

    .EXAMPLE
        Invoke-DownloadStorageAccountFiles -StorageAccountName "exxxxx012znb5inte" -SasToken "?sv=2017-04-17&sr=c&sig=RqgmOvZM%2BV4HQPAKqCm5KE5PI4ZjbnQqDaQPEQjz6gs%3D&st=2021-03-01T22%3A20%3A26Z&se=2021-03-02T00%3A20%3A26Z&sp=rl" -DownloadFolder "c:\temp" -Container "mysitemedia" -MaxFilesToDownload 100 -OverwriteExistingFiles $false

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SasToken,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Container,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadFolder,

        [Parameter(Mandatory = $false)]
        [int] $MaxFilesToDownload = 0,


        [Parameter(Mandatory = $false)]
        [bool] $OverwriteExistingFiles = $true,

        [Parameter(Mandatory = $false)]
        [int] $RetentionHours = 2

    )
    Write-Host "Invoke-DownloadStorageAccountFiles - Inputs:----"
    Write-Host "StorageAccountName:     $StorageAccountName"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "SasToken:               $SasToken"
    Write-Host "Container:              $Container"
    Write-Host "DownloadFolder:         $DownloadFolder"
    Write-Host "MaxFilesToDownload:     $MaxFilesToDownload"
    Write-Host "OverwriteExistingFiles: $OverwriteExistingFiles"
    Write-Host "RetentionHours:         $RetentionHours"
    Write-Host "------------------------------------------------"

    $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SASToken $SasToken -ErrorAction Stop

    $ArrayList = [System.Collections.ArrayList]::new()

    if ($null -eq $ctx){
        Write-Error "No context. The provided SASToken is not valid."
        exit
    }
    else {
        $blobContents = Get-AzStorageBlob -Container $Container  -Context $ctx | Sort-Object -Property LastModified -Descending

        if ($null -eq $blobContents){
            Write-Host "Can not find any blobs in container $Container :("
            exit
        }
    
        Write-Host "Found $($blobContents.Length) BlobContent."

        if ($blobContents.Length -eq 0) {
            Write-Warning "No blob/files found in the container '$container'"
            exit
        }

        if ($MaxFilesToDownload -eq 0) {
            $MaxFilesToDownload = [int]$blobContents.Length
        }
        $downloadedFiles = 0
        
        Write-Host "---------------------------------------------------"
        foreach($blobContent in $blobContents)  
        {  
            if ($downloadedFiles -ge $MaxFilesToDownload){
                Write-Host "Hit max files to download ($MaxFilesToDownload)"
                break
            }

            $filePath = (Join-Parts -Separator '\' -Parts $DownloadFolder, $blobContent.Name.Replace("/", "\"))
            $fileExist = Test-Path $filePath -PathType Leaf

            if ($fileExist -eq $false -or $true -eq $OverwriteExistingFiles){
                ## Download the blob content 
                Write-Host "Download #$($downloadedFiles + 1) - $($blobContent.Name) $(if ($fileExist -eq $true) {"overwrite"} else {"to"}) $filePath" 
                [void]$ArrayList.Add($filePath)
                $doNothingWithThisInfo = Get-AzStorageBlobContent -Container $Container -Context $ctx -Blob $blobContent.Name -Destination $DownloadFolder -Force -AsJob
                $downloadedFiles++
            } else {
                Write-Host "File exist on disc: $filePath." 
            }

            $procentage = [int](($downloadedFiles / $maxFilesToDownload) * 100)
            Write-Progress -Activity "Download files" -Status "$procentage% complete." -PercentComplete $procentage;
        }
        Write-Progress -Activity "Download files" -Completed;
        Write-Host "---------------------------------------------------"
    }

    return $ArrayList
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
        
# END PRIVATE METHODS

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
        [string] $Environment
    )

    Write-Host "Get-DxpStorageContainers - Inputs:--------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "------------------------------------------------"

    Test-DxpProjectId -ProjectId $ProjectId
    Test-EnvironmentParam -Environment $Environment
    
    #Import-EpiCloud
    Initialize-EpiCload

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
function Invoke-DxpBlobsDownload{
    <#
    .SYNOPSIS
        Download DXP project blobs.

    .DESCRIPTION
        Download DXP project blobs. You can specify the environment where the blobs exist.

    .PARAMETER ClientKey
        Your DXP ClientKey that you can generate in the paas.episerver.net portal.

    .PARAMETER ClientSecret
        Your DXP ClientSecret that you can generate in the paas.episerver.net portal.

    .PARAMETER ProjectId
        The DXP project id that is related to the ClientKey/Secret.

    .PARAMETER Environment
        The environment that holds the blobs that you want to download.

    .PARAMETER DownloadFolder
        The local download folder where you want to download the blob files.

    .PARAMETER MaxFilesToDownload
        The max number of blobs you want to download. 0=All. X=The first X number of blob found in the blobs container. Order by LastModified -Descending

    .PARAMETER Container
        The type of container you want to download. 
        AppLogs=Application logs that is created by your application in the specified environment.
        WebLogs=Web logs/IIS logs that is created by your webapp in the specified environment.
        Blobs or *=The container name where your blobs are stored. At present date (2021-02-02) Optimizely (formerly known as Episerver) have no default or standard name of the blobs container. So the script will try to help you find the right one. If not it will list the containers and you will be able to rerun the script and try which one it is.

    .PARAMETER OverwriteExistingFiles
        True/False if the downloaded files should overwite existing files (if exist).

    .PARAMETER RetentionHours
        The number of hours that the SAS token used for download will be ok. Default is 2 hours. This maybe need to be raised if it take longer then 2 hours to download the files requested to download.

    .EXAMPLE
        Invoke-DxpBlobsDownload -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -DownloadFolder $DownloadFolder -MaxFilesToDownload $MaxFilesToDownload -Container $Container -OverwriteExistingFiles $OverwriteExistingFiles -RetentionHours $RetentionHours

    .EXAMPLE
        Invoke-DxpBlobsDownload -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' -DownloadFolder "c:\temp" -MaxFilesToDownload 100 -Container "mysitemedia" -OverwriteExistingFiles $false -RetentionHours 2

    #>
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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $Environment = "Integration",

        [Parameter(Mandatory=$false)]
        [string] $DownloadFolder = $PSScriptRoot, 

        [Parameter(Mandatory=$false)]
        [int] $MaxFilesToDownload = 0, # 0=All, 100=Max 100 downloads

        [Parameter(Mandatory=$false)]
        [string] $Container = "Blobs",  #AppLogs | WebLogs | Blobs

        [Parameter(Mandatory=$false)]
        [bool] $OverwriteExistingFiles = $true,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 168)]
        [int] $RetentionHours = 2

    )

    Write-Host "Invoke-DxpBlobsDownload - Inputs:-----------------"
    Write-Host "ClientKey:              $ClientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $ProjectId"
    Write-Host "Environment:            $Environment"
    Write-Host "DownloadFolder:         $DownloadFolder"
    Write-Host "MaxFilesToDownload:     $MaxFilesToDownload"
    Write-Host "Container:              $Container"
    Write-Host "OverwriteExistingFiles: $OverwriteExistingFiles"
    Write-Host "RetentionHours:         $RetentionHours"
    Write-Host "------------------------------------------------"

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $ProjectId
    Test-DownloadFolder -DownloadFolder $DownloadFolder
    Test-EnvironmentParam -Environment $Environment

    Import-Az
    Import-EpiCloud

    #Connect-DxpEpiCloud -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId

    $containers = Get-DxpStorageContainers -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment

    $Container = Test-ContainerName -Containers $containers -Container $Container
    #$Container
    
    $sasLink = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $containers -Container $Container -RetentionHours $RetentionHours
    # $sasLink

    $storageAccountName = Get-StorageAccountName -SasLink $sasLink
    $sasToken = Get-SasToken -SasLink $sasLink

    Add-TlsSecurityProtocolSupport
    Import-AzureStorageModule

    $ArrayList = Invoke-DownloadStorageAccountFiles -StorageAccountName $StorageAccountName -SasToken $SasToken -DownloadFolder $DownloadFolder -Container $Container -MaxFilesToDownload $MaxFilesToDownload -OverwriteExistingFiles $OverwriteExistingFiles
    #$files = 
    #Write-Host "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
    #$files | Select-Object -Last 1 | Format-Table
    #$Files | Format-Table
    #Write-Host "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"

    #$Files = $files
    return $ArrayList
}
function Invoke-DxpDatabaseDownload{
    <#
    .SYNOPSIS
        Download DXP project DB.

    .DESCRIPTION
        Download DXP project DB. You can specify the environment from where the database should be exported from.

    .PARAMETER ClientKey
        Your DXP ClientKey that you can generate in the paas.episerver.net portal.

    .PARAMETER ClientSecret
        Your DXP ClientSecret that you can generate in the paas.episerver.net portal.

    .PARAMETER ProjectId
        The DXP project id that is related to the ClientKey/Secret.

    .PARAMETER Environment
        The environment that holds the blobs that you want to download.

    .PARAMETER DatabaseName
        The database you want to download. epicms / epicommerce

    .PARAMETER DownloadFolder
        The local download folder where you want to download the DB backup file.

    .PARAMETER RetentionHours
        The number of hours that the SAS token used for download will be ok. Default is 2 hours. This maybe need to be raised if it take longer then 2 hours to download the files requested to download.

    .PARAMETER Timeout
        The number of seconds that you will let the script run until it will timeout. Default 1800 (ca 30 minutes)

    .EXAMPLE
        Invoke-DxpDatabaseDownload -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -DatabaseName $DatabaseName -DownloadFolder $DownloadFolder -RetentionHours $RetentionHours -Timeout $Timeout

    .EXAMPLE
        Invoke-DxpDatabaseDownload -ClientKey '644b6926-39b1-42a1-93d6-3771cdc4a04e' -ClientSecret '644b6926-39b1fasrehyjtye-42a1-93d6-3771cdc4asasda04e'-ProjectId '644b6926-39b1-42a1-93d6-3771cdc4a04e' -Environment 'Integration' -DatabaseName 'epicms' -DownloadFolder "c:\temp" -RetentionHours 2 -Timeout 1800

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
    Test-EnvironmentParam -Environment $Environment
    Test-DatabaseName -DatabaseName $DatabaseName

    Import-EpiCloud

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
            $filePath = Join-Parts -Separator '\' -Parts $DownloadFolder, $status.bacpacName
            Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath
            Write-Host "Download database to $filePath"
            Write-Host "------------------------------------------------"
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

function Invoke-DxpAwaitStatus{
    <#
    .SYNOPSIS
        Task that await for status AwaitingVerification/Reset.

    .DESCRIPTION
        Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that awaits the correct status. So if target environment is in status InProgress/Resetting when it starts. The task will run and check the status until target environment is in status AwaitingVerification/Reset/Succeeded.\n\nIf status is AwaitingVerification/Reset/Succeeded when task starts, nothing will happen. If the task starts and status is anything else then AwaitingVerification/Reset/Succeeded/InProgress/Resetting the task will fail with error.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpAwaitStatus -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $lastDeploy = Get-DxpLatestEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment

    if ($null -ne $lastDeploy){
        Write-Output $lastDeploy | ConvertTo-Json
        Write-Output "Latest found deploy on targetEnvironment $targetEnvironment is in status $($lastDeploy.status)"

        if ($lastDeploy.status -eq "InProgress" -or $lastDeploy.status -eq "Resetting") {
            $deployDateTime = Get-DxpDateTimeStamp
            $deploymentId = $lastDeploy.id
            Write-Host "Deploy $deploymentId started $deployDateTime."

            $percentComplete = $lastDeploy.percentComplete

            $expectedStatus = ""
            if ($lastDeploy.status -eq "InProgress"){
                $expectedStatus = "AwaitingVerification"
            }
            elseif ($lastDeploy.status -eq "Resetting"){
                $expectedStatus = "Reset"
            }

            $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Deploy $deploymentId ended $deployDateTime"

            if ($status.status -eq "AwaitingVerification") {
                Write-Host "Deployment $deploymentId has been successful."
            }
            elseif ($status.status -eq "Reset") {
                Write-Host "Reset $deploymentId has been successful."
            }
            else {
                Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
                exit 1
            }
        }
        elseif ($lastDeploy.status -eq "AwaitingVerification" -or $lastDeploy.status -eq "Reset" -or $lastDeploy.status -eq "Succeeded") {
            Write-Output "Target environment $targetEnvironment is already in status $($lastDeploy.status). Will and can´t wait for any new status."
        }
        else {
            Write-Warning "Status is in a unhandled status. (Current:$($lastDeploy.status)). Will and can´t do anything..."
            Write-Host "##vso[task.logissue type=error]Status is in a unhandled status. (Current:$($lastDeploy.status))."
            Write-Error "Status is in a unhandled status. (Current:$($lastDeploy.status))." -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Output "No history received from the specified target environment $targetEnvironment"
        Write-Output "Will and can not do anything..."
    }
}

function Invoke-DxpCompleteDeploy{
    <#
    .SYNOPSIS
        Complete deploy in specified environment. Environment status must be in AwaitingVerification status. (Optimizely DXP, former Episerver DXC)

    .DESCRIPTION
        Complete deploy in specified environment. Environment status must be in AwaitingVerification status. (Optimizely DXP, former Episerver DXC)

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpCompleteDeploy -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $deploy = Get-DxpAwaitingEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment
    $deploy
    if (-not $deploy) {
        Write-Host "##vso[task.logissue type=error]Failed to locate a deployment in $targetEnvironment to complete!"
        exit 1
    }
    else {
        $deploymentId = $deploy.id
        Write-Host "Set variable DeploymentId: $deploymentId"
        Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"
    }

    if ($deploymentId.length -gt 1) {
        $completeEpiDeploymentSplat = @{
            ClientKey    = $clientKey
            ClientSecret = $clientSecret
            ProjectId    = $projectId
            Id           = "$deploymentId"
        }

        Write-Host "Start complete deployment $deploymentId"
        $complete = Complete-EpiDeployment @completeEpiDeploymentSplat
        $complete

        if ($complete.status -eq "Completing") {
            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Complete deploy $deploymentId started $deployDateTime."
    
            $percentComplete = $complete.percentComplete
            $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Succeeded" -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Complete deploy $deploymentId ended $deployDateTime"
    
            if ($status.status -eq "Succeeded") {
                Write-Host "Deployment $deploymentId has been completed."
            }
            else {
                Write-Warning "The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
                exit 1
            }
        }
        elseif ($complete.status -eq "Succeeded") {
            Write-Host "The deployment $deploymentId is already in Succeeded status."
        }
        else {
            Write-Warning "Status is not in complete (Current:$($complete.status)). Something is strange..."
            Write-Host "##vso[task.logissue type=error]Status is not in complete (Current:$($complete.status)). Something is strange..."
            Write-Error "Status is not in complete (Current:$($complete.status)). Something is strange..." -ErrorAction Stop
            exit 1
        }

    }
    else {
        Write-Host "##vso[task.logissue type=error]Could not retrieve the DeploymentId variable. Can not complete the deployment."
        exit 1
    }

}

function Invoke-DxpDeployNuGetPackage{
    <#
    .SYNOPSIS
        Optimizely DXP - Deploy NuGet package

    .DESCRIPTION
        Take a NuGet package from your drop folder in Azure DevOps and upload it to your Optimizely (formerly known as Episerver) DXP project and start a deployment to the specified environment.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER PackagePath
        The path to the package to upload. Example: $OctopusParameters["Octopus.Action.Package[sourcepackage].OriginalPath"]

    .PARAMETER DirectDeploy
        Specify if you want to do a direct deploy without using slot and warmup.

    .PARAMETER WarmUpUrl
        Specify if you want to warm-up the web application after direct deploy. It will request the specified URL and all links found on the page. 
        If there is some tests running against the web application with direct deploy there is a problem that the web application is not started and warmed up.

    .PARAMETER UseMaintenancePage
        Specify if you want to use a maintenance page during the deploy.

    .PARAMETER ZeroDowntimeMode
        The type of smooth deployment you want to use. More information about zero downtime mode 
        If this parameter is set to empty, no zero downtime deployment will be made. It will be a regular deployment.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpDeployNuGetPackage -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -PackagePath $PackagePath -DirectDeploy $directDeploy -WarmUpUrl $warmUpUrl -UseMaintenancePage $useMaintenancePage -ZeroDowntimeMode $zeroDowntimeMode -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackagePath,

        [Parameter(Mandatory = $false)]
        [bool] $DirectDeploy,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $WarmUpUrl,

        [Parameter(Mandatory = $false)]
        [bool] $UseMaintenancePage,

        [Parameter(Mandatory = $true)]
        [ValidateSet('NotSpecified','ReadOnly','ReadWrite')]
        [string] $ZeroDowntimeMode,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    [Boolean]$directDeploy = [System.Convert]::ToBoolean($DirectDeploy)
    $warmupThisUrl = $WarmUpUrl
    [Boolean]$useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $timeout = $Timeout
    $zeroDowntimeMode = $ZeroDowntimeMode
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $packagepath = $PackagePath
    Write-Host $packagepath
    $filePath = $packagepath
    $packagename = Split-Path $packagepath -leaf
    Write-Host $packagename

    if ($packagename.Contains(".cms.")){
        $sourceApp = "cms"
    } 
    elseif ($packagename.Contains(".commerce.")) {
        $sourceApp = "commerce"
    }

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "SourceApp:          $sourceApp"
    Write-Host "DirectDeploy:       $directDeploy"
    Write-Host "Warm-up URL:        $warmupThisUrl"
    Write-Host "UseMaintenancePage: $useMaintenancePage"
    Write-Host "FilePath:           $filePath"
    Write-Host "Timeout:            $timeout"
    Write-Host "ZeroDowntimeMode:   $zeroDowntimeMode"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    if (($targetEnvironment -eq "Preproduction" -or $targetEnvironment -eq "Production") -and $directDeploy){
        Write-Host "DirectDeploy does only support target environment = Integration|ADE1|ADE2|ADE3 at the moment. Will set the DirectDeploy=false."
        $directDeploy = $false
    }

    $packageLocation = Get-EpiDeploymentPackageLocation -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId
    Write-Host "PackageLocation:    $packageLocation"

    $uploadedPackage = $null
    $myPackages = $null

    $uploadedPackage = Publish-Package -FilePath $filePath -PackageLocation $packageLocation
    if ($uploadedPackage){
        $myPackages = $uploadedPackage
    }

    if ($null -eq $zeroDowntimeMode -or $zeroDowntimeMode -eq "" -or $zeroDowntimeMode -eq "NotSpecified" -or $zeroDowntimeMode -eq "NotApplicable") {
        $startEpiDeploymentSplat = @{
            ClientKey          = $ClientKey
            ClientSecret       = $ClientSecret
            DeploymentPackage  = $myPackages
            ProjectId          = $projectId
            TargetEnvironment  = $targetEnvironment
            UseMaintenancePage = $useMaintenancePage
        }
    } else {
        $startEpiDeploymentSplat = @{
            ClientKey          = $ClientKey
            ClientSecret       = $ClientSecret
            DeploymentPackage  = $myPackages
            ProjectId          = $projectId
            TargetEnvironment  = $targetEnvironment
            UseMaintenancePage = $useMaintenancePage
            ZeroDowntimeMode   = $zeroDowntimeMode
        }
    }


    if ($true -eq $directDeploy){
        $expectedStatus = "Succeeded"
        $deploy = Start-EpiDeployment @startEpiDeploymentSplat -DirectDeploy
    } else {
        $expectedStatus = "AwaitingVerification"
        $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    }
    $deploy

    $deploymentId = $deploy.id

    if ($deploy.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId started $deployDateTime."

        $percentComplete = $deploy.percentComplete

        $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId ended $deployDateTime"

        if ($status.status -eq $expectedStatus) {
            Write-Host "Deployment $deploymentId has been successful."

            if ($true -eq $directDeploy -and $null -ne $warmupThisUrl -and $warmupThisUrl.length -gt 0){ #Warmup when direct deploy.
                Invoke-WarmupSite $warmupThisUrl
            }
        }
        else {
            #Send-BenchmarkInfo "Bad deploy/Time out"
            Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        #Send-BenchmarkInfo "Unhandled status"
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploymentId"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"
}

function Invoke-DxpDeployTo{
    <#
    .SYNOPSIS
        Optimizely DXP - Deploy to

    .DESCRIPTION
        Start move DXP deploy from source environment to target environment. Like clicking on the 'Deploy To' button in PAAS. (Optimizely DXP, former Episerver DXC)

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER SourceEnvironment
        Specify from which environment you want to take the source code/package.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER SourceApp
        Specify which type of application you want to move. (When use syncdown, this param has no effect. Will sync all databases.)

    .PARAMETER UseMaintenancePage
        Specify if you want to use a maintenance page during the deploy.

    .PARAMETER IncludeBlob
        If BLOBs should be copied from source environment to the target environment.

    .PARAMETER IncludeDb
        If DBs should be copied from source environment to the target environment.

    .PARAMETER ZeroDowntimeMode
        The type of smooth deployment you want to use. More information about zero downtime mode 
        If this parameter is set to empty, no zero downtime deployment will be made. It will be a regular deployment.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpDeployTo -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -SourceEnvironment $sourceEnvironment -TargetEnvironment $targetEnvironment -SourceApp $sourceApp -UseMaintenancePage $useMaintenancePage -IncludeBlob $includeBlob -IncludeDb $includeDb -ZeroDowntimeMode $zeroDowntimeMode -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $SourceEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateSet('cms','commerce','cms,commerce')]
        [string] $SourceApp,

        [Parameter(Mandatory = $false)]
        [bool] $UseMaintenancePage,

        [Parameter(Mandatory = $false)]
        [bool] $IncludeBlob,

        [Parameter(Mandatory = $false)]
        [bool] $IncludeDb,

        [Parameter(Mandatory = $true)]
        [ValidateSet('NotSpecified','ReadOnly','ReadWrite')]
        [string] $ZeroDowntimeMode,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $sourceEnvironment = $SourceEnvironment
    $targetEnvironment = $TargetEnvironment
    $sourceApp = $SourceApp
    [Boolean]$useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $timeout = $Timeout
    [Boolean]$includeBlob = [System.Convert]::ToBoolean($IncludeBlob)
    [Boolean]$includeDb = [System.Convert]::ToBoolean($IncludeDb)
    $zeroDowntimeMode = $ZeroDowntimeMode
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "SourceEnvironment:  $sourceEnvironment"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "SourceApp:          $sourceApp"
    Write-Host "UseMaintenancePage: $useMaintenancePage"
    Write-Host "Timeout:            $timeout"
    Write-Host "IncludeBlob:        $includeBlob"
    Write-Host "IncludeDb:          $includeDb"
    Write-Host "ZeroDowntimeMode:   $zeroDowntimeMode"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $sourceApps = $sourceApp.Split(",")

    if ($null -eq $zeroDowntimeMode -or $zeroDowntimeMode -eq "" -or $zeroDowntimeMode -eq "NotSpecified") {
        $startEpiDeploymentSplat = @{
            ClientKey          = $ClientKey
            ClientSecret       = $ClientSecret
            ProjectId          = $projectId
            SourceEnvironment  = $sourceEnvironment
            TargetEnvironment  = $targetEnvironment
            SourceApp          = $sourceApps
            UseMaintenancePage = $useMaintenancePage
            IncludeBlob = $includeBlob
            IncludeDb = $includeDb
        }
    } else {
        $startEpiDeploymentSplat = @{
            ClientKey          = $ClientKey
            ClientSecret       = $ClientSecret
            ProjectId          = $projectId
            SourceEnvironment  = $sourceEnvironment
            TargetEnvironment  = $targetEnvironment
            SourceApp          = $sourceApps
            UseMaintenancePage = $useMaintenancePage
            IncludeBlob = $includeBlob
            IncludeDb = $includeDb
            ZeroDowntimeMode = $zeroDowntimeMode
        }
    }

    $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    $deploy

    $deploymentId = $deploy.id

    if ($deploy.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId started $deployDateTime."
        $percentComplete = $deploy.percentComplete
        $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "AwaitingVerification" -Timeout $timeout

        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId ended $deployDateTime"

        if ($status.status -eq "AwaitingVerification") {
            Write-Host "Deployment $deploymentId has been successful."
        }
        else {
            Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploymentId"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"
}

function Invoke-DxpExpectStatus{
    <#
    .SYNOPSIS
        Optimizely DXP - Expect status

    .DESCRIPTION
        Task that check the status for an environment. if environment is not in the expected status the task will fail.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER ExpectedStatus
        Specify the status that you expect the environment to have.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpExpectStatus -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -ExpectedStatus $expectedStatus -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AwaitingVerification','InProgress','Resetting','Reset','Succeeded','SucceededOrReset')]
        [string] $ExpectedStatus,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $expectedStatus = $ExpectedStatus
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)


    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "ExpectedStatus:     $expectedStatus"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $lastDeploy = Get-DxpLatestEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment

    if ($null -ne $lastDeploy){
        Write-Output $lastDeploy | ConvertTo-Json
        Write-Output "Latest found deploy on targetEnvironment $targetEnvironment is in status $($lastDeploy.status)"

        $inExpectedStatus = $false
        if ($lastDeploy.status -eq $expectedStatus) {
            $inExpectedStatus = $true
        }
        elseif ($expectedStatus -eq "SucceededOrReset") {
            if ($lastDeploy.status -eq "Succeeded" -or $lastDeploy.status -eq "Reset") {
                $inExpectedStatus = $true
            }
        }

        if ($true -eq $inExpectedStatus) {
            Write-Host "Status is as expected."
        }
        else {
            Write-Warning "$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))."
            Write-Host "##vso[task.logissue type=error]$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))."
            Write-Error "$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))." -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Output "No history received from the specified target environment $targetEnvironment"
        Write-Output "Will and can not do anything..."
    }
}

function Invoke-DxpResetDeploy{
    <#
    .SYNOPSIS
        Optimizely DXP - Reset deploy

    .DESCRIPTION
        Reset a specifed environment if the status for the environment is in status 'AwaitingVerification'.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        The target environment where we should check and wait for the correct status.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpResetDeploy -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $deploy = Get-DxpAwaitingEnvironmentDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment
    $deploy
    $deploymentId = ""
    if (-not $deploy) {
        Write-Output "Environment $targetEnvironment is not in status AwaitingVerification. We do not need to reset this environment."
        $deploymentId = ""
    }
    else {
        Write-Output "Environment $targetEnvironment is in status AwaitingVerification. We will start to reset this environment ASAP."
        $deploymentId = $deploy.id
    }

    #Start check if we should reset this environment.
    if ($deploymentId.length -gt 1) {


        $status = Get-EpiDeployment -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $projectId -Id $deploymentId
        $status

        if ($status.status -eq "AwaitingVerification") {
            $deployDateTime = Get-DxpDateTimeStamp
    
            Write-Host "Start Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId ($deployDateTime)"
            Reset-EpiDeployment -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $projectId -Id $deploymentId

            $percentComplete = $status.percentComplete
            $status = Invoke-DxpProgress -ClientKey $ClientKey -ClientSecret $ClientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Reset" -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Reset $deploymentId ended $deployDateTime"
    
            if ($status.status -eq "Reset") {
                Write-Host "Deployment $deploymentId has been successfuly reset."
            }
            else {
                Write-Warning "The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
                exit 1
            }
        }
        elseif ($status.status -eq "Reset") {
            Write-Host "The deployment $deploymentId is already in reset status."
        }
        else {
            Write-Warning "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
            Write-Host "##vso[task.logissue type=error]Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
            Write-Error "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment." -ErrorAction Stop
            exit 1
        }
    }
}

function Invoke-DxpSmokeTestIfFailReset{
    <#
    .SYNOPSIS
        Optimizely DXP - Smoke test if fail reset

    .DESCRIPTION
        This task smoke test a slot and decide if we should continue the release, or reset the environment slot, because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).\n\nA new property with the name \"Reset on fail\" is added that describes if the task will reset when smoke test fail. This can be used when you want to use SmokeTestIfFailReset task when doing a ContentSync.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the DXP project.

    .PARAMETER TargetEnvironment
        Specify which environment that you want to check ex Integration/Preproduction/Production.

    .PARAMETER Urls
        Specify the URLs that will be used in the smoke test. Use ',' as delimiter between the URLs.

    .PARAMETER ResetOnFail
        If checked it will reset the deployment if smoke test fails. If not checked, only a warning will be posted but no reset. Can be used when you want to use SmokeTestIfFailReset task when doing a ContentSync.

    .PARAMETER SleepBeforeStart
        The sleep time before the script will start to test the URL(s). Most of the time the slot need some extra time to get up and runing. Even if the status says that it is up and runing. But after alot of tests we think that 20 seconds should be enough.

    .PARAMETER NumberOfRetries
        The number of retries that the script will make before return error and reset the deployment.

    .PARAMETER SleepBeforeRetry
        The sleep time before the script will start to test the URL(s) again. This will only happend if the HTTP status response from one/many of the URLs is not responding with HTTP status 200.

    .PARAMETER Timeout
        Specify the number of seconds when the task should timeout.

    .PARAMETER RunVerbose
        If you want to run in verbose mode and see all information.

    .EXAMPLE
        Invoke-DxpSmokeTestIfFailReset -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -Urls $urls -ResetOnFail $resetOnFail -SleepBeforeStart $sleepBeforeStart -NumberOfRetries $numberOfRetries -SleepBeforeRetry $sleepBeforeRetry -Timeout $timeout -RunVerbose $runVerbose

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
        [ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
        [string] $TargetEnvironment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Urls,

        [Parameter(Mandatory = $false)]
        [bool] $ResetOnFail,

        [Parameter(Mandatory = $false)]
        [int] $SleepBeforeStart,

        [Parameter(Mandatory = $false)]
        [int] $NumberOfRetries,

        [Parameter(Mandatory = $false)]
        [int] $SleepBeforeRetry,

        [Parameter(Mandatory = $false)]
        [int] $Timeout,

        [Parameter(Mandatory = $false)]
        [bool] $RunVerbose

    )

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $urls = $Urls
    [Boolean]$resetOnFail = [System.Convert]::ToBoolean($ResetOnFail)
    $sleepBeforeStart = $SleepBeforeStart
    $retries = $NumberOfRetries
    $sleepBeforeRetry = $SleepBeforeRetry
    $timeout = $Timeout
    $runBenchmark = [System.Convert]::ToBoolean($RunBenchmark)
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $global:ErrorActionPreference = $errorAction
    ####################################################################################

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    Add-TlsSecurityProtocolSupport

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Urls:               $urls"
    Write-Host "ResetOnFail:        $resetOnFail"
    Write-Host "SleepBeforeStart:   $sleepBeforeStart"
    Write-Host "NumberOfRetries:    $retries"
    Write-Host "SleepBeforeRetry:   $sleepBeforeRetry"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    Write-Host "ErrorActionPref:    $($global:ErrorActionPreference)"

    Write-Host "Start sleep for $($sleepBeforeStart) seconds before we start check URL(s)."
    Start-Sleep $sleepBeforeStart

    $urlsArray = "$urls" -split ','
    Write-Host "Start smoketest $urls"
    $numberOfErrors = 0
    $numberOfRetries = 0
    $retry = $true
    while ($retries -ge $numberOfRetries -and $retry -eq $true){
        $retry = $false
        for ($i = 0; $i -le $urlsArray.Length - 1; $i++) {
            $sw = [Diagnostics.StopWatch]::StartNew()
            $sw.Start()
            $uri = $urlsArray[$i]
            Write-Output "Executing request for URI $uri"
            try {
                $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -Verbose:$false -MaximumRedirection 0
                $sw.Stop()
                $statusCode = $response.StatusCode
                $seconds = $sw.Elapsed.TotalSeconds
                if ($statusCode -eq 200) {
                    $statusDescription = $response.StatusDescription
                    Write-Output "##[ok] $uri => Status: $statusCode $statusDescription in $seconds seconds"
                }
                else {
                    Write-Output "##[warning] $uri => Error $statusCode after $seconds seconds"
                    Write-Output "##vso[task.logissue type=warning;] $uri => Error $statusCode after $seconds seconds"
                    $numberOfErrors = $numberOfErrors + 1
                }
            }
            catch {
                $sw.Stop()
                $errorMessage = $_.Exception.Message
                $seconds = $sw.Elapsed.TotalSeconds
                Write-Output "##vso[task.logissue type=warning;] $uri => Error after $seconds seconds: $errorMessage "
                $numberOfErrors = $numberOfErrors + 1
            }
        }
        
        if ($numberOfErrors -gt 0 -and $numberOfRetries -lt $retries) {
            Write-Host "We found ERRORS. But we will retry in $sleepBeforeRetry seconds."
            $numberOfErrors = 0
            Start-Sleep $sleepBeforeRetry
            $retry = $true
            $numberOfRetries++
        }
    }

    if ($numberOfErrors -gt 0) {
        Write-Host "We found ERRORS. Smoketest fails. We will set reset flag to TRUE."
        Write-Host "##vso[task.setvariable variable=ResetDeployment;]true"
        $resetDeployment = $true
    }
    else {
        Write-Host "We found no errors. Smoketest success. We will set reset flag to false."
        Write-Host "##vso[task.setvariable variable=ResetDeployment;]false"
        $resetDeployment = $false
    }

    if ($resetOnFail -eq $false -and $resetDeployment -eq $true) {
        Write-Output "##vso[task.logissue type=warning;] Smoke test failed. But ResetOnFail is set to false. No reset will be made."
    } 
    elseif ($resetDeployment -eq $true) {

        Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

        $getEpiDeploymentSplat = @{
                ClientKey    = $ClientKey
                ClientSecret = $ClientSecret
                ProjectId    = $projectId
        }

        $deploy = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $targetEnvironment }
        $deploy
        $deploymentId = ""
        if (-not $deploy) {
            Write-Output "Environment $targetEnvironment is not in status AwaitingVerification. We do not need to reset this environment."
        }
        else {
            $deploymentId = $deploy.id
        }

        #Start check if we should reset this environment.
        if ($deploymentId.length -gt 1) {


            $status = Get-EpiDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Id $deploymentId
            $status

            if ($status.status -eq "AwaitingVerification") {

                Write-Host "Start Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId"
                Reset-EpiDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Id $deploymentId

                $percentComplete = $status.percentComplete
                $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Reset" -Timeout $timeout

                if ($status.status -eq "Reset") {
                    Write-Host "Deployment $deploymentId has been successfuly reset."
                    Write-Host "##vso[task.logissue type=error]Deployment $deploymentId has been successfuly reset. But we can not continue deploy when we have reset the deployment."
                    Write-Error "Deployment $deploymentId has been successfuly reset. But we can not continue deploy when we have reset the deployment." -ErrorAction Stop
                    exit 1
                }
                else {
                    Write-Warning "The reset has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                    Write-Host "##vso[task.logissue type=error]The reset has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                    Write-Error "Deployment $deploymentId has NOT been successfuly reset or the script has timedout. CurrentStatus: $($status.status)" -ErrorAction Stop
                    exit 1
                }
            }
            elseif ($status.status -eq "Reset") {
                Write-Host "The deployment $deploymentId is already in reset status."
                Write-Host "##vso[task.logissue type=error]Deployment $deploymentId is already in reset status. But we can not continue deploy when we have found errors in the smoke test."
                Write-Error "Deployment $deploymentId is already in reset status. But we can not continue deploy when we have found errors in the smoke test." -ErrorAction Stop
                exit 1
            }
            else {
                Write-Host "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
                Write-Host "##vso[task.logissue type=error]Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
                Write-Error "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment." -ErrorAction Stop
                exit 1
            }
        }
    }
    else {
        Write-Host "The deployment will not be reset. Smoketest is success."
    }
}

Export-ModuleMember -Function @( 'Invoke-DxpBlobsDownload', 'Invoke-DxpDatabaseDownload', 'Get-DxpStorageContainers', 'Get-DxpStorageContainerSasLink', 'Invoke-DxpAwaitStatus', 'Invoke-DxpCompleteDeploy', 'Invoke-DxpDeployNuGetPackage', 'Invoke-DxpDeployTo', 'Invoke-DxpExpectStatus', 'Invoke-DxpResetDeploy', 'Invoke-DxpSmokeTestIfFailReset' )