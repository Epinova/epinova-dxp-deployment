try {
    $resetOnFail = [System.Convert]::ToBoolean($ResetOnFail)
	$runVerbose = [System.Convert]::ToBoolean($RunVerbose)

	#Uninstall-Module -Name "EpinovaDxpToolBucket" -AllVersions -Force
    Install-Module -Name "EpinovaDxpToolBucket" -MinimumVersion 0.13.4 -Force
    $module = Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable | Select-Object Version
    $moduleVersion = "v$($module.Version.Major).$($module.Version.Minor).$($module.Version.Build)"
    Write-Host "EpinovaDxpToolBucket: $moduleVersion"

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