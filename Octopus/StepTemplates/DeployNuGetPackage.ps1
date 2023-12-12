try {
    # Get all inputs for the task

    $packagePath = $OctopusParameters["Octopus.Action.Package[sourcepackage].OriginalPath"]
    $directDeploy = [System.Convert]::ToBoolean($DirectDeploy)
    $useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $myPackageId = "EPiCloud"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath
    
    $myPackageId = "EpinovaDxpToolBucket"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath

    Invoke-DxpDeployNuGetPackage -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment -PackagePath $packagePath -DirectDeploy $directDeploy -WarmUpUrl $WarmUpUrl -UseMaintenancePage $useMaintenancePage -ZeroDowntimeMode $ZeroDowntimeMode -Timeout $Timeout -RunVerbose $runVerbose
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