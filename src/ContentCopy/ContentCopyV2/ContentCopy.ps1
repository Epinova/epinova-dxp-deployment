[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $Environment,
    $Timeout,
    $IncludeBlob,
    $IncludeDb,
    $RunBenchmark,
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
    $environment = $Environment
    $timeout = $Timeout
    [Boolean]$includeBlob = [System.Convert]::ToBoolean($IncludeBlob)
    [Boolean]$includeDb = [System.Convert]::ToBoolean($IncludeDb)
    $runBenchmark = [System.Convert]::ToBoolean($RunBenchmark)
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # 30 min timeout
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
    Write-Host "Environment:        $environment"
    Write-Host "Timeout:            $timeout"
    Write-Host "IncludeBlob:        $includeBlob"
    Write-Host "IncludeDb:          $includeDb"
    Write-Host "RunBenchmark:       $runBenchmark"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

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
        ProdAde1{
            $sourceEnvironment = "Production"
            $targetEnvironment = "ADE1"
        }
        ProdAde2{
            $sourceEnvironment = "Production"
            $targetEnvironment = "ADE2"
        }
        ProdAde3{
            $sourceEnvironment = "Production"
            $targetEnvironment = "ADE3"
        }
        PrepAde1{
            $sourceEnvironment = "Preproduction"
            $targetEnvironment = "ADE1"
        }
        PrepAde2{
            $sourceEnvironment = "Preproduction"
            $targetEnvironment = "ADE2"
        }
        PrepAde3{
            $sourceEnvironment = "Preproduction"
            $targetEnvironment = "ADE3"
        }
        InteAde1{
            $sourceEnvironment = "Integration"
            $targetEnvironment = "ADE1"
        }
        InteAde2{
            $sourceEnvironment = "Integration"
            $targetEnvironment = "ADE2"
        }
        InteAde3{
            $sourceEnvironment = "Integration"
            $targetEnvironment = "ADE3"
        }
        Ade1Prep{
            $sourceEnvironment = "ADE1"
            $targetEnvironment = "Preproduction"
        }
        Ade2Prep{
            $sourceEnvironment = "ADE2"
            $targetEnvironment = "Preproduction"
        }
        Ade3Prep{
            $sourceEnvironment = "ADE3"
            $targetEnvironment = "Preproduction"
        }
        Ade1Inte{
            $sourceEnvironment = "ADE1"
            $targetEnvironment = "Integration"
        }
        Ade2Inte{
            $sourceEnvironment = "ADE2"
            $targetEnvironment = "Integration"
        }
        Ade3Inte{
            $sourceEnvironment = "ADE3"
            $targetEnvironment = "Integration"
        }
        Ade1Ade2{
            $sourceEnvironment = "ADE1"
            $targetEnvironment = "ADE2"
        }
        Ade1Ade3{
            $sourceEnvironment = "ADE1"
            $targetEnvironment = "ADE3"
        }
        Ade2Ade1{
            $sourceEnvironment = "ADE2"
            $targetEnvironment = "ADE1"
        }
        Ade2Ade3{
            $sourceEnvironment = "ADE2"
            $targetEnvironment = "ADE3"
        }
        Ade3Ade1{
            $sourceEnvironment = "ADE3"
            $targetEnvironment = "ADE1"
        }
        Ade3Ade2{
            $sourceEnvironment = "ADE3"
            $targetEnvironment = "ADE2"
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
            Send-BenchmarkInfo "Bad deploy/Time out"
            Write-Warning "Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "Content copy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Send-BenchmarkInfo "Unhandled status"
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not content copy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploy.id"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"

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