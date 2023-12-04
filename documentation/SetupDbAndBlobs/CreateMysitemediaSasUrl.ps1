Set-StrictMode -Version Latest
Set-ExecutionPolicy -Scope CurrentUser Unrestricted

. "$PSScriptRoot\Params.ps1" #$clientkey, $clientSecret, $projectId, $environment is set in this Params file to be reused by all scripts.
$storageContainer = "mysitemedia"

# In this case we got and will use 'mysitemedia' as the folder where we want to upload the blobs to.
$containerHash = @{
            ClientKey        = $clientKey
            ClientSecret     = $clientSecret
            ProjectId        = $projectId
            Environment      = $environment
            StorageContainer = $storageContainer
            Writable         = $true
        }
$sasLink = Get-EpiStorageContainerSasLink @containerHash
Write-Host "SAS link info:"
Write-Host "{"
Write-Host "Environment:    $($sasLink.environment)"
Write-Host "Container:      $($sasLink.containerName)"
Write-Host "SAS link:       $($sasLink.sasLink)"
Write-Host "Expires:        $($sasLink.expiresOn)"
Write-Host "}"
