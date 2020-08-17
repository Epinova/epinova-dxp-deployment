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

    $deploy = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.parameters.targetEnvironment -eq $targetEnvironment }

    if ($deploy.Count -gt 1){
        $lastDeploy = $deploy[0]
        Write-Output $lastDeploy | ConvertTo-Json
        Write-Output "Latest found deploy on targetEnvironment $targetEnvironment is in status $($lastDeploy.status)"

        if ($lastDeploy.status -eq "InProgress" -or $lastDeploy.status -eq "Resetting") {
            $deployDateTime = GetDateTimeStamp
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

            $status = Progress -projectid $projectId -deploymentId $deploymentId -percentComplete $percentComplete -expectedStatus $expectedStatus -timeout $timeout

            $deployDateTime = GetDateTimeStamp
            Write-Host "Deploy $deploymentId ended $deployDateTime"

            if ($status.status -eq "AwaitingVerification") {
                Write-Host "Deployment $deploymentId has been successful."
            }
            elseif ($status.status -eq "Reset") {
                Write-Host "Reset $deploymentId has been successful."
            }
            else {
                Write-Warning "The deploy has not been successful or the script has timedout."
                Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timedout."
                Write-Error "The deploy has not been successful or the script has timedout." -ErrorAction Stop
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
        Write-Output "Will and can´t do anything..."
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

