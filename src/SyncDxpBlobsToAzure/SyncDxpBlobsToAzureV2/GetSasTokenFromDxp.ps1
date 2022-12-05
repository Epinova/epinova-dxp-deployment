[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $DxpContainer,

    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $environment = $Environment
    $dxpContainer = $DxpContainer

    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
    ####################################################################################

    if ($runVerbose){
        ## To Set Verbose output
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $RetentionHours = 2 # Set the retantion hours to 2h. Should be good enough to sync the blobs

    Write-Host "Inputs: - GetSasTokenFromDxp"
    Write-Host "ClientKey:                  $clientKey"
    Write-Host "ClientSecret:               **** (it is a secret...)"
    Write-Host "ProjectId:                  $projectId"
    Write-Host "Environment:                $environment"
    Write-Host "DxpContainer:               $dxpContainer"
    Write-Host "Timeout:                    $timeout"
    Write-Host "RunVerbose:                 $runVerbose"
    Write-Host "RetentionHours:             $RetentionHours"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Mount-PsModulesPath

    Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

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

    if ($null -ne $SourceSasLink){
        Write-Host "Setvariable DxpBlobsSasLink: $SourceSasLink"
        Write-Host "##vso[task.setvariable variable=DxpBlobsSasLink;]$SourceSasLink"

        New-Item DxpBlobsSasLink.txt
        Set-Content DxpBlobsSasLink.txt "$SourceSasLink"
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
