try {
    $useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $includeBlob = [System.Convert]::ToBoolean($IncludeBlob)
    $includeDb = [System.Convert]::ToBoolean($IncludeDb)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

	#Uninstall-Module -Name "EpinovaDxpToolBucket" -AllVersions -Force
    Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.13.0 -Force
    $module = Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable | Select-Object Version
    $moduleVersion = "v$($module.Version.Major).$($module.Version.Minor).$($module.Version.Build)"
    Write-Host "EpinovaDxpToolBucket: $moduleVersion"

    Invoke-DxpDeployTo -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -SourceEnvironment $SourceEnvironment -TargetEnvironment $TargetEnvironment -SourceApp $SourceApp -UseMaintenancePage $useMaintenancePage -IncludeBlob $includeBlob -IncludeDb $includeDb -ZeroDowntimeMode $ZeroDowntimeMode -Timeout $Timeout -RunVerbose $runVerbose

    # Get all inputs for the task
    # $clientKey = $ClientKey
    # $clientSecret = $ClientSecret
    # $projectId = $ProjectId
    # $sourceEnvironment = $SourceEnvironment
    # $targetEnvironment = $TargetEnvironment
    # $sourceApp = $SourceApp
    # [Boolean]$useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    # $timeout = $Timeout
    # [Boolean]$includeBlob = [System.Convert]::ToBoolean($IncludeBlob)
    # [Boolean]$includeDb = [System.Convert]::ToBoolean($IncludeDb)
    # $zeroDowntimeMode = $ZeroDowntimeMode
    # $runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    # # 30 min timeout
    # ####################################################################################

    # $sw = [Diagnostics.Stopwatch]::StartNew()
    # $sw.Start()

    # if ($runVerbose){
    #     ## To Set Verbose output
    #     $PSDefaultParameterValues['*:Verbose'] = $true
    # }

    # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Write-Host "Inputs:"
    # Write-Host "ClientKey:          $clientKey"
    # Write-Host "ClientSecret:       **** (it is a secret...)"
    # Write-Host "ProjectId:          $projectId"
    # Write-Host "SourceEnvironment:  $sourceEnvironment"
    # Write-Host "TargetEnvironment:  $targetEnvironment"
    # Write-Host "SourceApp:          $sourceApp"
    # Write-Host "UseMaintenancePage: $useMaintenancePage"
    # Write-Host "Timeout:            $timeout"
    # Write-Host "IncludeBlob:        $includeBlob"
    # Write-Host "IncludeDb:          $includeDb"
    # Write-Host "ZeroDowntimeMode:   $zeroDowntimeMode"
    # Write-Host "RunVerbose:         $runVerbose"

    # Initialize-EpinovaDxpScript -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId

    # $sourceApps = $sourceApp.Split(",")

    # if ($null -eq $zeroDowntimeMode -or $zeroDowntimeMode -eq "" -or $zeroDowntimeMode -eq "NotSpecified") {
    #     $startEpiDeploymentSplat = @{
    #         ClientKey          = $ClientKey
    #         ClientSecret       = $ClientSecret
    #         ProjectId          = $projectId
    #         SourceEnvironment  = $sourceEnvironment
    #         TargetEnvironment  = $targetEnvironment
    #         SourceApp          = $sourceApps
    #         UseMaintenancePage = $useMaintenancePage
    #         IncludeBlob = $includeBlob
    #         IncludeDb = $includeDb
    #     }
    # } else {
    #     $startEpiDeploymentSplat = @{
    #         ClientKey          = $ClientKey
    #         ClientSecret       = $ClientSecret
    #         ProjectId          = $projectId
    #         SourceEnvironment  = $sourceEnvironment
    #         TargetEnvironment  = $targetEnvironment
    #         SourceApp          = $sourceApps
    #         UseMaintenancePage = $useMaintenancePage
    #         IncludeBlob = $includeBlob
    #         IncludeDb = $includeDb
    #         ZeroDowntimeMode = $zeroDowntimeMode
    #     }
    # }

    # $deploy = Start-EpiDeployment @startEpiDeploymentSplat
    # $deploy

    # $deploymentId = $deploy.id

    # if ($deploy.status -eq "InProgress") {
    #     $deployDateTime = Get-DxpDateTimeStamp
    #     Write-Host "Deploy $deploymentId started $deployDateTime."
    #     $percentComplete = $deploy.percentComplete
    #     $status = Invoke-DxpProgress -ClientKey $clientKey -ClientSecret $clientSecret -Projectid $projectId -DeploymentId $deploymentId -PercentComplete $percentComplete -ExpectedStatus "AwaitingVerification" -Timeout $timeout

    #     $deployDateTime = Get-DxpDateTimeStamp
    #     Write-Host "Deploy $deploymentId ended $deployDateTime"

    #     if ($status.status -eq "AwaitingVerification") {
    #         Write-Host "Deployment $deploymentId has been successful."
    #     }
    #     else {
    #         Write-Warning "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
    #         Write-Host "##vso[task.logissue type=error]The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)"
    #         Write-Error "The deploy has not been successful or the script has timed out. CurrentStatus: $($status.status)" -ErrorAction Stop
    #         exit 1
    #     }
    # }
    # else {
    #     Write-Warning "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
    #     Write-Host "##vso[task.logissue type=error]Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment."
    #     Write-Error "Status is not in InProgress (Current:$($deploy.status)). You can not deploy at this moment." -ErrorAction Stop
    #     exit 1
    # }
    # Write-Host "Setvariable DeploymentId: $deploymentId"
    # Write-Host "##vso[task.setvariable variable=DeploymentId;]$($deploymentId)"

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