Set-StrictMode -Version Latest

$version = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
Write-Host "EPiCloud: $version"

#Uninstall-Module -Name EpiCloud -RequiredVersion 1.2.0
#Uninstall-Module -Name EpiCloud -RequiredVersion 1.1.0
#Uninstall-Module -Name EpiCloud -RequiredVersion 1.0.0
#Uninstall-Module -Name EpiCloud -RequiredVersion 0.13.15
#Uninstall-Module -Name EpiCloud -RequiredVersion 0.12.14