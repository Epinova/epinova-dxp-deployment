Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $clientKey = Get-VstsInput -Name "ClientKey" -Require -ErrorAction "Stop"
    $clientSecret = Get-VstsInput -Name "ClientSecret" -Require -ErrorAction "Stop"
    $projectId = Get-VstsInput -Name "ProjectId" -Require -ErrorAction "Stop"
    $targetEnvironment = Get-VstsInput -Name "TargetEnvironment" -Require -ErrorAction "Stop"
    $expectedStatus = Get-VstsInput -Name "ExpectedStatus" -Require -ErrorAction "Stop"
    $timeout = Get-VstsInput -Name "Timeout" -AsInt -Require -ErrorAction "Stop"

    $runVerbose = Get-VstsInput -Name "RunVerbose" -AsBool
    $runBenchmark = Get-VstsInput -Name "RunBenchmark" -AsBool


    $arguments = "-ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -TargetEnvironment $targetEnvironment -ExpectedStatus $expectedStatus -Timeout $timeout"
    if ($runBenchmark) {
        $arguments = $arguments + "-RunBenchmark"
    }
    if ($runVerbose) {
        $arguments = $arguments + "-RunVerbose"
    }

    $command = "pwsh .\ExpectStatus.ps1 $arguments"
    #$result = Invoke-Expression -Command:$command
    Invoke-Expression -Command:$command

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}