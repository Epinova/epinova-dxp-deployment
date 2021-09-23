[CmdletBinding()]
Param(
    $ClientKey,
    $ClientSecret,
    $ProjectId, 
    $TargetEnvironment,
    $SourceApp,
    $DirectDeploy,
    $UseMaintenancePage,
    $DropPath,
    $Timeout,
    $ZeroDowntimeMode
)

try {
    # Get all inputs for the task
    $clientKey = $ClientKey
    $clientSecret = $ClientSecret
    $projectId = $ProjectId
    $targetEnvironment = $TargetEnvironment
    $sourceApp = $SourceApp
    [Boolean]$directDeploy = [System.Convert]::ToBoolean($DirectDeploy)
    [Boolean]$useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $dropPath = $DropPath
    $timeout = $Timeout
    $zeroDowntimeMode = $ZeroDowntimeMode

    # 30 min timeout
    ####################################################################################

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "Inputs:"
    Write-Host "ClientKey:          $clientKey"
    Write-Host "ClientSecret:       **** (it is a secret...)"
    Write-Host "ProjectId:          $projectId"
    Write-Host "TargetEnvironment:  $targetEnvironment"
    Write-Host "SourceApp:          $sourceApp"
    Write-Host "DirectDeploy:       $directDeploy"
    Write-Host "UseMaintenancePage: $useMaintenancePage"
    Write-Host "DropPath:           $dropPath"
    Write-Host "Timeout:            $timeout"
    Write-Host "ZeroDowntimeMode:   $zeroDowntimeMode"

    . "$PSScriptRoot\ps_modules\EpinovaDxpDeploymentUtil.ps1"

    Install-AzStorage
     
    Mount-PsModulesPath

    # if (-not ($env:PSModulePath.Contains("C:\Modules\azurerm_6.7.0"))){
    #     $env:PSModulePath = "C:\Modules\azurerm_6.7.0;" + $env:PSModulePath   
    # }

    Initialize-EpiCload

    if ($targetEnvironment -ne "Integration" -and $directDeploy){
        Write-Host "DirectDeploy does only support target environment = Integration at the moment. Will set the DirectDeploy=false."
        $directDeploy = $false
    }

    Write-DxpHostVersion

    Test-DxpProjectId -ProjectId $projectId

    Connect-DxpEpiCloud -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    $packageLocation = Get-EpiDeploymentPackageLocation -ProjectId $projectId
    Write-Host "PackageLocation:    $packageLocation"

    $resolvedCmsPackagePath = $null
    if ($sourceApp -eq "cms" -or $sourceApp -eq "cms,commerce"){
        $resolvedCmsPackagePath = Get-ChildItem -Path $dropPath -Filter *.cms.*.nupkg
        Write-Host "Cms PackagePath:    $resolvedCmsPackagePath"
    
        if ($null -eq $resolvedCmsPackagePath){
            Write-Host "Following files found in location $dropPath : $(Get-ChildItem -Path $dropPath -File)"
            Write-Host "##vso[task.logissue type=error]Could not find the cms package in location $dropPath."
            Write-Error "Could not find the cms package in location $dropPath." -ErrorAction Stop
            exit 1
        }
    
        Add-EpiDeploymentPackage -SasUrl $packageLocation -Path $resolvedCmsPackagePath.FullName
        Write-Host "cms package $resolvedCmsPackagePath is uploaded."
        $myPackages = $resolvedCmsPackagePath.Name
    }

    $resolvedCommercePackagePath = $null
    if ($sourceApp -eq "commerce" -or $sourceApp -eq "cms,commerce"){
        $resolvedCommercePackagePath = Get-ChildItem -Path $dropPath -Filter *.commerce.*.nupkg
        Write-Host "Commerce PackagePath: $resolvedCommercePackagePath"
    
        if ($null -eq $resolvedCommercePackagePath){
            Write-Host "Following files found in location $dropPath : $(Get-ChildItem -Path $dropPath -File)"
            Write-Host "##vso[task.logissue type=error]Could not find the commerce package in location $dropPath."
            Write-Error "Could not find the commerce package in location $dropPath." -ErrorAction Stop
            exit 1
        }
    
        Add-EpiDeploymentPackage -SasUrl $packageLocation -Path $resolvedCommercePackagePath.FullName
        Write-Host "commerce package $resolvedCommercePackagePath is uploaded."
        $myPackages = $resolvedCommercePackagePath.Name
    }

    if ($null -ne $resolvedCmsPackagePath -and $null -ne $resolvedCommercePackagePath){
        $myPackages = $resolvedCmsPackagePath, $resolvedCommercePackagePath
    }

    if ($null -eq $zeroDowntimeMode -or $zeroDowntimeMode -eq "" -or $zeroDowntimeMode -eq "Not specified") {
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
        }
        else {
            Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
            Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
            exit 1
        }
    }
    else {
        Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
        Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
        exit 1
    }
    Write-Host "Setvariable DeploymentId: $deploymentId"
    Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"

    ####################################################################################

    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
