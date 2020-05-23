Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    # 30 min timeout
    ####################################################################################

    Write-Host "Inputs:"
    Write-Host "ClientKey: $clientKey"
    Write-Host "ClientSecret: **** (it is a secret...)"
    Write-Host "ProjectId: $projectId"
    Write-Host "TargetEnvironment: $targetEnvironment"
    Write-Host "Timeout: $timeout"

    . "$PSScriptRoot\Helper.ps1"
    WriteInfo

    if ((Test-IsGuid -ObjectGuid $projectId) -ne $true){
        Write-Error "The provided ProjectId is not a guid value."
    }

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Install-Module EpiCloud -Scope CurrentUser -Force
    }

    Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret

    $getEpiDeploymentSplat = @{
        ProjectId    = $projectId
    }

    $deploy = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $targetEnvironment }
    $deploy
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


        $status = Get-EpiDeployment -ProjectId $projectId -Id $deploymentId
        $status

        if ($status.status -eq "AwaitingVerification") {

            Write-Host "Start Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId"
            Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId

            $percentComplete = $status.percentComplete

            $status = Progress -projectid $projectId -deploymentId $deploymentId -percentComplete $percentComplete -expectedStatus "Reset" -timeout $timeout

            if ($status.status -eq "Reset") {
                Write-Host "Deployment $deploymentId has been successfuly reset."
            }
            else {
                Write-Warning "The reset has not been successful or the script has timedout."
                Write-Host "##vso[task.logissue type=error]The reset has not been successful or the script has timedout."
                Write-Error "The reset has not been successful or the script has timedout." -ErrorAction Stop
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

