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
    $deployUtilScript = Join-Path -Path $PSScriptRoot -ChildPath "ps_modules"
    $deployUtilScript = Join-Path -Path $deployUtilScript -ChildPath "EpinovaDxpDeploymentUtil.ps1"
    . $deployUtilScript

    # Get all inputs for the task
    Initialize-Params
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $timeout = $Timeout
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    ####################################################################################

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()

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

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    # . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    # Mount-PsModulesPath

    # Initialize-EpiCload

    # Write-DxpHostVersion

    # Test-DxpProjectId -ProjectId $projectId

    # Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $deploy = Get-DxpAwaitingEnvironmentDeployment -ProjectId $projectId -TargetEnvironment $targetEnvironment
    $deploy
    if (-not $deploy) {
        Write-Host "##vso[task.logissue type=error]Failed to locate a deployment in $targetEnvironment to complete!"
        Send-BenchmarkInfo "Failed to locate a deployment"
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
            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Complete deploy $deploymentId started $deployDateTime."
    
            $percentComplete = $complete.percentComplete
            $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Succeeded" -Timeout $timeout

            $deployDateTime = Get-DxpDateTimeStamp
            Write-Host "Complete deploy $deploymentId ended $deployDateTime"
    
            if ($status.status -eq "Succeeded") {
                Write-Host "Deployment $deploymentId has been completed."
            }
            else {
                Write-Warning "The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Host "##vso[task.logissue type=error]The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)"
                Write-Error "The completion for deployment $deploymentId has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
                Send-BenchmarkInfo "Bad deploy/Time out"
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
            Send-BenchmarkInfo "Unhandled status"
            exit 1
        }

    }
    else {
        Write-Host "##vso[task.logissue type=error]Could not retrieve the DeploymentId variable. Can not complete the deployment."
        Send-BenchmarkInfo "No DeploymentId"
        exit 1
    }

    Send-BenchmarkInfo "Succeeded"
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