Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $environment = Get-VstsInput -Name "Environment" -Require -ErrorAction "Stop"
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"
    $includeBlob = Get-VstsInput -Name "IncludeBlob" -AsBool
    $includeDb = Get-VstsInput -Name "IncludeDb" -AsBool

    # 30 min timeout
    ####################################################################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "Environment:        $environment"
    Write-Host "Timeout:            $timeout"
    Write-Host "IncludeBlob:        $includeBlob"
    Write-Host "IncludeDb:          $includeDb"

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

    switch ($environment){
        ProdPrep{
            $sourceEnvironment = "Production"
            $targetEnvironment = "Preproduction"
        }
        ProdInte{
            $sourceEnvironment = "Production"
            $targetEnvironment = "Integration"
        }
        PrepInte{
            $sourceEnvironment = "Preproduction"
            $targetEnvironment = "Integration"
        }
        IntePrep{
            $sourceEnvironment = "Integration"
            $targetEnvironment = "Preproduction"
        }
    }

    $startEpiDeploymentSplat = @{
        ProjectId          = $projectId
        SourceEnvironment  = $sourceEnvironment
        TargetEnvironment  = $targetEnvironment
        IncludeBlob = $includeBlob
        IncludeDb = $includeDb
    }

    $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    $deploy

    $deploymentId = $deploy.id

    if ($deploy.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Content copy $deploymentId started $deployDateTime."
        $percentComplete = $deploy.percentComplete
        $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "Succeeded" -Timeout $timeout

        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Content copy $deploymentId ended $deployDateTime"

        if ($status.status -eq "Succeeded") {
            Write-Host "Content copy $deploymentId has been successful."
        }
        else {
            Write-Warning "Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploy.id"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"

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

