[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $ExpectedStatus,
    $Timeout
)

Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
#$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    # $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    # $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    # $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    # $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    # $expectedStatus = Get-VstsInput -Name "ExpectedStatus" -Require -ErrorAction "Stop"
    # $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $expectedStatus = $ExpectedStatus
    $timeout = $Timeout

    ####################################################################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "ExpectedStatus:     $expectedStatus"
    Write-Host "Timeout:            $timeout"

    . "$PSScriptRoot\EpinovaDxpDeploymentUtil.ps1"

    # TEMP code
    Install-AzureStorage
        
    if (-not ($env:PSModulePath.Contains("$PSScriptRoot\ps_modules"))){
        $env:PSModulePath = "$PSScriptRoot\ps_modules;" + $env:PSModulePath   
    }

    Initialize-EpiCload
    
    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

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

