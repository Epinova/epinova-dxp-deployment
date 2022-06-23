# Deploy nuget package (Optimizely DXP) #
Take a nuget package from your drop folder in Azure DevOps and upload it to your Optimizely (formerly known as Episerver) DXP project and start a deployment to the targeted environment.  
Also support the DirectDeploy function. [Introducing "Direct Deploy", a quicker way to deploy to integration using the deployment API!](https://world.optimizely.com/blogs/anders-wahlqvist/dates/2021/3/introducing-direct-deploy-a-quicker-way-to-deploy-to-dxp/)

## Spaces in package name(s)
If you send/create packages in the build pipeline that contains spaces. Example "Cool Customer Project.cms.app.20200429.2.nupkg" the script will throw a exception and tell you to update build pipeline to fix that. EpiCloud does not support that package names contains any spaces.

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

#### Drop path
**[string]** - **required**  
The path in Azure DevOps where the nuget file(s) is placed. Will try to find the file with the following pattern: "[DropPath]/*.[SourceApp].*.nupkg". The SourceApp is equal to what you specify for the "SourceApp" parameter. If you specify "cms,commerce", it will try to find both "[DropPath]/*.cms.*.nupkg" and "[DropPath]/*.commerce.*.nupkg" to upload to DXP.
**Example:** `$(System.DefaultWorkingDirectory)/_ProjectName-CI/drop`  
**Default value:** `$(DropPath)`

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
Specify which type of application you want to deploy. Will look in the drop folder with the filter *.[SourceApp].*.nupkg. New in v1.1.0.  
If you use "cms,commerce", both nupkg files must be in the same DropPath folder.
**Example:** `commerce`  
**Default value:** `cms`  
**Options:**  
- cms
- commerce
- cms,commerce

#### DirectDeploy
**[boolean]** - **required**  
Specify if you want to do a direct deploy without using slot and warmup.  
**Example:** `true`  
**Default value:** `false`

#### Warm-up URL
**[string]** 
Specify if you want to warm-up the web application after direct deploy. It will request the specified URL and all links found on the page.  
If there is some tests running against the web application with direct deploy there is a problem that the web application is not started and warmed up.  
This should solve this problem.  
**Example1:** `https://dikl06mstr3pe5minte.dxcloud.episerver.net/`  
**Example2:** `$(Integration.Url)`  
**Default value:** `$(Integration.Url)`

#### Use maintenance page
**[boolean]** - **required**  
Specify if you want to use a maintenance page during the deploy.  
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
Example v1:  
```yaml
- task: DxpDeployNuGetPackage@1  
    inputs:  
    ClientKey: '$(ClientKey)'  
    ClientSecret: '$(ClientSecret)'  
    ProjectId: '$(DXP.ProjectId)'  
    DropPath: '$(System.DefaultWorkingDirectory)\drop'  
    TargetEnvironment: 'Integration'  
    SourceApp: 'cms'  
    DirectDeploy: true  
    UseMaintenancePage: false  
    Timeout: 1800  
```  
  
Example v2:  
```yaml
- task: DxpDeployNuGetPackage@2  
    inputs:  
    ClientKey: '$(ClientKey)'  
    ClientSecret: '$(ClientSecret)'  
    ProjectId: '$(DXP.ProjectId)'  
    DropPath: '$(System.DefaultWorkingDirectory)\drop'  
    TargetEnvironment: 'Integration'  
    SourceApp: 'cms'  
    DirectDeploy: true  
    UseMaintenancePage: false  
    Timeout: 1800  
```

Example v3:  
```yaml
- task: DxpDeployNuGetPackage@2  
    inputs:  
    ClientKey: '$(ClientKey)'  
    ClientSecret: '$(ClientSecret)'  
    ProjectId: '$(DXP.ProjectId)'  
    DropPath: '$(System.DefaultWorkingDirectory)\drop'  
    TargetEnvironment: 'Integration'  
    SourceApp: 'cms'  
    DirectDeploy: true  
    WarmUpUrl: '$(Integration.Url)'
    UseMaintenancePage: false  
    Timeout: 1800  
```

[<= Back](../README.md)

