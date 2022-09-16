[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

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
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Mount-PsModulesPath

    Initialize-EpiCload

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $lastDeploy = Get-DxpLatestEnvironmentDeployment -ProjectId $projectId -TargetEnvironment $targetEnvironment

    if ($null -ne $lastDeploy){
        Write-Output $lastDeploy | ConvertTo-Json
        Write-Output "Latest found deploy on targetEnvironment $targetEnvironment is in status $($lastDeploy.status)"

        if ($lastDeploy.status -eq "InProgress" -or $lastDeploy.status -eq "Resetting") {
            $deployDateTime = Get-DxpDateTimeStamp
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

            $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Deploy $deploymentId ended $deployDateTime"

            if ($status.status -eq "AwaitingVerification") {
                Write-Host "Deployment $deploymentId has been successful."
            }
            elseif ($status.status -eq "Reset") {
                Write-Host "Reset $deploymentId has been successful."
            }
            else {
                Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
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
        Write-Output "Will and can not do anything..."
    }

    ####################################################################################

    Write-Host "---THE END---"
}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
# finally {
#     Trace-VstsLeavingInvocation $MyInvocation
# }

if ($runVerbose){
    ## To Set Verbose output
    $PSDefaultParameterValues['*:Verbose'] = $false
}