Set-StrictMode -Version Latest
Set-ExecutionPolicy -Scope CurrentUser Unrestricted

. "$PSScriptRoot\Params.ps1" #$clientkey, $clientSecret, $projectId, $environment is set in this Params file to be reused by all scripts.

#Uninstall-Module -Name "EpiCloud" -RequiredVersion 1.2.0
Install-Module -Name "EpiCloud" -MinimumVersion 1.3.0  -Scope CurrentUser

$version = Get-Module -Name EpiCloud -ListAvailable | Select-Object Version
Write-Host "EPiCloud: $version"

# List all containers that are ok to order SAS URL with writable permission.
$containerHash = @{
            ClientKey    = $clientKey
            ClientSecret = $clientSecret
            ProjectId    = $projectId
            Environment  = $environment
            Writable     = $true
        }
$containers = Get-EpiStorageContainer @containerHash
Write-Host "Found following storage containers that are writable:"
Write-Host "{"
Write-Host $containers.storageContainers
Write-Host "}"
