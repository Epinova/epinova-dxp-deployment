# Deploy smooth to (Optimizely DXP) #

<span style="color:red">
Deprecated!   
You should stop using this task DeploySmoothTo. You should change to DeployTo.
</span>

Do the same thing as the ["Deploy to" task](DeployTo.md). But this has support for Smooth deployment (Zero downtime deployment).  
Since this function is still in [closed beta](https://world.episerver.com/service-and-product-lifecycles/#CloudServicesLifecycle). There is not everybody that can use this feature yet. That is why this is like a copy past of the "Deploy To" task but with smooth deployment support.  
When this feature is public for all DXP users, we will implement this feature on the "Deploy to" task.  
[More about smooth deploy can be read on Episerver world.](https://world.episerver.com/documentation/developer-guides/digital-experience-platform/deploying/deployment-process/smooth-deploy/)  
[https://world.episerver.com/documentation/developer-guides/digital-experience-platform/deploying/episerver-digital-experience-cloud-deployment-api/how-to-deploy-using-deployment-api/](https://world.episerver.com/documentation/developer-guides/digital-experience-platform/deploying/episerver-digital-experience-cloud-deployment-api/how-to-deploy-using-deployment-api/)  
  
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
Specify from which environment you want to take the source code/package.  
**Example:** `Integration`  
**Default value:** `$(SourceEnvironment)`  
**Options:**  
- Integration
- Preproduction
- Production

#### Target environment
**[pickList]** - **required**  
Specify if you want to deploy to Integration/Preproduction/Production.  
**Example:** `Integration`  
**Default value:** `$(TargetEnvironment)`  
**Options:**  
- Integration
- Preproduction
- Production

#### SourceApp
**[pickList]** - **required**  
Specify which type of application you want to move.  
**Example:** `commerce`  
**Default value:** `cms`  
**Options:**  
- cms
- commerce
- cms,commerce

#### Use maintenance page
**[boolean]** - **required**  
Specify if you want to use a maintenance page during the deploy.  
**Example:** `true`  
**Default value:** `false`

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

#### Zero Downtime Mode
**[pickList]** - **required**  
The type of smooth deployment you want to use. [More information about zero downtime mode](https://world.episerver.com/documentation/developer-guides/digital-experience-platform/deploying/deployment-process/smooth-deploy/)  
**Example:** `ReadOnly`  
**Default value:** `ReadOnly`  
**Options:**  
- ''
- ReadOnly
- ReadWrite

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
Example:  
```yaml
- task: DxpDeploySmoothTo@1
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Preproduction'
    TargetEnvironment: 'Production'
    SourceApp: 'cms'
    UseMaintenancePage: false
    ZeroDowntimeMode: 'ReadOnly'
    Timeout: 1800
```
  
[<= Back](../README.md)
