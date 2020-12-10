[CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $clientKey = "",
        [Parameter(Mandatory=$false)]
        [string] $clientSecret = "",
        [Parameter(Mandatory=$false)]
        [string] $projectId = "",
        [Parameter(Mandatory=$false)]
        [string] $environment = "Integration", #Integration | Preproduction | Production
        [Parameter(Mandatory=$false)]
        [string] $databaseName = "epicms", #epicms | epicommerce
        [Parameter(Mandatory=$false)]
        [string] $downloadFolder = "d:\downloads",
        [Parameter(Mandatory=$false)]
        [int] $maxFilesToDownload = 0, # 0=All, 100=Max 100 downloads
        [Parameter(Mandatory=$false)]
        [string] $container = "Blobs",  #AppLogs | WebLogs | Blobs
        [Parameter(Mandatory=$false)]
        [bool] $overwriteExistingFiles = $true,
        [Parameter(Mandatory=$false)]
        [int] $retentionHours = 24,
        [Parameter(Mandatory=$false)]
        [int] $timeout = 1800
)

####################################################################################

function Test-IsGuid() {
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

function WriteInfo() {
    $version = Get-Host | Select-Object Version
    Write-Host $version
}

function ImportAzureStorageModule {
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

function AddTlsSecurityProtocolSupport {
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

function Join-Parts {
    param
    (
        $Parts = $null,
        $Separator = ''
    )

    ($Parts | Where-Object { $_ } | ForEach-Object { ([string]$_).trim($Separator) } | Where-Object { $_ } ) -join $Separator 
}

function GetDateTimeStamp{
    $dateTimeNow = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    return $dateTimeNow
}

function GetFileDateTimeStamp{
    $dateTimeNow = Get-Date -Format "yyyyMMddTHHmm"
    return $dateTimeNow
}

function ExportProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $exportId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $environment,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $databaseName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $expectedStatus,
        [Parameter(Mandatory = $true)]
        [int] $timeout
    )
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    $currentStatus = ""
    $iterator = 0
    while ($currentStatus -ne $expectedStatus) {
        $status = Get-EpiDatabaseExport -projectId $projectId -id $exportId -environment $environment -databaseName $databaseName
        $currentStatus = $status.status
        if ($iterator % 6 -eq 0) {
            Write-Host "Database backup status: $($currentStatus). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($currentStatus -ne $expectedStatus) {
            Start-Sleep 10
        }
        if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
        if ($currentStatus -eq $expectedStatus) { break }
        $iterator++
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDatabaseExport -projectId $projectId -id $exportId -environment $environment -databaseName $databaseName
    Write-Host "################################################"
    Write-Host "Database export:"
    Write-Host "Status:       $($status.status)"
    Write-Host "BacpacName:   $($status.bacpacName)"
    Write-Host "DownloadLink: $($status.downloadLink)"
    return $status
}

    ####################################################################################
    Write-Host "################################################"
    Write-Host "Inputs:"
    Write-Host "ClientKey:              $clientKey"
    Write-Host "ClientSecret:           **** (it is a secret...)"
    Write-Host "ProjectId:              $projectId"
    Write-Host "Environment:            $environment"
    Write-Host "DatabaseName:           $databaseName"
    Write-Host "DownloadFolder:         $downloadFolder"
    Write-Host "MaxFilesToDownload:     $maxFilesToDownload"
    Write-Host "Container:              $container"
    Write-Host "OverwriteExistingFiles: $overwriteExistingFiles"
    Write-Host "RetentionHours:         $retentionHours"
    Write-Host "Timeout:                $timeout"
    Write-Host "################################################"

    WriteInfo

    #Check values/params #####################################################
    if ((Test-IsGuid -ObjectGuid $projectId) -ne $true){
        Write-Error "The provided ProjectId is not a guid value."
        exit
    }

    if ((Test-Path $downloadFolder -PathType Container) -eq $false) {
        Write-Error "Download folder $downloadFolder does not exist."
        exit
    }

    if ($environment -eq "Integration" -or $environment -eq "Preproduction" -or $environment -eq "Production") {
        Write-Host "Environment param ok."
    }
    else {
        Write-Error "The environment $environment that you have specified does not exist. Ok environments: Integration | Preproduction | Production"
        exit
    }

    if ($container -eq "AppLogs"){
        $container = "azure-application-logs"
    } elseif ($container -eq "WebLogs"){
        $container = "azure-web-logs"
    } elseif ($container -eq "Blobs"){
        $container = "mysitemedia"
    }
    
    if ($databaseName -eq "epicms" -or $databaseName -eq "epicommerce") {
        Write-Host "DatabaseName param ok."
    }
    else {
        Write-Error "The database $databaseName that you have specified is not valid. Ok databaseName: epicms | epicommerce"
        exit
    } 

    if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
        Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
            'Az modules installed at the same time is not supported.')
    } else {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Install-Module EpiCloud -Scope CurrentUser -Force
    }
    ####################################################################################


    try {
        Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret
    }
    catch {
        Write-Error "Could not connect to EpiCload API with specified ClientKey/ClientSecret"
        exit
    }

    # Start download database. Then download blobs. After downloaded blobs we will check again if the bakpac file is ready to download.
    
    $exportDatabaseSplat = @{
        ProjectId      = $projectId
        Environment    = $environment
        DatabaseName   = $databaseName
        RetentionHours = $retentionHours
    }

    $export = Start-EpiDatabaseExport @exportDatabaseSplat
    Write-Host "################################################"
    Write-Host "Database export has started:"
    Write-Host "Id:           $($export.id)"
    Write-Host "ProjectId:    $($export.projectId)"
    Write-Host "DatabaseName: $($export.databaseName)"
    Write-Host "Environment:  $($export.environment)"
    Write-Host "Status:       $($export.status)"

    $exportId = $export.id 

    if ($export.status -eq "InProgress") {
        $deployDateTime = GetDateTimeStamp
        Write-Host "Export $exportId started $deployDateTime."
    } else {
        Write-Error "Status is not in InProgress (Current:$($export.status)). You can not export database at this moment."
        exit
    }
    ####################################################################################
    
    $storageContainerSplat = @{
        ProjectId   = $projectId
        Environment = $environment
    }

    Write-Host "################################################"
    try {
        $containerResult = Get-EpiStorageContainer @storageContainerSplat
    }
    catch {
        Write-Error "Could not get storage container information from Epi. Make sure you have specified correct ProjectId/Environment"
        exit
    }
  
    if ($null -eq $containerResult){
        Write-Error "Could not get Epi DXP storage containers. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    if ($false -eq $containerResult.storageContainers.Contains($container))
    {
        Write-Host "Containers does not contain $container. Will try to figure out the correct one."
        Write-Host "Found the following containers for your project:"
        Write-Host "---------------------------------------------------"
        foreach ($tempContainer in $containerResult.storageContainers){
            Write-Host "$tempContainer"
        }
        Write-Host "---------------------------------------------------"
        if ($container -eq "mysitemedia" -and $containerResult.storageContainers.Length -eq 3) {
            $exclude = @("azure-application-logs", "azure-web-logs")
            $lastContainer = $containerResult.storageContainers | Where-Object { $_ -notin $exclude }
            if ($lastContainer.Length -ne 0) {
                $container = $lastContainer
                Write-Host "Found '$container' and going to use that as the blob container."
            } else {
                Write-Host "After trying to figure out which is the blob container. We still can not find it."
                Write-Error "Expected blob container '$container' but we can not find it. Check the specified container above and try to specify one of them."
                exit
            }
        } else {
            if ($container -eq "azure-application-logs" -or $container -eq "azure-web-logs"){
                Write-Error "Expected log container '$container' but we could not find it."
            } else {
                Write-Error "Expected container '$container' but we can not find it. Check the found containers above and try to specify one of them as param -container."
            }
            exit
        }
    }


    $linkSplat = @{
        ProjectId          = $projectId
        Environment = $environment
        StorageContainer = $containerResult.storageContainers
        RetentionHours = $retentionHours
    }

    $linkResult = Get-EpiStorageContainerSasLink @linkSplat

    foreach ($link in $linkResult){
        if ($link.containerName -eq $container) {
            
            Write-Host "Sas link           : $($link.sasLink)"

            $fullSasLink = $link.sasLink
            $fullSasLink -match "https:\/\/(.*).blob.core" | Out-Null
            $storageAccountName = $Matches[1]
            Write-Host "StorageAccountName : $storageAccountName"

            $fullSasLink -match "(\?.*)" | Out-Null
            $sasToken = $Matches[0]
            Write-Host "SAS token          : $sasToken"
        } else {
            Write-Host "Ignore container   : $($link.containerName)"
        }
    }
    
    if ($null -eq $sasToken -or $sasToken.Length -eq 0) {
        Write-Warning "Did not found container $container in the list. Look in the log and see if your blob container have another name then mysitemedia. If so, specify that name as param -container. Example: Ignore container: projectname-assets. Then set -container 'projectname-assets'"
        exit
    }


AddTlsSecurityProtocolSupport

ImportAzureStorageModule

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SASToken $sasToken -ErrorAction Stop

if ($null -eq $ctx){
    Write-Error "No context. The provided SASToken is not valid."
    exit
}
else {
    $blobContents = Get-AzStorageBlob -Container $container  -Context $ctx | Sort-Object -Property LastModified -Descending

    Write-Host "Found $($blobContents.Length) BlobContent."

    if ($blobContents.Length -eq 0) {
        Write-Warning "No blob/files found in the container '$container'"
        exit
    }

    if ($maxFilesToDownload -eq 0) {
        $maxFilesToDownload = [int]$blobContents.Length
    }
    $downloadedFiles = 0
    Write-Host "---------------------------------------------------"
    foreach($blobContent in $blobContents)  
    {  
        if ($downloadedFiles -ge $maxFilesToDownload){
            Write-Host "Hit max files to download ($maxFilesToDownload)"
            break
        }

       $filePath = Join-Parts -Separator '\' -Parts $downloadFolder, $blobContent.Name
       $fileExist = Test-Path $filePath -PathType Leaf

       if ($fileExist -eq $false -or $true -eq $overwriteExistingFiles){
            ## Download the blob content 
            Write-Host "Download #$($downloadedFiles + 1) - $($blobContent.Name) $(if ($fileExist -eq $true) {"overwrite"} else {"to"}) $filePath" 
            Get-AzStorageBlobContent -Container $container  -Context $ctx -Blob $blobContent.Name -Destination $downloadFolder -Force  
            $downloadedFiles++
       }
       else
       {
            Write-Host "File exist on disc: $filePath." 
       }

        $procentage = [int](($downloadedFiles / $maxFilesToDownload) * 100)
        Write-Progress -Activity "Download files" -Status "$procentage% Complete:" -PercentComplete $procentage;
    }
    Write-Host "---------------------------------------------------"
}

####################################################################################

    Write-Host "Continue to check how it goes for the database export."

    if ($export.status -eq "InProgress" -or $status.status -eq "Succeeded") {
        $status = ExportProgress -projectid $projectId -exportId $exportId -environment $environment -databaseName $databaseName -expectedStatus "Succeeded" -timeout $timeout

        $deployDateTime = GetDateTimeStamp
        Write-Host "Export $exportId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Database export $exportId has been successful."
            Write-Host "Start download database $($status.downloadLink)"
            $filePath = Join-Parts -Separator '\' -Parts $downloadFolder, $status.bacpacName
            Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath
            Write-Host "Download database to $filePath"
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
    ####################################################################################

    Write-Host "---THE END---"