function AddAzStorageBlob {
    <#
    .SYNOPSIS
    This helper function uploads a blob to blob storage using azure storage DLL

    .DESCRIPTION
    This helper function uploads a blob to blob storage using azure storage DLL

    .PARAMETER SasUri
    The Sas link contains access to storage account.

    .PARAMETER Path
    The file name with full path.

    .PARAMETER BlobName
    The name of Blob in the container.

    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [Uri] $SasUri,

        [Parameter(Mandatory = $true)]
        [String] $Path,

        [Parameter(Mandatory = $true)]
        [String] $BlobName
    )

    $containerClient = New-Object "Azure.Storage.Blobs.BlobContainerClient" -ArgumentList $SasUri
    $blobClient = $containerClient.GetBlobClient($BlobName)
    $uploadOptions = New-Object "Azure.Storage.Blobs.Models.BlobUploadOptions"
    $filePath = Resolve-Path -Path $Path

    $storageTransferOptions = New-Object "Azure.Storage.StorageTransferOptions"
    $storageTransferOptions.InitialTransferSize = 1024*1024*8
    $storageTransferOptions.MaximumTransferSize = 1024*1024*8
    $uploadOptions.TransferOptions = $storageTransferOptions

    $uploadResult = $blobClient.Upload($filePath, $uploadOptions)
    $response = $uploadResult.GetRawResponse()

    $responseOk = ($response.Status -ge 200) -and ($response.Status -lt 300)

    Write-Output [PSCustomObject] @{
        Status = $response.Status
        ReasonPhrase = $response.ReasonPhrase
        IsSuccessful = $responseOk
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
function GetApiErrorResponse {
    <#
    .SYNOPSIS
    This helper function retrieves the returned error message from the API

    .DESCRIPTION
    This helper function retrieves the returned error message from the API

    Because of the way Invoke-RestMethod works, the error message would
    otherwise be "hidden" and only the http code would be returned

    #>

    [CmdletBinding()]
    [OutputType([String])]
    param(
        $ExceptionResponse
    )

    try {
        $errorResponseStream = $ExceptionResponse.GetResponseStream()
        $errorResponseStreamReader = New-Object System.IO.StreamReader($errorResponseStream)
        $errorResponseStreamReader.BaseStream.Position = 0
        $errorResponseStreamReader.DiscardBufferedData()
        $errorResponse = $errorResponseStreamReader.ReadToEnd()

        $errorResponse
    }
    catch {
        $ExceptionResponse
    }
}
function GetApiObjectEncoded {
    <#
    .SYNOPSIS
    This helper function converts the responses from the API
    so the encoding is correct

    .DESCRIPTION
    This helper function converts the responses from the API
    so the encoding is correct

    (Related to an encoding bug in Invoke-RestMethod)

    #>

    [CmdletBinding(DefaultParameterSetName='Response')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Response')]
        [System.Object[]] $ApiObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'Payload')]
        [System.Object[]] $RequestPayload
    )

    $utf8 = [System.Text.Encoding]::GetEncoding(65001)
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1

    if ($ApiObject) {
        $SerializedObject = ConvertTo-Json -Depth 10 -InputObject $ApiObject -Compress
        $bytesArray = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($SerializedObject))
    }
    else {
        $SerializedObject = ConvertTo-Json -Depth 10 -InputObject $RequestPayload -Compress
        $bytesArray = [System.Text.Encoding]::Convert($iso88591, $utf8, $utf8.GetBytes($SerializedObject))
    }

    # Write the first results to the pipline
    $EncodedJsonString = $utf8.GetString($bytesArray)

    $EncodedObject = ConvertFrom-Json -InputObject $EncodedJsonString
    Write-Output $EncodedObject
}
function GetApiRequestSplattingHash {
    <#
    .SYNOPSIS
    This helper function creates a hashtable containing the basic properties needed
    to use the REST-api

    .DESCRIPTION
    This helper function creates a hashtable containing the basic properties needed
    to use the REST-api. Other properties will need to be added for most calls but
    that will be handled in the respective functions for those methods.

    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [String] $UriEnding,

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'Default',
            'Delete',
            'Get',
            'Head',
            'Merge',
            'Options',
            'Patch',
            'Post',
            'Put',
            'Trace'
        )]
        [String] $Method = 'Get'
    )

    if ($Global:EpiCloudApiEndpointUri) {
        $apiEndpoint = $Global:EpiCloudApiEndpointUri
    }
    else {
        $apiEndpoint = 'https://paasportal.episerver.net/api/v1.0/'
    }

    $hashToReturn = @{
        Headers     = @{
            Authorization = ''
        }
        Uri         = $apiEndpoint + $UriEnding
        ContentType = 'application/json'
        Method      = $Method
        ErrorAction = 'Stop'
        TimeoutSec  = 120
        Verbose     = $false
    }

    $hashToReturn
}
<#
    Initialization code required when importing EpiCloud module.
#>

$dllPath = $PSScriptRoot
$dllFiles = (Get-ChildItem -Path $dllPath -Filter "*.dll").FullName
if ($dllFiles.Count -eq 0) {
    $dllPath = (Get-Item -Path $dllPath).Parent.FullName
    $dllFiles = (Get-ChildItem -Path $dllPath -Filter "*.dll").FullName
}

