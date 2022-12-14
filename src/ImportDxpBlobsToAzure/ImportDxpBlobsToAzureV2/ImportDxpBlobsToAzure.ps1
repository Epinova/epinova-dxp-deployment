[CmdletBinding()]
Param(
    # $ClientKey,
    # $ClientSecret,
    # $ProjectId, 
    # $Environment,
    # $DxpContainer,
    $DxpExportBlobsSasLink,
    $SubscriptionId,
    $ResourceGroupName,
    $StorageAccountName,
    $StorageAccountContainer,
    $CleanBeforeCopy,

    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    # $clientKey = $ClientKey
    # $clientSecret = $ClientSecret
    # $projectId = $ProjectId
    # $environment = $Environment

    # $dxpContainer = $DxpContainer
    $dxpExportBlobsSasLink = $DxpExportBlobsSasLink
    $subscriptionId = $SubscriptionId
    $resourceGroupName = $ResourceGroupName
    $storageAccountName = $StorageAccountName
    $storageAccountContainer = $StorageAccountContainer
    $cleanBeforeCopy = [System.Convert]::ToBoolean($CleanBeforeCopy)

    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #$SourceSasLink = $(DxpBlobsSasLink)
    #$SourceSasLink = Get-Content DxpBlobsSasLink.txt

    Write-Host "Inputs - ImportDxpBlobsToAzure:"
    # Write-Host "ClientKey:                  $clientKey"
    # Write-Host "ClientSecret:               **** (it is a secret...)"
    # Write-Host "ProjectId:                  $projectId"
    # Write-Host "Environment:                $environment"
    # Write-Host "DxpContainer:               $dxpContainer"
    Write-Host "DxpExportBlobsSasLink:      $dxpExportBlobsSasLink"
    Write-Host "SourceSasLink:              $SourceSasLink"
    Write-Host "SubscriptionId:             $subscriptionId"
    Write-Host "ResourceGroupName:          $resourceGroupName"
    Write-Host "StorageAccountName:         $storageAccountName"
    Write-Host "StorageAccountContainer:    $storageAccountContainer"
    Write-Host "CleanBeforeCopy:            $cleanBeforeCopy"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    #Mount-PsModulesPath

    # Initialize-EpiCload

    # Write-DxpHostVersion
    #$sasInfo = Get-SasInfo -SasLink $dxpExportBlobsSasLink

    # Test-DxpProjectId -ProjectId $projectId

    #Set-ExecutionPolicy -Scope CurrentUser Unrestricted
    #Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.5.0 -Verbose
    # Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    # Get-InstalledModule -Name EpinovaAzureToolBucket

    #Install-AzStorage

    #Import-Module Az.Storage
    #Get-InstalledModule -Name Az
    #Import-Module Az.Storage
    #Install-Module -Name Az -AllowClobber -Scope CurrentUser
    #Install-Module Az.Storage
    #Get-InstalledModule -Name Az.Storage


    #Sync-DxpBlobsToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DxpContainer $dxpContainer -Timeout $timeout -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -CleanBeforeCopy $cleanBeforeCopy
    # Copy-BlobsWithSas -SourceSasLink $dxpExportBlobsSasLink -DestinationSubscriptionId $SubscriptionId -DestinationResourceGroupName $ResourceGroupName -DestinationStorageAccountName $StorageAccountName -DestinationContainerName $StorageAccountContainer -CleanBeforeCopy $CleanBeforeCopy

    $sasInfo = Get-SasInfo -SasLink $dxpExportBlobsSasLink

    $sourceContext = New-AzStorageContext -StorageAccountName $sourceStorageAccountName -SASToken $sasInfo.SasToken -ErrorAction Stop
    if ($null -eq $sourceContext) {
        Write-Error "Could not create a context against source storage account $sourceStorageAccountName"
        exit
    }

    $destinationStorageAccount = Get-AzStorageAccount -ResourceGroupName $DestinationResourceGroupName -Name $DestinationStorageAccountName
    if ($null -eq $destinationStorageAccount) {
        Write-Error "Could not create a context against destination storage account $DestinationStorageAccountName"
        exit
    }
    $destinationContext = $destinationStorageAccount.Context 

    if ($true -eq $CleanBeforeCopy){
        Write-Host "Start remove all blobs in $DestinationContainerName."    
        (Get-AzStorageBlob -Container $DestinationContainerName -Context $destinationContext | Sort-Object -Property LastModified -Descending) | Remove-AzStorageBlob
        Write-Host "All blobs in $DestinationContainerName should be removed."    
    }

    Get-AzStorageBlob -Container $sourceContainerName -Context $sourceContext | Start-AzStorageBlobCopy -DestContainer $DestinationContainerName  -Context $destinationContext -Force

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
