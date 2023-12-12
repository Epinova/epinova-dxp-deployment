try {
	Write-Host "Server:" + $env:computername
    
    $runVerbose = [System.Convert]::ToBoolean($RunVerbose)
    
    $myPackageId = "EPiCloud"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath
    
    $myPackageId = "EpinovaDxpToolBucket"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath
    
    Invoke-DxpExpectStatus -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment -ExpectedStatus $ExpectedStatus -RunVerbose $runVerbose
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