$dllFileString = $( ($dllFiles | ForEach-Object { "@`"$_`"" } ) -join ", " )

$epiCloudAssemblyResolver = "
using System;
using System.Collections.Generic;
using System.Reflection;

public static class EpiCloudAssemblyResolver
{
    private static readonly Dictionary<string,Assembly> _localAssemblies = new Dictionary<string,Assembly>();

    public static void Initialize()
    {
        var dllFiles = new[] { $dllFileString };
        foreach (var dllFile in dllFiles)
        {
            var assembly = Assembly.LoadFrom(dllFile);
            if (!_localAssemblies.ContainsKey(assembly.GetName().Name))
                _localAssemblies.Add(assembly.GetName().Name, assembly);
        }

        AppDomain.CurrentDomain.AssemblyResolve += OnAssemblyResolve;
    }

    public static Assembly OnAssemblyResolve(object s, ResolveEventArgs e)
    {
        var assemblyName = e.Name;
        var assemblyCommaPosition = assemblyName.IndexOf("","", StringComparison.InvariantCulture);
        if (assemblyCommaPosition > -1) assemblyName = assemblyName.Substring (0, assemblyCommaPosition);
        Assembly assembly;
        _localAssemblies.TryGetValue(assemblyName, out assembly);
        return assembly;
    }
}
"

Add-Type -TypeDefinition $epiCloudAssemblyResolver
[EpiCloudAssemblyResolver]::Initialize()
function InvokeApiRequest {
    <#
    .SYNOPSIS
    This helper function does the actual API call.

    .DESCRIPTION
    This helper function does the actual API call and signs the request.

    #>

    [CmdletBinding(DefaultParameterSetName = 'NoRequestPayload')]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $RequestSplattingHash,

        [Parameter(Mandatory = $true, ParameterSetName = 'ObjectRequestPayload')]
        [System.Collections.Hashtable] $RequestPayload
    )

    begin {
        AddTlsSecurityProtocolSupport
    }

    process {
        if ($RequestPayload) {
            try {
                $encodedString = GetApiObjectEncoded -RequestPayload $RequestPayload
                $encodedPayload = ConvertTo-Json -Depth 10 -InputObject $encodedString
            }
            catch {
                throw "Failed to encode the request payload. The error was: $($_.Exception.Message)"
            }

            $RequestSplattingHash.Add('Body', $encodedPayload)
        }

        $setApiAuthorizationHeaderParams = @{
            ClientKey    = $ClientKey
            ClientSecret = $ClientSecret
            RequestHash  = $RequestSplattingHash
        }

        SetApiAuthorizationHeader @setApiAuthorizationHeaderParams

        try {
            $response = Invoke-RestMethod @RequestSplattingHash
        }
        catch {
            $errorMessage = GetApiErrorResponse -ExceptionResponse $_.Exception.Response
            throw "API call failed! The error was: $($_.Exception.Message) $errorMessage"
        }

        if (!$response.success) {
            throw "API call failed! The error(s) was: $(($response.errors) -join ', ')"
        }

        if ($response.result) {
            GetApiObjectEncoded -ApiObject $response.result
        }
    }

    end { }
}
function SetApiAuthorizationHeader {
    <#
            .SYNOPSIS
            This helper function contains the logic for signing the request/creating the
            authorization header

            .DESCRIPTION
            This helper function contains the logic for signing the request/creating the
            authorization header

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
                    $errorMessage = 'The ClientSecret is invalid.'
                    if ($_.Length % 4 -ne 0 -or $_.Contains(' ')) {
                        throw $errorMessage
                    }
                    
                    try {
                        [System.Convert]::FromBase64String($_)
                        return $true
                    }
                    catch {
                        throw "$errorMessage The error was: $($_.Exception.Message)"
                    }
        })]
        [String] $ClientSecret,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable] $RequestHash
    )

    # Initialize utils required for computing an HMAC and md5 signature/hash
    $hmacAlgorithm = New-Object System.Security.Cryptography.HMACSHA256
    $md5 = [System.Security.Cryptography.MD5]::Create()

    # Set the secret the HMAC algorithm uses for computing the signature
    $hmacAlgorithm.key = [System.Convert]::FromBase64String($ClientSecret)

    # Define the different parts that make up the HMAC signature
    $path = ([System.Uri] $RequestHash.Uri).PathAndQuery
    $method = $RequestHash.Method.ToUpperInvariant()
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliSeconds().ToString("0")
    $nonce = (New-Guid).ToString("N")

    # Define the HTTP request payload that will be tacked on to the signature
    if ($RequestHash.Body) {
        $bodyBytes = [Text.Encoding]::UTF8.GetBytes($RequestHash.Body)
    }
    else {
        $bodyBytes = [Text.Encoding]::UTF8.GetBytes('')
    }

    $bodyHashBytes = $md5.ComputeHash($bodyBytes)
    $hashBody = [Convert]::ToBase64String($bodyHashBytes)

    # Combine all the parts into a signature message
    $message = "{0}{1}{2}{3}{4}{5}" -f $ClientKey, $method, $path, $timestamp, $nonce, $hashBody
    $messageBytes = [Text.Encoding]::UTF8.GetBytes($message)

    # Define the HMAC signature from the message
    $signatureHash = $hmacAlgorithm.ComputeHash($messageBytes);
    $signature = [Convert]::ToBase64String($signatureHash)

    # Define the authorization header for the HTTP request
    $authorization = "epi-hmac {0}:{1}:{2}:{3}" -f $ClientKey, $timestamp, $nonce, $signature

    # Set the header
    $RequestHash.Headers.Authorization = $authorization
}
function Add-EpiDeploymentPackage {
    <#
    .SYNOPSIS
        Will upload the specified file to the code package container by using a SAS link.

    .DESCRIPTION
        Will upload the specified file to the code package container by using a SAS link.

        Requires storage cmdlets from the Azure.Storage module to run.

    .PARAMETER Path
        The file name with full path.

    .PARAMETER BlobName
        The name of Blob in the container.

    .PARAMETER SasUrl
        The Sas link contains access to storage account.

    .EXAMPLE
        Add-EpiDeploymentPackage -SasUrl "https://thle2307mh134.blob.core.windows.net/deploymentpackages?sv=2017-04-17&sr=c&sig=MGW6ndtX1vNT%2BSRpLUT8vPuurteyb" -Path .\site.cms.app.1.0.0.nupkg

        Uploads the file ".\site.cms.app.1.0.0.nupkg" to the code package container on the storage account specified via the SAS link ("SasUrl").
    #>

    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory = $true)]
        [String] $SasUrl,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [String] $Path,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [String] $BlobName
    )

    begin {
        AddTlsSecurityProtocolSupport

        $DefaultContainer = "deploymentpackages"

        $urlComponent = $SasUrl -split $DefaultContainer
        if ($urlComponent.Length -lt 2 -or -not $SasUrl.StartsWith('https://') -or -not $SasUrl.Contains('.blob.core.windows.net/')) {
            throw "The SasUrl is not correct"
        }

        $sasUri = [Uri] $SasUrl
    }

    process {
        if (-not $BlobName) {
            $BlobName = Split-Path $Path -leaf
        }

        Write-Verbose "Uploading blob $BlobName to storage account ..."

        try {
            $response = AddAzStorageBlob -SasUri $sasUri -BlobName $BlobName -Path $Path
        }
        catch {
            if ($_.Exception.InnerException.Status -eq 412 -and $_.Exception.InnerException.ErrorCode -eq 'LeaseIdMissing') {
                throw "A package named '$BlobName' is already linked to a deployment and cannot be overwritten."
            }
            else {
                throw "Failed to upload the blob. The error was: $($_.Exception.Message)"
            }
        }

        if (-not $response.IsSuccessful) {
            throw "Error uploading $BlobName`: $($response.Status) $($response.ReasonPhrase)"
        }

        Write-Verbose "Done!"
    }

    end { }
}
function Complete-EpiDeployment {
    <#
    .SYNOPSIS
        This function will complete the specified code deployment.

    .DESCRIPTION
        This function will complete the specified code deployment.

    .EXAMPLE
        $clientKey = '12331bpXbHmuTDkhZmtUAq1scYsEbCIlY4N355SWLmTq1cgi'
        $clientSecret = '123456dkQQZ2ohrVMwtyZAtEkqHd75l2f9ACPIN1nm4pHmZDQ4NMikCNWBlZ2H6D'
        $projectId = '8ad8cc5b-0c49-4b79-8ebd-6451465a92c2'
        $deploymentId = '6c0ed684-8548-48aa-8695-fcfd43477b43'

        Complete-EpiDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Id $deploymentId

    .EXAMPLE
        $clientKey = '12331bpXbHmuTDkhZmtUAq1scYsEbCIlY4N355SWLmTq1cgi'
        $clientSecret = '123456dkQQZ2ohrVMwtyZAtEkqHd75l2f9ACPIN1nm4pHmZDQ4NMikCNWBlZ2H6D'
        $projectId = '8ad8cc5b-0c49-4b79-8ebd-6451465a92c2'
        $deploymentId = '6c0ed684-8548-48aa-8695-fcfd43477b43'

        Complete-EpiDeployment -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Id $deploymentId -Wait -WaitTimeoutMinutes 10 -PollingIntervalSeconds 10

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The Id (should be a guid) of the project.

    .PARAMETER Id
        The Id (should be a guid) of the deployment that you want to complete.

    .PARAMETER Wait
        Specify this switch to wait for the deployment to finish.

    .PARAMETER ShowProgress
        Specify this switch to enable a progress bar indicating deployment progress

    .PARAMETER WaitTimeoutMinutes
        The maximum amount of time, in minutes, to wait for the completion to finish.

    .PARAMETER PollingIntervalSeconds
        The time interval, in seconds, to check the deployment status.
        Default to 30 seconds.
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $Id,

        [Parameter(Mandatory = $false)]
        [Switch] $Wait,

        [Parameter(Mandatory = $false)]
        [Switch] $ShowProgress,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $WaitTimeoutMinutes = 240,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $PollingIntervalSeconds = 30
    )

    begin { }

    process {
        $uriEnding = "projects/$ProjectId/deployments/$Id/complete"

        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding -Method 'Post'

        $completeEpiDeploymentParams = @{
            ClientKey            = $ClientKey
            ClientSecret         = $ClientSecret
            RequestSplattingHash = $requestHash
        }

        $deploymentDetails = InvokeApiRequest @completeEpiDeploymentParams

        if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
            $writeProgressParams = @{
                Activity = "Completing deployment with id $Id..."
                PercentComplete = 0
                Status = $deploymentDetails.status
            }

            Write-Progress @writeProgressParams
        }

        if ($Wait.IsPresent) {
            $timeoutDate = (Get-Date).AddMinutes($WaitTimeoutMinutes)

            $deploymentCompletionStates = @('Failed', 'Succeeded')
            do {
                Start-Sleep -Second $PollingIntervalSeconds
                $getEpiDeploymentDetailsParams = @{
                    ClientKey    = $ClientKey
                    ClientSecret = $ClientSecret
                    ProjectId    = $ProjectId
                    Id           = $Id
                }
                $deploymentDetails = Get-EpiDeployment @getEpiDeploymentDetailsParams
                Write-Verbose "Deployment status: $($deploymentDetails.status). Progress: $($deploymentDetails.percentComplete)%"

                if ($ShowProgress.IsPresent) {
                    $writeProgressParams.PercentComplete = $deploymentDetails.percentComplete
                    $writeProgressParams.Status = $deploymentDetails.status
                    Write-Progress @writeProgressParams
                }
            }
            while ($deploymentDetails.status -notin $deploymentCompletionStates -and (Get-Date) -le $timeoutDate)

            if ($deploymentCompletionStates -notcontains $deploymentDetails.status) {
                throw "Timed out during deployment with status: $($deploymentDetails.status)"
            }
        }

        $deploymentDetails
    }

    end { }
}
function Connect-EpiCloud {
    <#
    .SYNOPSIS
        Adds credentials (ClientKey and ClientSecret) for all functions
        in EpiCloud module to be used during the session/context.

    .DESCRIPTION
        This function will specify the default credentials (ClientKey and ClientSecret)
        that should be used for all functions in the current session/context.

        Can also specify the ProjectId.

    .EXAMPLE
        Connect-EpiCloud -ClientKey 12331bpXbHmuTDkhZmtUAq1scYsEbCIlY4N355SWLmTq1123 -ClientSecret UowYA4dkQQZ2ohrVMwtyZAtEkqHd75l2f9ACPIN1nm4pHmZDQ4NMikCNWBlZ2H6D

        Get-EpiDeploymentPackageLocation -ProjectId 1234567890

    .EXAMPLE
        Connect-EpiCloud -ClientKey 12331bpXbHmuTDkhZmtUAq1scYsEbCIlY4N355SWLmTq1123 -ClientSecret UowYA4dkQQZ2ohrVMwtyZAtEkqHd75l2f9ACPIN1nm4pHmZDQ4NMikCNWBlZ2H6D -ProjectId 3c84b95d-42d5-4a3a-9e65-d5c83e945fe7

        Get-EpiDeploymentPackageLocation

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The id of the project

    #>

    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $false)]
        [String] $ProjectId
    )

    begin {
        $commands = Get-Command -Module 'EpiCloud'
    }

    process {
        $authVerified = $false
        # If ProjectId was specified, we can validate the credentials
        if ($ProjectId) {
            try {
                $getEpiDeploymentSplat = @{
                    ClientKey = $ClientKey
                    ErrorAction = 'Stop'
                    ClientSecret = $ClientSecret
                    ProjectId = $ProjectId
                }

                $null = Get-EpiDeployment @getEpiDeploymentSplat
                $authVerified = $true
            }
            catch {
                throw "Failed to validate the credentials specified for project with id $ProjectId! Error: $($_.Exception.Message)"
            }
        }

        foreach ($command in $commands) {
            Write-Verbose "Configuring credentials for command $($command.Name)"
            if ($Global:PSDefaultParameterValues."$($command.Name):ClientKey") {
                $Global:PSDefaultParameterValues.Remove("$($command.Name):ClientKey")
            }

            if ($Global:PSDefaultParameterValues."$($command.Name):ClientSecret") {
                $Global:PSDefaultParameterValues.Remove("$($command.Name):ClientSecret")
            }

            if ($Global:PSDefaultParameterValues."$($command.Name):ProjectId") {
                $Global:PSDefaultParameterValues.Remove("$($command.Name):ProjectId")
            }

            if ($command.Parameters.Keys -contains 'ClientKey') {
                $Global:PSDefaultParameterValues.Add("$($command.Name):ClientKey", $ClientKey)
            }

            if ($command.Parameters.Keys -contains 'ClientSecret') {
                $Global:PSDefaultParameterValues.Add("$($command.Name):ClientSecret", $ClientSecret)
            }

            if ($ProjectId -and $command.Parameters.Keys -contains 'ProjectId') {
                $Global:PSDefaultParameterValues.Add("$($command.Name):ProjectId", $ProjectId)
            }
        }

        $hashToReturn = @{
            ClientKey = $ClientKey
            AuthenticationVerified = $authVerified
        }

        if ($ProjectId) {
            $hashToReturn.ProjectId = $ProjectId
        }

        [PSCustomObject] $hashToReturn
    }

    end { }
}
function Get-EpiDatabaseExport {
    <#
        .SYNOPSIS
        Retrieves information for the specified export.

        .DESCRIPTION
        Retrieves information for the specified export.

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.

        .PARAMETER Environment
        The environment that the exported database belongs to.

        .PARAMETER DatabaseName
        The name of the exported database.

        .PARAMETER Id
        The Id (should be a guid) of the database export.

        .EXAMPLE
        Get-EpiDatabaseExport -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -Environment Integration -DatabaseName epicms -Id d142a635-c09e-4c56-a4ba-394d0dd7a14a
    #>

    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true)]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [String] $ClientSecret,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory=$true)]
        [String] $Environment,

        [Parameter(Mandatory=$true)]
        [String] $DatabaseName,

        [Parameter(Mandatory=$true)]
        [String] $Id
    )

    begin { }

    process {
        $uriEnding = "projects/$ProjectId/environments/$Environment/databases/$DatabaseName/exports/$Id"

        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding

        $invokeApiRequestSplat = @{
            ClientSecret = $ClientSecret
            ClientKey = $ClientKey
            RequestSplattingHash = $requestHash
        }

        InvokeApiRequest @invokeApiRequestSplat
    }

    end { }
}
function Get-EpiDeployment {
    <#
        .SYNOPSIS
        Retrieves deployments that have been triggered via the deployment api for the specified project id.

        .DESCRIPTION
        Retrieves deployments that have been triggered via the deployment api for the specified project id.

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.

        .PARAMETER Id
        The Id (should be a guid) of the deployment.

        .EXAMPLE
        Get-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv

        .EXAMPLE
        Get-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -Id d142a635-c09e-4c56-a4ba-394d0dd7a14a
    #>

    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true)]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [String] $ClientSecret,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [String] $Id
    )

    begin { }

    process {
        $uriEnding = "projects/$ProjectId/deployments"

        if ($Id) {
            $uriEnding += "/$Id"
        }

        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding

        $invokeApiRequestSplat = @{
            ClientSecret = $ClientSecret
            ClientKey = $ClientKey
            RequestSplattingHash = $requestHash
        }

        InvokeApiRequest @invokeApiRequestSplat
    }

    end { }
}
function Get-EpiDeploymentPackageLocation {
    <#
        .SYNOPSIS
        Retrieves the location where deployment packages can be uploaded.

        .DESCRIPTION
        Retrieves the location where deployment packages can be uploaded.

        This will be a SAS-link to an Azure blob storage account.

        .EXAMPLE
        Get-EpiDeploymentPackageLocation -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.
    #>

    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true)]
        [String] $ClientKey,

        [Parameter(Mandatory=$true)]
        [String] $ClientSecret,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId
    )


    begin { }

    process {

        $uriEnding = "projects/$ProjectId/packages/location"
        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding

        $invokeApiRequestSplat = @{
            ClientSecret = $ClientSecret
            ClientKey = $ClientKey
            RequestSplattingHash = $requestHash
        }

        # Since the response only contains one property we expand it
        (InvokeApiRequest @invokeApiRequestSplat).location
    }

    end { }
}
function Get-EpiStorageContainer {
    <#
        .SYNOPSIS
        Retrieves list of blob storage containers for specified project id and environment.

        .DESCRIPTION
        Retrieves list of blob storage containers for specified project id and environment.

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.

        .PARAMETER Environment
        The environment name.

        .EXAMPLE
        Get-EpiStorageContainer -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -Environment Integration
    #>

    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [String] $Environment
    )

    begin { }

    process {
        $uriEnding = "projects/$ProjectId/environments/$Environment/storagecontainers"

        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding

        $invokeApiRequestSplat = @{
            ClientSecret         = $ClientSecret
            ClientKey            = $ClientKey
            RequestSplattingHash = $requestHash
        }

        InvokeApiRequest @invokeApiRequestSplat
    }

    end { }
}
function Get-EpiStorageContainerSasLink {
    <#
        .SYNOPSIS
        Retrieves SAS link for specified project id, environment, storage container and retention hours.

        .DESCRIPTION
        Retrieves SAS link for specified project id, environment, storage container and retention hours.

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.

        .PARAMETER Environment
        The environment name.

        .PARAMETER StorageContainer
        The blob storage container name.

        .PARAMETER RetentionHours
        Total hours for which sas link will be retained. Default is 24 hours.

        .EXAMPLE
        Get-EpiStorageContainerSasLink -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -Environment Integration -StorageContainer @('azure-application-logs', 'azure-web-logs')
    #>

    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $Environment,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('storageContainers')]
        [String[]] $StorageContainer,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 168)]
        [Int] $RetentionHours = 24
    )

    begin { }

    process {
        foreach ($container in $StorageContainer) {
            $uriEnding = "projects/$ProjectId/environments/$Environment/storagecontainers/$container/saslink"

            $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding -Method 'Post'

            $invokeApiRequestSplat = @{
                ClientSecret         = $ClientSecret
                ClientKey            = $ClientKey
                RequestSplattingHash = $requestHash
                RequestPayload       = @{ RetentionHours = $RetentionHours }
            }

            InvokeApiRequest @invokeApiRequestSplat
        }
    }

    end { }
}
function Reset-EpiDeployment {
    <#
        .SYNOPSIS
        Resets or completes resetting the specified deployment.

        .DESCRIPTION
        Resets or completes resetting the specified deployment.

        .PARAMETER ClientKey
        The client key used to access the project.

        .PARAMETER ClientSecret
        The client secret used to access the project.

        .PARAMETER ProjectId
        The Id (should be a guid) of the project.

        .PARAMETER Id
        The Id (should be a guid) of the deployment that you want to reset.

        .PARAMETER RollbackDatabase
        Specify this switch to rollback database if maintenance mode was applied.

        .PARAMETER ValidateBeforeSwap
        Specify this switch to validate the target site before completing the reset progress if maintenance mode was applied.

        .PARAMETER Complete
        Specify this switch to complete resetting a deployment.

        .PARAMETER Wait
        Specify this switch to wait for the deployment to finish.

        .PARAMETER ShowProgress
        Specify this switch to enable a progress bar indicating deployment progress.

        .PARAMETER WaitTimeoutMinutes
        The maximum amount of time, in minutes, to wait for the reset to finish.

        .PARAMETER PollingIntervalSeconds
        The time interval, in seconds, to check the deployment status.
        Default to 30 seconds.

        .EXAMPLE
        Reset-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId 423ae883-7202-44cb-a907-3006d0d1cd58 -Id d117c12c-d02e-4b53-aabd-aa8e00a47cdv

        Reset a deployment.

        .EXAMPLE
        Reset-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId $myProject -Id $deploymentId -RollbackDatabase -ValidateBeforeSwap

        Reset a deployment with RollbackDatabase and ValidateBeforeSwap options.

        .EXAMPLE
        Reset-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId $myProject -Id $deploymentId -Complete

        Complete resetting a deployment.
    #>

    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'StartReset')]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $Id,

        [Parameter(Mandatory = $false, ParameterSetName = 'StartReset')]
        [Switch] $RollbackDatabase,

        [Parameter(Mandatory = $false, ParameterSetName = 'StartReset')]
        [Switch] $ValidateBeforeSwap,

        [Parameter(Mandatory = $false, ParameterSetName = 'CompleteReset')]
        [Switch] $Complete,

        [Parameter(Mandatory = $false)]
        [Switch] $Wait,

        [Parameter(Mandatory = $false)]
        [Switch] $ShowProgress,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $WaitTimeoutMinutes = 240,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $PollingIntervalSeconds = 30
    )

    begin { }

    process {

        $uriEnding = "projects/$ProjectId/deployments/$Id/reset"
        $requestHash = GetApiRequestSplattingHash -UriEnding $uriEnding -Method 'Post'

        $invokeApiRequestParams = @{
            ClientSecret         = $ClientSecret
            ClientKey            = $ClientKey
            RequestSplattingHash = $requestHash
            RequestPayload       = @{
                ResetWithDbRollback = $RollbackDatabase.IsPresent
                ValidateBeforeSwap  = $ValidateBeforeSwap.IsPresent
                Complete            = $Complete.IsPresent
            }
        }

        $resetDeploymentDetails = InvokeApiRequest @invokeApiRequestParams

        if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
            $writeProgressParams = @{
                Activity = "Resetting deployment with id $Id..."
                PercentComplete = 0
                Status = $resetDeploymentDetails.status
            }

            Write-Progress @writeProgressParams
        }

        if ($Wait.IsPresent) {
            $timeoutDate = (Get-Date).AddMinutes($WaitTimeoutMinutes)
            $getEpiDeploymentDetailsParams = @{
                ClientKey    = $ClientKey
                ClientSecret = $ClientSecret
                ProjectId    = $ProjectId
                Id           = $Id
            }

            $deploymentCompletionStates = @('Failed', 'Reset', 'AwaitingResetVerification')
            do {
                Start-Sleep -Second $PollingIntervalSeconds

                $resetDeploymentDetails = Get-EpiDeployment @getEpiDeploymentDetailsParams
                Write-Verbose -Message "Deployment status: $($resetDeploymentDetails.status). Progress: $($resetDeploymentDetails.percentComplete)%"

                if ($ShowProgress.IsPresent) {
                    $writeProgressParams.PercentComplete = $resetDeploymentDetails.percentComplete
                    $writeProgressParams.Status = $resetDeploymentDetails.status
                    Write-Progress @writeProgressParams
                }
            }
            while ($resetDeploymentDetails.status -notin $deploymentCompletionStates -and (Get-Date) -le $timeoutDate)

            if ($deploymentCompletionStates -notcontains $resetDeploymentDetails.status) {
                throw "Timed out during deployment with status: $($resetDeploymentDetails.status). Deployment ID: $Id"
            }
        }

        $resetDeploymentDetails
    }

    end { }
}
function Start-EpiDatabaseExport {
    <#
    .SYNOPSIS
        Starts a database export for the specified project, environment and database combination.

    .DESCRIPTION
        Starts a database export for the specified project, environment and database combination

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The Id (should be a guid) of the project.

    .PARAMETER Environment
        The environment that the database belongs to.

    .PARAMETER DatabaseName
        The name of the database that will be exported.

    .PARAMETER RetentionHours
        Total hours that the bacpac will be retained.

    .PARAMETER Wait
        Specify this switch to enable "polling" of the export until it's completed.

    .PARAMETER ShowProgress
        Specify this switch to enable a progress text indicating export progress

    .PARAMETER WaitTimeoutMinutes
        The maximum amount of time, in minutes, to wait for the export to finish.

    .PARAMETER PollingIntervalSec
        How often, in seconds, to poll for export status.

    .EXAMPLE
        Start-EpiDatabaseExport -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -Environment Integration -DatabaseName epicms
    #>

    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $true)]
        [String] $Environment,

        [Parameter(Mandatory = $true)]
        [ValidateSet('epicms','epicommerce')]
        [String] $DatabaseName,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $RetentionHours = 24,

        [Parameter(Mandatory = $false)]
        [Switch] $Wait,

        [Parameter(Mandatory = $false)]
        [Switch] $ShowProgress,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $WaitTimeoutMinutes = 60,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $PollingIntervalSec = 30
    )

    begin { }

    process {
        if ($Wait.IsPresent) {
            $timeOutDateTime = (Get-Date).AddMinutes($WaitTimeoutMinutes)
        }
        else {
            $timeOutDateTime = Get-Date
        }

        $uriEnding = "projects/$ProjectId/environments/$Environment/databases/$DatabaseName/exports"
        $requestSplattingHash = GetApiRequestSplattingHash -UriEnding $uriEnding -Method 'Post'

        $startExportParams = @{
            ClientKey            = $ClientKey
            ClientSecret         = $ClientSecret
            RequestSplattingHash = $requestSplattingHash
            RequestPayload       = @{
                RetentionHours = $RetentionHours
            }
        }

        Write-Verbose "Starting export database: $($DatabaseName) for the project: $($ProjectId) / environment: $($Environment)"
        $startExportResponse = InvokeApiRequest @startExportParams

        if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
            $writeProgressParams = @{
                Activity = "Export database running against $DatabaseName..."
                Status = $startExportResponse.status
            }

            Write-Progress @writeProgressParams
        }

        $exportCompletionStates = @('LinkExpired', 'ExportFailed', 'Succeeded')
        do {
            if ($Wait.IsPresent) {
                Start-Sleep -Seconds $PollingIntervalSec
            }
            $getExportParams = @{
                ClientKey    = $ClientKey
                ClientSecret = $ClientSecret
                ProjectId    = $ProjectId
                Environment  = $Environment
                DatabaseName = $DatabaseName
                Id           = $startExportResponse.id
            }

            $getExportResponse = Get-EpiDatabaseExport @getExportParams
            Write-Verbose "Export status: $($getExportResponse.status)."

            if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
                $writeProgressParams.Status = $getExportResponse.status
                Write-Progress @writeProgressParams
            }
        } while ($Wait.IsPresent -and $exportCompletionStates -notcontains $getExportResponse.status -and (Get-Date) -le ($timeOutDateTime))

        if ($Wait.IsPresent -and $exportCompletionStates -notcontains $getExportResponse.status) {
            throw "Timed out during export with status: $($getExportResponse.status)"
        }

        $getExportResponse
    }
    end {}
}
function Start-EpiDeployment {
    <#
    .SYNOPSIS
        Starts a code deployment for the specified project.

    .DESCRIPTION
        Starts a code deployment for the specified project.

    .PARAMETER ClientKey
        The client key used to access the project.

    .PARAMETER ClientSecret
        The client secret used to access the project.

    .PARAMETER ProjectId
        The Id (should be a guid) of the project.

    .PARAMETER SourceApp
        The source app(s) for the deployment (if no uploaded code package should be used).

    .PARAMETER SourceEnvironment
        The source environment for the deployment (if no uploaded code package should be used).

    .PARAMETER TargetEnvironment
        The target environment to which the code should be deployed.

    .PARAMETER DeploymentPackage
        The code package(s) being deployed.

    .PARAMETER UseMaintenancePage
        The flag to tell whether maintenance page is used during the deployment.

    .PARAMETER  ZeroDownTimeMode
        What database mode to use on the primary web app, possible values are: ReadOnly, ReadWrite.

        If omitted, zero downtime mode will not be used.

    .PARAMETER IncludeBlob
        Specify this switch to include blobs from the source environment.

    .PARAMETER IncludeDb
        Specify this switch to include the SQL DB from the source environment.

    .PARAMETER DirectDeploy
        Specify this switch to speed up deployments to Integration/Development environment.
        A deployment will be made directly to the target web app without performing a swap.
        Attention: Resetting the deployment (or the database of the target environment) is not supported for DirectDeploy.

    .PARAMETER Wait
        Specify this switch to enable "polling" of the deployment until it's completed.

    .PARAMETER ShowProgress
        Specify this switch to enable a progress bar indicating deployment progress

    .PARAMETER WaitTimeoutMinutes
        The maximum amount of time, in minutes, to wait for the deployment to finish.

    .PARAMETER PollingIntervalSec
        How often, in seconds, to poll for deployment status.

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId $projectId -TargetEnvironment Integration -DeploymentPackage cms.app.1.0.0.nupkg -DirectDeploy

        Directly deploys a code package to the Integration environment.

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -TargetEnvironment Integration -DeploymentPackage cms.app.1.0.0.nupkg

        Deploys a code package to the Integration environment.

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -TargetEnvironment Integration -DeploymentPackage cms.app.1.0.0.nupkg -Wait -PollingIntervalSec 10 -WaitTimeoutMinutes 30

        Deploys a code package to the Integration environment and waits for it to finish (for up to 30 minutes).

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -SourceEnvironment Integration -SourceApp cms -TargetEnvironment Preproduction -IncludeBlob -IncludeDb

        Starts a deployment to Preproduction environment copying the code of the cms app and the contents (blobs and db(s)) from the Integration source environment.

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -SourceEnvironment Integration -TargetEnvironment Production -IncludeBlob -IncludeDb

        Starts a deployment to Production environment copying only the the contents (blobs and db(s)) from the Integration source environment.

    .EXAMPLE
        Start-EpiDeployment -ClientKey $myKey -ClientSecret $mySecret -ProjectId d117c12c-d02e-4b53-aabd-aa8e00a47cdv -SourceEnvironment Integration -TargetEnvironment Production -ZeroDownTimeMode ReadOnly

        Starts a deployment to Production environment with zero downtime readonly mode.
    #>

    [CmdletBinding(
        DefaultParameterSetName = 'DeploymentPackage',
        PositionalBinding = $false
    )]
    param(
        [Parameter(Mandatory = $true)]
        [String] $ClientKey,

        [Parameter(Mandatory = $true)]
        [String] $ClientSecret,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String] $ProjectId,

        [Parameter(Mandatory = $false, ParameterSetName = 'SourceEnvironment')]
        [ValidateSet('cms', 'commerce')]
        [String[]] $SourceApp,

        [Parameter(Mandatory = $true, ParameterSetName = 'SourceEnvironment')]
        [String] $SourceEnvironment,

        [Parameter(Mandatory = $true)]
        [String] $TargetEnvironment,

        [Parameter(Mandatory = $true, ParameterSetName = 'DeploymentPackage')]
        [String[]] $DeploymentPackage,

        [Parameter(Mandatory = $false)]
        [Switch] $UseMaintenancePage,

        [Parameter(Mandatory = $false)]
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [String] $ZeroDownTimeMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'SourceEnvironment')]
        [Switch] $IncludeBlob,

        [Parameter(Mandatory = $false, ParameterSetName = 'SourceEnvironment')]
        [Switch] $IncludeDb,

        [Parameter(Mandatory = $false)]
        [Switch] $DirectDeploy,

        [Parameter(Mandatory = $false)]
        [Switch] $Wait,

        [Parameter(Mandatory = $false)]
        [Switch] $ShowProgress,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('WaitTimeoutSec')]
        [Int] $WaitTimeoutMinutes = 240,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [Int] $PollingIntervalSec = 30
    )

    begin {
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('WaitTimeoutMinutes')) {
            if ($PSCmdlet.MyInvocation.Line -like "*-WaitTimeoutSec*") {
                Write-Warning "The WaitTimeoutSec-parameter has been deprecated. Please use WaitTimeoutMinutes instead."
                $WaitTimeoutMinutes = $WaitTimeoutMinutes / 60
            }
        }
    }

    process {
        if ($Wait.IsPresent) {
            $timeOutDateTime = (Get-Date).AddMinutes($WaitTimeoutMinutes)
        }
        else {
            $timeOutDateTime = Get-Date
        }

        $maintenanceMode = $false
        if ($ZeroDownTimeMode -or $UseMaintenancePage.IsPresent) {
            $maintenanceMode = $true
        }

        $uriEnding = "projects/$ProjectId/deployments"
        $requestSplattingHash = GetApiRequestSplattingHash -UriEnding $uriEnding -Method 'Post'

        $startDeploymentParams = @{
            ClientKey            = $ClientKey
            ClientSecret         = $ClientSecret
            RequestSplattingHash = $requestSplattingHash
            RequestPayload       = @{
                TargetEnvironment = $TargetEnvironment
                MaintenancePage   = $maintenanceMode
                ZeroDownTimeMode  = $ZeroDownTimeMode
                DirectDeploy      = $DirectDeploy.IsPresent
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'DeploymentPackage') {
            $startDeploymentParams.RequestPayload.Packages = $DeploymentPackage
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'SourceEnvironment') {
            $startDeploymentParams.RequestPayload.sourceEnvironment = $SourceEnvironment

            if ($SourceApp) {
                $startDeploymentParams.RequestPayload.sourceApps = $SourceApp
            }

            $startDeploymentParams.RequestPayload.includeBlob = $IncludeBlob.IsPresent
            $startDeploymentParams.RequestPayload.includeDB = $IncludeDb.IsPresent

            if (-not $startDeploymentParams.RequestPayload.sourceApps -and
                -not $IncludeBlob.IsPresent -and
                -not $IncludeDb.IsPresent) {
                throw "You need to specify at least one of the following parameters: DeploymentPackage, SourceApp, IncludeBlob or IncludeDb."
            }
        }

        Write-Verbose "Starting deployment for the project: $($ProjectId) / targetEnvironment: $($TargetEnvironment)"
        $startDeploymentResponse = InvokeApiRequest @startDeploymentParams

        if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
            $writeProgressParams = @{
                Activity        = "Deployment running against $TargetEnvironment..."
                PercentComplete = 0
                Status          = $startDeploymentResponse.status
            }

            Write-Progress @writeProgressParams
        }

        $deploymentCompletionStates = @('Failed', 'AwaitingVerification', 'Succeeded')
        do {
            if ($Wait.IsPresent) {
                Start-Sleep -Seconds $PollingIntervalSec
            }
            $getDeploymentParams = @{
                ClientKey    = $ClientKey
                ClientSecret = $ClientSecret
                ProjectId    = $ProjectId
                Id           = $startDeploymentResponse.id
            }

            $getDeploymentResponse = Get-EpiDeployment @getDeploymentParams
            Write-Verbose "Deployment status: $($getDeploymentResponse.status). Progress: $($getDeploymentResponse.percentComplete)%"

            if ($ShowProgress.IsPresent -and $Wait.IsPresent) {
                $writeProgressParams.PercentComplete = $getDeploymentResponse.percentComplete
                $writeProgressParams.Status = $getDeploymentResponse.status
                Write-Progress @writeProgressParams
            }
        } while ($Wait.IsPresent -and $deploymentCompletionStates -notcontains $getDeploymentResponse.status -and (Get-Date) -le ($timeOutDateTime))

        if ($Wait.IsPresent -and $deploymentCompletionStates -notcontains $getDeploymentResponse.status) {
            throw "Timed out during deployment with status: $($getDeploymentResponse.status)"
        }

        $getDeploymentResponse
    }
    end {}
}
