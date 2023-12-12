try {
    $resetOnFail = [System.Convert]::ToBoolean($ResetOnFail)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

    $myPackageId = "EPiCloud"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath
    
    $myPackageId = "EpinovaDxpToolBucket"
    $taskModulePath = $OctopusParameters["Octopus.Action.Package[$myPackageId].ExtractedPath"]
    Write-Host $taskModulePath
    Import-Module -Name $taskModulePath

    Invoke-DxpSmokeTestIfFailReset -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -TargetEnvironment $TargetEnvironment -Urls $Urls -ResetOnFail $resetOnFail -SleepBeforeStart $SleepBeforeStart -NumberOfRetries $NumberOfRetries -SleepBeforeRetry $SleepBeforeRetry -Timeout $Timeout -RunVerbose $runVerbose

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