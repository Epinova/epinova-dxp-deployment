Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $sourceEnvironment = Get-VstsInput -Name "SourceEnvironment" -Require -ErrorAction "Stop"
    $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    $sourceApp = Get-VstsInput -Name "SourceApp" -Require -ErrorAction "Stop"
    $useMaintenancePage = Get-VstsInput -Name "UseMaintenancePage" -AsBool
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    # 30 min timeout
    ####################################################################################

    . "$PSScriptRoot\Helper.ps1"
    WriteInfo

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Install-Module EpiCloud -Scope CurrentUser -Force
    }

    Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret

    $startEpiDeploymentSplat = @{
        ProjectId          = $projectId
        SourceEnvironment  = $sourceEnvironment
        TargetEnvironment  = $targetEnvironment
        SourceApp          = $sourceApp
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

