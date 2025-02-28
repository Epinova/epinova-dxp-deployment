[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $SourceApp,
    $DirectDeploy,
    $WarmUpUrl,
    $UseMaintenancePage,
    $DropPath,
    $Timeout,
    $ZeroDowntimeMode,
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
    $targetEnvironment = $TargetEnvironment
    $sourceApp = $SourceApp
    [bool]$directDeploy = [System.Convert]::ToBoolean($DirectDeploy)
    $warmupThisUrl = $WarmUpUrl
    [bool]$useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $dropPath = $DropPath
    $timeout = $Timeout
    $zeroDowntimeMode = $ZeroDowntimeMode
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
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "SourceApp:          $sourceApp"
    Write-Host "DirectDeploy:       $directDeploy"
    Write-Host "Warm-up URL:        $warmupThisUrl"
    Write-Host "UseMaintenancePage: $useMaintenancePage"
    Write-Host "DropPath:           $dropPath"
    Write-Host "Timeout:            $timeout"
    Write-Host "ZeroDowntimeMode:   $zeroDowntimeMode"
    Write-Host "RunBenchmark:       $runBenchmark"
    Write-Host "RunVerbose:         $runVerbose"

    Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    if (($targetEnvironment -eq "Preproduction" -or $targetEnvironment -eq "Production") -and $directDeploy){
        Write-Host "DirectDeploy does only support target environment = Integration|ADE* at the moment. Will set the DirectDeploy=false."
        $directDeploy = $false
    }

    $packageLocation = Get-EpiDeploymentPackageLocation -ProjectId $projectId
    Write-Host "PackageLocation:    $packageLocation"

    $uploadedCmsPackage = $null
    $myPackages = $null
    if ($sourceApp -eq "cms" -or $sourceApp -eq "cms,commerce"){
        $uploadedCmsPackage = Publish-Package -PackageType "cms" -DropPath $dropPath -PackageLocation $packageLocation
        if ($uploadedCmsPackage){
            $myPackages = $uploadedCmsPackage
            $cmsFileSize = Get-PackageFileSize -DropPath $dropPath -PackageFileName $uploadedCmsPackage
            $cmsPackage = $uploadedCmsPackage
        }
    }
    $uploadedCommercePackage = $null
    if ($sourceApp -eq "commerce" -or $sourceApp -eq "cms,commerce"){
        $uploadedCommercePackage = Publish-Package -PackageType "commerce" -DropPath $dropPath -PackageLocation $packageLocation
        if ($uploadedCommercePackage){
            $myPackages = $uploadedCommercePackage
            $commerceFileSize = Get-PackageFileSize -DropPath $dropPath -PackageFileName $uploadedCommercePackage
            $commercePackage = $uploadedCommercePackage
        }
    }

    if ($uploadedCmsPackage -and $uploadedCommercePackage){
        $myPackages = $uploadedCmsPackage, $uploadedCommercePackage
    }

    if ($null -eq $zeroDowntimeMode -or $zeroDowntimeMode -eq "" -or $zeroDowntimeMode -eq "NotSpecified" -or $zeroDowntimeMode -eq "NotApplicable") {
        $startEpiDeploymentSplat = @{
            DeploymentPackage  = $myPackages
            ProjectId          = $projectId
            TargetEnvironment  = $targetEnvironment
            UseMaintenancePage = $useMaintenancePage
        }
    } else {
        $startEpiDeploymentSplat = @{
            DeploymentPackage  = $myPackages
            ProjectId          = $projectId
            TargetEnvironment  = $targetEnvironment
            UseMaintenancePage = $useMaintenancePage
            ZeroDowntimeMode   = $zeroDowntimeMode
        }
    }


    if ($true -eq $directDeploy){
        $expectedStatus = "Succeeded"
        $deploy = Start-EpiDeployment @startEpiDeploymentSplat -DirectDeploy
    } else {
        $expectedStatus = "AwaitingVerification"
        $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    }
    $deploy

    $deploymentId = $deploy.id

    if ($deploy.status -eq "InProgress") {
        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId started $deployDateTime."

        $percentComplete = $deploy.percentComplete

        $status = Invoke-DxpProgress -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus $expectedStatus -Timeout $timeout

        $deployDateTime = Get-DxpDateTimeStamp
        Write-Host "Deploy $deploymentId ended $deployDateTime"

        if ($status.status -eq $expectedStatus) {
            Write-Host "Deployment $deploymentId has been successful."

            if ($warmupThisUrl){
                Invoke-WarmupSite $warmupThisUrl
            }
        }
        else {
            Send-BenchmarkInfo "Bad deploy/Time out"
            Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Send-BenchmarkInfo "Unhandled status"
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploymentId"
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
