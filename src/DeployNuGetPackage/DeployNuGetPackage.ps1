Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    $useMaintenancePage = Get-VstsInput -Name "UseMaintenancePage" -AsBool
    $dropPath = Get-VstsInput -Name "DropPath" -Require -ErrorAction "Stop"
    #$includeBlob = $false #switches to copy BLOBs from source to target environment
    #$includeDb = $false #switched to copy the DB from source to target environment
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    # 30 min timeout
    ####################################################################################

    . "$PSScriptRoot\Helper.ps1"
    WriteInfo

    $env:PSModulePath = "C:\Modules\azurerm_6.7.0;" + $env:PSModulePath

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Install-Module EpiCloud -Scope CurrentUser -Force
    }

    Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret

    $resolvedPackagePath = Get-ChildItem -Path $dropPath -Filter *.nupkg
    Write-Host "resolvedPackagePath: $resolvedPackagePath"

    $packageLocation = Get-EpiDeploymentPackageLocation -ProjectId $projectId
    Write-Host "packageLocation: $packageLocation"

    Add-EpiDeploymentPackage -SasUrl $packageLocation -Path $resolvedPackagePath.FullName

    $startEpiDeploymentSplat = @{
        DeploymentPackage  = $resolvedPackagePath.Name
        ProjectId          = $projectId
        TargetEnvironment  = $targetEnvironment
        UseMaintenancePage = $useMaintenancePage
    }

    $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    $deploy

    $deploymentId = $deploy.id

    if ($deploy.status -eq "InProgress") {

        $percentComplete = $deploy.percentComplete

        $status = Progress -projectid $projectId -deploymentId $deploymentId -percentComplete $percentComplete -expectedStatus "AwaitingVerification" -timeout $timeout

        if ($status.status -eq "AwaitingVerification") {
            Write-Host "Deployment $deploymentId has been successful."
        }
        else {
            Write-Warning "The deploy has not been successful or the script has timedout."
            Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timedout."
            Write-Error "The deploy has not been successful or the script has timedout." -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploy.id"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"

    ####################################################################################

    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
