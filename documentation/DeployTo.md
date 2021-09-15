# Deploy to (Optimizely DXP) #
Do the same thing like the "Deploy to =>" button in the portal. It moves the deployed code from one environment to another.  

## Content sync (syncdown/harmonization)
Have support for IncludeBlob and IncludeDb so that you can deploy your code and move BLOBs and/or DB if you want.  
Can also be used for Content syncdown. Example: if you want to make your preproduction environment contain the same content as in production. [More about content syncdown can be read on Optimizely (formerly known as Episerver) world.](https://world.optimizely.com/blogs/anders-wahlqvist/dates/2020/4/dxp-deployment-improvements/)  
_**NOTE 2020-09-30:** At present date the sync can not handle just one database type. It will sync both cms AND commerce database. We tried to just sync the cms database but there is no support for that in the Optimizely (formerly known as Episerver) API. So if you have a cms and commerce database, both databases will sync when if you set SourceApp=cms._  
## Zero Downtime Deployment aka ZDD (Smooth deployment)
Support for Smooth deployment (Zero downtime deployment).  
[More about smooth deploy can be read on Episerver world.](https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/deploying/deployment-process/smooth-deploy/)   
[https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/deploying/episerver-digital-experience-cloud-deployment-api/how-to-deploy-using-deployment-api/](https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/deploying/episerver-digital-experience-cloud-deployment-api/how-to-deploy-using-deployment-api/)  
   
_**Note:** v2 task supports windows/ubuntu/MacOS agents. v1 task only support windows._  

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
Specify which type of application you want to move. (When use syncdown, this param has no effect. Will sync all databases.) 
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
The type of smooth deployment you want to use. [More information about zero downtime mode](https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/deploying/deployment-process/smooth-deploy/)  
If this parameter is set to empty, no zero downtime deployment will be made. It will be a regular deployment.   
**Example:** `ReadOnly`  
**Default value:** ``  
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
### v1 ###
Example 1: Start CMS deployment of preproduction 'code' from preproduction to production.  
```yaml
- task: DxpDeployTo@1
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Preproduction'
    TargetEnvironment: 'Production'
    SourceApp: 'cms'
    UseMaintenancePage: false
    Timeout: 1800
```
Example 2: Start CMS content syncdown from production to preproduction. Will sync CMS web application, blobs and DB.
```yaml
- task: DxpDeployTo@1
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Production'
    TargetEnvironment: 'Preproduction'
    SourceApp: 'cms'
    UseMaintenancePage: false
    IncludeBlob: true  
    IncluseDb: true  
    Timeout: 1800
```

Example 3: Start CMS zero downtime deployment with ReadOnly option.
```yaml
- task: DxpDeployTo@1
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Production'
    TargetEnvironment: 'Preproduction'
    SourceApp: 'cms'
    ZeroDowntimeMode: ReadOnly
    Timeout: 1800
```

### v2 ###
Example 1: Start CMS deployment of preproduction 'code' from preproduction to production.  
```yaml
- task: DxpDeployTo@2
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Preproduction'
    TargetEnvironment: 'Production'
    SourceApp: 'cms'
    UseMaintenancePage: false
    Timeout: 1800
```
Example 2: Start CMS content syncdown from production to preproduction. Will sync CMS web application, blobs and DB.
```yaml
- task: DxpDeployTo@2
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Production'
    TargetEnvironment: 'Preproduction'
    SourceApp: 'cms'
    UseMaintenancePage: false
    IncludeBlob: true  
    IncluseDb: true  
    Timeout: 1800
```

Example 3: Start CMS zero downtime deployment with ReadOnly option.
```yaml
- task: DxpDeployTo@2
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    SourceEnvironment: 'Production'
    TargetEnvironment: 'Preproduction'
    SourceApp: 'cms'
    ZeroDowntimeMode: ReadOnly
    Timeout: 1800
```

## Example of content syncdown from Production to Preproduction - classic
![DeployTo syndown example](Images/DeployTo_SyncDown_example.png)  

[<= Back](../README.md)
