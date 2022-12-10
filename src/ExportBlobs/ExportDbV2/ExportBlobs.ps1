[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DxpContainer,
    $RetentionHours,
    $Timeout,
    $RunVerbose,
    $DownloadBlobs,
    $DownloadFolder
)
try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment
    $dxpContainer = $DxpContainer
    $retentionHours = $RetentionHours
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $downloadBlobs = [System.Convert]::ToBoolean($DownloadBlobs)
    $downloadFolder = $DownloadFolder

    # 30 min timeout
    ####################################################################################
    
    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "Environment:        $environment"
    Write-Host "DxpContainer:       $dxpContainer"
    Write-Host "RetentionHours:     $retentionHours"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"
    Write-Host "DownloadBlobs:      $downloadBlobs"
    Write-Host "DownloadFolder:     $downloadFolder"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Mount-PsModulesPath

    Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $sasLinkInfo = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Containers $null -Container $DxpContainer -RetentionHours $RetentionHours
    if ($null -eq $sasLinkInfo) {
        Write-Error "Did not get a SAS link to container $DxpContainer."
        exit
    }
    Write-Host "Found SAS link info: ---------------------------"
    Write-Host "projectId:                $($sasLinkInfo.projectId)"
    Write-Host "environment:              $($sasLinkInfo.environment)"
    Write-Host "containerName:            $($sasLinkInfo.containerName)"
    Write-Host "sasLink:                  $($sasLinkInfo.sasLink)"
    Write-Host "expiresOn:                $($sasLinkInfo.expiresOn)"
    Write-Host "------------------------------------------------"
    $SourceSasLink = $sasLinkInfo.sasLink
    $container = $sasLinkInfo.containerName
    

    if ($null -ne $SourceSasLink){
        Write-Host "Setvariable DxpExportBlobsSasLink: $SourceSasLink"
        Write-Host "##vso[task.setvariable variable=DxpExportBlobsSasLink;]$SourceSasLink"
    }


    if ($downloadBlobs){
        Write-Host "-------------DOWNLOAD-TO-AGENT---------------------"
        Write-Host "Start download blobs $($status.downloadLink)"
        $overwriteExistingFiles = $true

        ImportAzureStorageModule

        $sasInfo = Get-SasInfo -SasLink $SourceSasLink
        $storageAccountName = $sasInfo.StorageAccountName
        #$storageAccountName = Get-StorageAccountNameFromSasLink -SasLink $SourceSasLink

        $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -SASToken $SourceSasLink -ErrorAction Stop

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

            # if ($maxFilesToDownload -eq 0) {
            #     $maxFilesToDownload = [int]$blobContents.Length
            # }
            $downloadedFiles = 0
            Write-Host "---------------------------------------------------"
            foreach($blobContent in $blobContents)  
            {  
                # if ($downloadedFiles -ge $maxFilesToDownload){
                #     Write-Host "Hit max files to download ($maxFilesToDownload)"
                #     break
                # }

                $filePath = (Join-Parts -Separator '\' -Parts $downloadFolder, $blobContent.Name.Replace("/", "\"))
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


        # if ($downloadFolder.Contains("\")){
        #     $filePath = "$downloadFolder\$($status.bacpacName)"
        # } else {
        #     $filePath = "$downloadFolder/$($status.bacpacName)"
        # }
        # Invoke-WebRequest -Uri $status.downloadLink -OutFile $filePath

        Write-Host "Downloaded blobs to $filePath"
        Write-Host "Setvariable ExportBlobsFilePath: $filePath"
        Write-Host "##vso[task.setvariable variable=ExportBlobsFilePath;]$filePath"
        Write-Host "------------------------------------------------"
    }

    ####################################################################################
    Write-Host "---THE END---"
}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}

if ($runVerbose){
    ## To Set Verbose output
    $PSDefaultParameterValues['*:Verbose'] = $false
}