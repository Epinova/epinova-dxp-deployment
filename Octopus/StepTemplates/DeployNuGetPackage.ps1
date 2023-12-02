try {
    # Get all inputs for the task

    $packagePath = $OctopusParameters["Octopus.Action.Package[sourcepackage].OriginalPath"]
    $directDeploy = [System.Convert]::ToBoolean($DirectDeploy)
    $useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

	#Uninstall-Module -Name "EpinovaDxpToolBucket" -AllVersions -Force
    Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.13.4 -Force
    $module = Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable | Select-Object Version
    $moduleVersion = "v$($module.Version.Major).$($module.Version.Minor).$($module.Version.Build)"
    Write-Host "EpinovaDxpToolBucket: $moduleVersion"

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