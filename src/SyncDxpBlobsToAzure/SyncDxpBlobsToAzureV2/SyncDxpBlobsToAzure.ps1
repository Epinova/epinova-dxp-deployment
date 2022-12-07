[CmdletBinding()]
Param(
    # $ClientKey,
    # $ClientSecret,
    # $ProjectId, 
    # $Environment,
    # $DxpContainer,
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
    $SourceSasLink = Get-Content DxpBlobsSasLink.txt

    Write-Host "Inputs - SyncDxpBlobsToAzure:"
    # Write-Host "ClientKey:                  $clientKey"
    # Write-Host "ClientSecret:               **** (it is a secret...)"
    # Write-Host "ProjectId:                  $projectId"
    # Write-Host "Environment:                $environment"
    # Write-Host "DxpContainer:               $dxpContainer"
    Write-Host "SourceSasLink:              $SourceSasLink"
    Write-Host "SubscriptionId:             $subscriptionId"
    Write-Host "ResourceGroupName:          $resourceGroupName"
    Write-Host "StorageAccountName:         $storageAccountName"
    Write-Host "StorageAccountContainer:    $storageAccountContainer"
    Write-Host "CleanBeforeCopy:            $cleanBeforeCopy"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"

    #. "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    #Mount-PsModulesPath

    # Initialize-EpiCload

    # Write-DxpHostVersion

    # Test-DxpProjectId -ProjectId $projectId

    #Set-ExecutionPolicy -Scope CurrentUser Unrestricted
    #Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.5.0 -Verbose
    Install-Module EpinovaAzureToolBucket -Scope CurrentUser -Force
    Get-InstalledModule -Name EpinovaAzureToolBucket

    #Install-AzStorage

    #Import-Module Az.Storage
    #Get-InstalledModule -Name Az
    #Import-Module Az.Storage
    #Install-Module -Name Az -AllowClobber -Scope CurrentUser
    #Install-Module Az.Storage
    #Get-InstalledModule -Name Az.Storage

    Import-AzStorageModule

    #Sync-DxpBlobsToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $environment -DxpContainer $dxpContainer -Timeout $timeout -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName -StorageAccountContainer $storageAccountContainer -CleanBeforeCopy $cleanBeforeCopy
    Copy-BlobsWithSas -SourceSasLink $SourceSasLink -DestinationSubscriptionId $SubscriptionId -DestinationResourceGroupName $ResourceGroupName -DestinationStorageAccountName $StorageAccountName -DestinationContainerName $StorageAccountContainer -CleanBeforeCopy $CleanBeforeCopy


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
