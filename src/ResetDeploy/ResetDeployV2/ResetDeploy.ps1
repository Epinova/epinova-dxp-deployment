[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $Timeout
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout

    # 30 min timeout
    ####################################################################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Timeout:            $timeout"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    #Install-AzStorage
     
    Mount-PsModulesPath

    Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $deploy = Get-DxpAwaitingEnvironmentDeployment -ProjectId $projectId -TargetEnvironment $targetEnvironment
    $deploy
    $deploymentId = ""
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
            $deployDateTime = Get-DxpDateTimeStamp
    
            Write-Host "Start Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId ($deployDateTime)"
            Reset-EpiDeployment -ProjectId $projectId -Id $deploymentId

            $percentComplete = $status.percentComplete
            $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Reset" -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Reset $deploymentId ended $deployDateTime"
    
            if ($status.status -eq "Reset") {
                Write-Host "Deployment $deploymentId has been successfuly reset."
            }
            else {
                Write-Warning "The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The reset has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
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

