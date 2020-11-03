# Content copy #
In the DXP Management Portal, you can copy content (database and BLOBs) between environments to test your code with the data you want.  
Does the same thing like the "Content copy" button in the portal. It copy database and/or blobs from one environment to another.  

[More about content syncdown can be read on Episerver world.](https://world.episerver.com/documentation/developer-guides/digital-experience-platform/self-service/content-synchronization/)  
[How content syncdown works in Episerver DXP deployment API.](https://world.episerver.com/blogs/anders-wahlqvist/dates/2020/4/dxp-deployment-improvements/)  

_*NOTE 2020-09-30:* At present date the sync can not handle just one database type. It will sync both cms AND commerce database. We tried to just sync the cms database but there is no support for that in the Episerver API. So if you have a cms and commerce database, both databases will sync when if you set SourceApp=cms._  
  
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

#### Environment
**[pickList]** - **required**  
Specify content copy you want to do.  
**Example:** `Production => Preproduction`  
**Default value:** `$(Environment)`  
**Options:**  
- Production => Preproduction (ProdPrep)
- Preproduction => Integration (PrepInte)
- Production => Integration (ProdInte)
- Integration => Preproduction (IntePrep)

#### Include BLOB
**[boolean]** - **required**  
If BLOBs should be copied from source environment to the target environment.  
**Example:** `true`  
**Default value:** `false`

#### Include DB
**[boolean]** - **required**  
If DBs should be copied from source environment to the target environment.  
**Example:** `true`  
**Default value:** `false`

### Group: Timeout
#### Script timeout (in seconds)
**[int]** - **required**  
Specify the number of seconds when the task should timeout.  
**Example:** `600`  
**Default value:** `1800` (30 minutes)

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
Example: Start content copy of database and blobs from production environment to preproduction environment.  
```yaml
- task: DxpContentCopy@1
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    Environment: 'ProdPrep'
    IncludeBlob: true
    IncludeDb: true
    Timeout: 1800
```

[<= Back](../README.md)
