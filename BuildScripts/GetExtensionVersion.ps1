[CmdletBinding()]
Param(
    $buildnumber
)

$version = (Get-Content src\vss-extension.json) -join "`n" | ConvertFrom-Json | Select -ExpandProperty "version"
$extVersion = "$version"
$extFileVersion = "v$version-$buildnumber"
Write-Host "Try to set ExtensionVersion to $extVersion"
Write-Host "Try to set ExtensionFileVersion to $extFileVersion"
Write-Host "##vso[task.setvariable variable=ExtensionVersion;]"$extVersion
Write-Host "##vso[task.setvariable variable=ExtensionFileVersion;]"$extFileVersion