Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    $expectedStatus = Get-VstsInput -Name "ExpectedStatus" -Require -ErrorAction "Stop"
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    ####################################################################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Inputs:"
    Write-Host "ClientKey: $clientKey"
    Write-Host "ClientSecret: **** (it is a secret...)"
    Write-Host "ProjectId: $projectId"
    Write-Host "TargetEnvironment: $targetEnvironment"
    Write-Host "ExpectedStatus: $expectedStatus"
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

    try{
        #if (-not (Get-Module -Name EpinovaDxpDeploymentUtil -ListAvailable)) {
        #    Write-Host "Could not find EpinovaDxpDeploymentUtil. Installing it."
            Import-module EpinovaDxpDeploymentUtil -Scope CurrentUser -Force
        #} else {
        #    Write-Host "EpinovaDxpDeploymentUtil installed."
            #Update-Module -Name EpinovaDxpDeploymentUtil -RequiredVersion 0.0.2
            Get-Module -Name EpinovaDxpDeploymentUtil -ListAvailable
        #}
        Write-DxpHostInfo
    }
    catch{
        $errorMessage = $_.Exception.Message
        Write-Host $errorMessage
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

        if ($lastDeploy.status -eq $expectedStatus) {
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

