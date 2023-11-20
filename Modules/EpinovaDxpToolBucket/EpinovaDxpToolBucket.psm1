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

Export-ModuleMember -Function @( 'Invoke-DxpBlobsDownload', 'Invoke-DxpDatabaseDownload', 'Get-DxpStorageContainers', 'Get-DxpStorageContainerSasLink', 'Invoke-DxpAwaitStatus' )