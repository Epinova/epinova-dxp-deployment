# Sync DXP blobs to Azure (Optimizely DXP)
Task that export DXP blobs and upload it on Azure storage account container.  
  
[<= Back](../README.md)

## Parameters
### Group: Settings
#### DXP target environment ClientKey
**[string]** - **required**  
The DXP API ClientKey for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** `$(ClientKey)`

#### DXP target environment ClientSecret
**[string]** - **required**  
The DXP API ClientSecret for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** `$(ClientSecret)`

#### Project Id
**[string]** - **required**  
The DXP project id.  
**Example:** `1921827e-2eca-2fb3-8015-a89f016bacc5`  
**Default value:** `$(DXP.ProjectId)`

#### Source environment
**[pickList]** - **required**  
Specify the source environment where we will get blobs from.  
**Example:** `Integration`  
**Default value:** `$(TargetEnvironment)`  
**Options:**  
- Integration
- Preproduction
- Production
- ADE1
- ADE2
- ADE3

#### DxpContainer
**[string]** - **required**  
Name on the container in DXP where the blobs exist.   
**Example:** `mysitemedia`
**Default value:** `mysitemedia`  

#### DownloadFolder
**[string]** - **required**  
The   
**Example:** `30`  
**Default value:** `20`

#### SubscriptionId
**[string]** - **required**  
The id for the subscription in Azure that holds the storage account where you want to restore the blobs.  
**Example:** `e872f180-979f-xxx-aff7-3bbxxxx7f89`  
**Default value:** ``

#### ResourceGroupName
**[string]** - **required**  
The name on the resource group that holds the storage account where you want to restore the blobs.  
**Example:** `rg-my-group`  
**Default value:** ``

#### StorageAccountName
**[string]** - **optional**  
The name on the storage account where blobs will be uploaded.  
**Example:** `my-storage`  
**Default value:** ``

#### StorageAccountContainer
**[string]** - **required**  
The name on the storage account container where blobs will be uploaded.  
**Example:** `mysitemedia`  
**Default value:** ``

### Group: ErrorHandlingOptions
#### ErrorActionPreference
**[pickList]** - **required**  
How the task should handle errors.  
**Example:** `600`  
**Default value:** `stop`  
**Options:**  
- **Stop**: Terminate the action with error.
- **Continue**: Display any error message and attempt to continue execution of subsequence commands.
- **SilentlyContinue**: Don't display an error message continue to execute subsequent commands.

## YAML ##
Example v1:  
```yaml
- task: DxpSyncBlobsToAzure@2
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    Environment: 'Integration'
    DxpContainer: 'mysitemedia'
    DownloadFolder: 'c:\'
    Timeout: 1800
    SubscriptionId: 'e872f180-979f-xxx-aff7-3bbxxxx7f89'
    ResourceGroupName: 'rg-my-group'
    StorageAccountName: 'my-storage'
    StorageAccountContainer: 'mysitemedia'
```

## PowerShell ##
Example v1:  

```powershell
Sync-DxpBlobsToAzure -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment $DxpEnvironment -DxpContainer $DxpContainer -DownloadFolder $DxpDownloadFolder -Timeout 1800 -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -StorageAccountContainer $StorageAccountContainer  
```

[<= Back](../README.md)
