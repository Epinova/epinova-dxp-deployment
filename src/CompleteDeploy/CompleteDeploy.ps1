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

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
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

    if (-not ($env:PSModulePath.Contains("$PSScriptRoot\ps_modules"))){
        $env:PSModulePath = "$PSScriptRoot\ps_modules;" + $env:PSModulePath   
    }

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Write-Host "Could not find EpiCloud. Installing it."
        Install-Module EpiCloud -Scope CurrentUser -Force
    } else {
        Write-Host "EpiCloud installed."
    }


    Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret

    $getEpiDeploymentSplat = @{
        ProjectId    = $projectId
    }

    $deploy = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $targetEnvironment }
    $deploy
    if (-not $deploy) {
        Write-Host "##vso[task.logissue type=error]Failed to locate a deployment in $targetEnvironment to complete!"
        exit 1
    }
    else {
        $deploymentId = $deploy.id
        Write-Host "Set variable DeploymentId: $deploymentId"
        Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"
    }

    if ($deploymentId.length -gt 1) {
        $completeEpiDeploymentSplat = @{
            ProjectId = $projectId
            Id        = "$deploymentId"
        }

        Write-Host "Start complete deployment $deploymentId"
        $complete = Complete-EpiDeployment @completeEpiDeploymentSplat
        $complete

        if ($complete.status -eq "Completing") {
            $deployDateTime = GetDateTimeStamp
            Write-Host "Complete $deploymentId started $deployDateTime."
    
            $percentComplete = $complete.percentComplete

            $status = Progress -projectid $projectId -deploymentId $deploymentId -percentComplete $percentComplete -expectedStatus "Succeeded" -timeout $timeout

            $deployDateTime = GetDateTimeStamp
            Write-Host "Complete $deploymentId ended $deployDateTime"
    
            if ($status.status -eq "Succeeded") {
                Write-Host "Deployment $deploymentId has been completed."
            }
            else {
                Write-Warning "The completion for deployment $deploymentId has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The completion for deployment $deploymentId has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                Write-Error "The completion for deployment $deploymentId has not been successful or the script has timedout. CurrentStatus: $($status.status)" -ErrorAction Stop
                exit 1
            }
        }
        elseif ($complete.status -eq "Succeeded") {
            Write-Host "The deployment $deploymentId is already in Succeeded status."
        }
        else {
            Write-Warning "Status is not in complete (Current:$($complete.status)). Something is strange..."
            Write-Host "##vso[task.logissue type=error]Status is not in complete (Current:$($complete.status)). Something is strange..."
            Write-Error "Status is not in complete (Current:$($complete.status)). Something is strange..." -ErrorAction Stop
            exit 1
        }

    }
    else {
        Write-Host "##vso[task.logissue type=error]Could not retrieve the DeploymentId variable. Can not complete the deployment."
        exit 1
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

