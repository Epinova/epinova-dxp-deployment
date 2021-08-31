[CmdletBinding()]
Param(
    $buildnumber
)

$version = (Get-Content src\vss-extension.json) -join "`n" | ConvertFrom-Json | Select -ExpandProperty "version"
$extVersion = "v$version-$buildnumber"
Write-Host "Try to set ExtensionVersion to $extVersion"
Write-Host "##vso[task.setvariable variable=ExtensionVersion;]"$extVersion