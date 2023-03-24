[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $Urls,
    $ResetOnFail,
    $SleepBeforeStart,
    $NumberOfRetries,
    $SleepBeforeRetry,
    $Timeout,
    $ErrorActionPreference,
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
    $urls = $Urls
    [Boolean]$resetOnFail = [System.Convert]::ToBoolean($ResetOnFail)
    $sleepBeforeStart = $SleepBeforeStart
    $retries = $NumberOfRetries
    $sleepBeforeRetry = $SleepBeforeRetry
    $timeout = $Timeout
    $errorAction = $ErrorActionPreference
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $global:ErrorActionPreference = $errorAction
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
    Write-Host "Urls:               $urls"
    Write-Host "ResetOnFail:        $resetOnFail"
    Write-Host "SleepBeforeStart:   $sleepBeforeStart"
    Write-Host "NumberOfRetries:    $retries"
    Write-Host "SleepBeforeRetry:   $sleepBeforeRetry"
    Write-Host "Timeout:            $timeout"
    Write-Host "ErrorActionPref:    $errorAction"
    Write-Host "RunVerbose:         $runVerbose"

    Write-Host "ErrorActionPref:    $($global:ErrorActionPreference)"

    Write-Host "Start sleep for $($sleepBeforeStart) seconds before we start check URL(s)."
    Start-Sleep $sleepBeforeStart

    $urlsArray = "$urls" -split ','
    Write-Host "Start smoketest $urls"
    $numberOfErrors = 0
    $numberOfRetries = 0
    $retry = $true
    while ($retries -ge $numberOfRetries -and $retry -eq $true){
        $retry = $false
        for ($i = 0; $i -le $urlsArray.Length - 1; $i++) {
            $sw = [Diagnostics.StopWatch]::StartNew()
            $sw.Start()
            $uri = $urlsArray[$i]
            Write-Output "Executing request for URI $uri"
            try {
                $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -Verbose:$false -MaximumRedirection 0
                $sw.Stop()
                $statusCode = $response.StatusCode
                $seconds = $sw.Elapsed.TotalSeconds
                if ($statusCode -eq 200) {
                    $statusDescription = $response.StatusDescription
                    Write-Output "##[ok] $uri => Status: $statusCode $statusDescription in $seconds seconds"
                }
                else {
                    Write-Output "##[warning] $uri => Error $statusCode after $seconds seconds"
                    Write-Output "##vso[task.logissue type=warning;] $uri => Error $statusCode after $seconds seconds"
                    $numberOfErrors = $numberOfErrors + 1
                }
            }
            catch {
                $sw.Stop()
                $errorMessage = $_.Exception.Message
                $seconds = $sw.Elapsed.TotalSeconds
                Write-Output "##vso[task.logissue type=warning;] $uri => Error after $seconds seconds: $errorMessage "
                $numberOfErrors = $numberOfErrors + 1
            }
        }
        
        if ($numberOfErrors -gt 0 -and $numberOfRetries -lt $retries) {
            Write-Host "We found ERRORS. But we will retry in $sleepBeforeRetry seconds."
            $numberOfErrors = 0
            Start-Sleep $sleepBeforeRetry
            $retry = $true
            $numberOfRetries++
        }

    }

    if ($numberOfErrors -gt 0) {
        Write-Host "We found ERRORS. Smoketest fails. We will set reset flag to TRUE."
        Write-Host "##vso[task.setvariable variable=ResetDeployment;]true"
        $resetDeployment = $true
    }
    else {
        Write-Host "We found no errors. Smoketest success. We will set reset flag to false."
        Write-Host "##vso[task.setvariable variable=ResetDeployment;]false"
        $resetDeployment = $false
    }

    if ($resetOnFail -eq $false -and $resetDeployment -eq $true) {
        Send-BenchmarkInfo "Failed"
        Write-Output "##vso[task.logissue type=warning;] Smoke test failed. But ResetOnFail is set to false. No reset will be made."
    } 
    elseif ($resetDeployment -eq $true) {

        Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

        $getEpiDeploymentSplat = @{
            ProjectId = $projectId
        }

        $deploy = Get-EpiDeployment @getEpiDeploymentSplat | Where-Object { $_.Status -eq 'AwaitingVerification' -and $_.parameters.targetEnvironment -eq $targetEnvironment }
        $deploy
        $deploymentId = ""
        if (-not $deploy) {
            Write-Output "Environment $targetEnvironment is not in status AwaitingVerification. We do not need to reset this environment."
        }
        else {
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
                $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Reset" -Timeout $timeout

                if ($status.status -eq "Reset") {
                    Send-BenchmarkInfo "Reset"
                    Write-Host "Deployment $deploymentId has been successfuly reset."
                    Write-Host "##vso[task.logissue type=error]Deployment $deploymentId has been successfuly reset. But we can not continue deploy when we have reset the deployment."
                    Write-Error "Deployment $deploymentId has been successfuly reset. But we can not continue deploy when we have reset the deployment." -ErrorAction Stop
                    exit 1
                }
                else {
                    Send-BenchmarkInfo "Bad deploy/Time out"
                    Write-Warning "The reset has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                    Write-Host "##vso[task.logissue type=error]The reset has not been successful or the script has timedout. CurrentStatus: $($status.status)"
                    Write-Error "Deployment $deploymentId has NOT been successfuly reset or the script has timedout. CurrentStatus: $($status.status)" -ErrorAction Stop
                    exit 1
                }
            }
            elseif ($status.status -eq "Reset") {
                Send-BenchmarkInfo "Succeeded"
                Write-Host "The deployment $deploymentId is already in reset status."
                Write-Host "##vso[task.logissue type=error]Deployment $deploymentId is already in reset status. But we can not continue deploy when we have found errors in the smoke test."
                Write-Error "Deployment $deploymentId is already in reset status. But we can not continue deploy when we have found errors in the smoke test." -ErrorAction Stop
                exit 1
            }
            else {
                Send-BenchmarkInfo "Unhandled status"
                Write-Host "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
                Write-Host "##vso[task.logissue type=error]Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment."
                Write-Error "Status is not in AwaitingVerification (Current:$($status.status)). You can not reset the deployment at this moment." -ErrorAction Stop
                exit 1
            }
        }
    }
    else {
        Send-BenchmarkInfo "Succeeded"
        Write-Host "The deployment will not be reset. Smoketest is success."
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