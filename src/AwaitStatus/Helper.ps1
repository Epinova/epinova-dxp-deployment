function Progress {
    #([string] $projectId, [string] $deploymentId, [int] $percentComplete, [string] $expectedStatus, [int] $timeout)
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $deploymentId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int] $percentComplete,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $expectedStatus,
        [Parameter(Mandatory = $true)]
        [int] $timeout
    )

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    while ($percentComplete -le 100) {
        $status = Get-EpiDeployment -ProjectId $projectId -Id $deploymentId
        if ($percentComplete -ne $status.percentComplete) {
            $percentComplete = $status.percentComplete
            Write-Host $percentComplete "%. Status: $($status.status). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($percentComplete -le 100 -or $status.status -ne $expectedStatus) {
            Start-Sleep 5
        }
        if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
        if ($status.percentComplete -eq 100 -and $status.status -eq $expectedStatus) { break }
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDeployment -ProjectId $projectId -Id $deploymentId
    $status
    return $status
}

function ExportProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $projectId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $exportId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $environment,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $databaseName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $expectedStatus,
        [Parameter(Mandatory = $true)]
        [int] $timeout
    )
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $sw.Start()
    $currentStatus = ""
    $iterator = 0
    while ($currentStatus -ne $expectedStatus) {
        $status = Get-EpiDatabaseExport -projectId $projectId -id $exportId -environment $environment -databaseName $databaseName
        $currentStatus = $status.status
        if ($iterator % 6 -eq 0) {
            Write-Host "Status: $($currentStatus). ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
        }
        if ($currentStatus -ne $expectedStatus) {
            Start-Sleep 10
        }
        if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
        if ($currentStatus -eq $expectedStatus) { break }
        $iterator++
    }

    $sw.Stop()
    Write-Host "Stopped iteration after $($sw.Elapsed.TotalSeconds) seconds."

    $status = Get-EpiDatabaseExport -projectId $projectId -id $exportId -environment $environment -databaseName $databaseName
    Write-Host $status
    return $status
}

function WriteInfo() {
    $version = Get-Host | Select-Object Version
    Write-Host $version
}

function Test-IsGuid
{
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ObjectGuid
	)
	
	# Define verification regex
	[regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

	# Check guid against regex
	return $ObjectGuid -match $guidRegex
}

function GetDateTimeStamp{
    $dateTimeNow = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    return $dateTimeNow
}