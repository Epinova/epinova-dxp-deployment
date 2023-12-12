try {
    $useMaintenancePage = [System.Convert]::ToBoolean($UseMaintenancePage)
    $includeBlob = [System.Convert]::ToBoolean($IncludeBlob)
    $includeDb = [System.Convert]::ToBoolean($IncludeDb)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $myPackageId = "EPiCloud"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath
    
    $myPackageId = "EpinovaDxpToolBucket"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath

    Invoke-DxpDeployTo -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -SourceEnvironment $SourceEnvironment -TargetEnvironment $TargetEnvironment -SourceApp $SourceApp -UseMaintenancePage $useMaintenancePage -IncludeBlob $includeBlob -IncludeDb $includeDb -ZeroDowntimeMode $ZeroDowntimeMode -Timeout $Timeout -RunVerbose $runVerbose

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