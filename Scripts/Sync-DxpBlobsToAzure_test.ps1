Set-StrictMode -Version Latest 
$DebugPreference = 'Continue'

Remove-Module -Name "EpinovaAzureToolBucket" -Verbose -Force
#Import-Module -Name E:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose
Import-Module -Name C:\dev\EpinovaAzureToolBucket-psmodule\Modules\EpinovaAzureToolBucket -Verbose

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose -Force
#Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket\EpinovaDxpToolBucket.psd1 -Verbose
Import-Module -Name C:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket\EpinovaDxpToolBucket.psd1 -Verbose
Get-Module -Name "EpinovaDxpToolBucket" -ListAvailable

#. E:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1
. C:\dev\temp\PowerShellSettingFiles\DxpProjects.ps1
[string] $DxpEnvironment = "Integration" #[ValidateSet('Integration','Preproduction','Production','ADE1','ADE2','ADE3')]
[string] $DxpContainer = "baerum-assets" #"mysitemedia" 
#[string] $DxpDownloadFolder = "E:\dev\temp\_blobDownloads"

[string] $SubscriptionId = "e872f180-979f-xxx-aff7-3bbxxxx7f89" 
[string] $ResourceGroupName = "rg-my-group"
[string] $StorageAccountName = "my-storage"
[string] $StorageAccountContainer = "mysitemedia"

#. E:\dev\temp\PowerShellSettingFiles\EpinovaDxpExtension_Sync-DxpBlobsToAzure.ps1
. C:\dev\temp\PowerShellSettingFiles\EpinovaDxpExtension_Sync-DxpBlobsToAzure.ps1


# Override with real settings

Set-ExecutionPolicy -Scope CurrentUser Unrestricted

Sync-DxpBlobsToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DxpContainer $DxpContainer -Timeout 1800 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer 
