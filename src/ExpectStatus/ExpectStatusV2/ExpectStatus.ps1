[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $ExpectedStatus,
    $Timeout,
    $RunVerbose
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $expectedStatus = $ExpectedStatus
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
    Write-Host "ExpectedStatus:     $expectedStatus"
    Write-Host "Timeout:            $timeout"
    Write-Host "RunVerbose:         $runVerbose"


    $deployUtilScript = Join-Path -Path $PSScriptRoot -ChildPath "ps_modules"
    $deployUtilScript = Join-Path -Path $deployUtilScript -ChildPath "EpinovaDxpDeploymentUtil.ps1"
    . $deployUtilScript

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()


    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $psContext = Write-ContextInfo -ProjectId $projectId -Environment $targetEnvironment
    # Mount-PsModulesPath

    # Write-ContextInfo

    # Initialize-EpiCload
    
    # Write-DxpHostVersion

    # Test-DxpProjectId -ProjectId $projectId

    # Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $lastDeploy = Get-DxpLatestEnvironmentDeployment -ProjectId $projectId -TargetEnvironment $targetEnvironment

    if ($null -ne $lastDeploy){
        Write-Output $lastDeploy | ConvertTo-Json
        Write-Output "Latest found deploy on targetEnvironment $targetEnvironment is in status $($lastDeploy.status)"

        $inExpectedStatus = $false
        if ($lastDeploy.status -eq $expectedStatus) {
            $inExpectedStatus = $true
        }
        elseif ($expectedStatus -eq "SucceededOrReset") {
            if ($lastDeploy.status -eq "Succeeded" -or $lastDeploy.status -eq "Reset") {
                $inExpectedStatus = $true
            }
        }

        if ($true -eq $inExpectedStatus) {
            Write-Host "Status is as expected."
        }
        else {
            Write-Warning "$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))."
            Write-Host "##vso[task.logissue type=error]$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))."
            Write-Error "$targetEnvironment is not in expected status $expectedStatus. (Current:$($lastDeploy.status))." -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Output "No history received from the specified target environment $targetEnvironment"
        Write-Output "Will and can not do anything..."
    }

    $sw.Stop()
    $elapsed = $sw.Elapsed.TotalSeconds
    Write-ContextInfo -ProjectId $projectId -Environment $targetEnvironment -Elapsed $elapsed -Result "Some status" -FileSize 0
    #Write-ResultInfo $psContext
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