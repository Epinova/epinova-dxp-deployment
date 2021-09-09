# Complete deploy (Optimizely DXP)
Both "Deploy nuget package (Optimizely DXP)" and "Move deploy (Optimizely DXP)" tasks deploy a package to a environment. That will deploy the package to a slot. The task "Complete deploy (Optimizely DXP)" will complete the deploy and move the package from slot to the real environment.  

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

#### Target environment
**[pickList]** - **required**  
Specify if you want to complete the deploy to Integration/Preproduction/Production.  
**Example:** `Integration`  
**Default value:** `$(TargetEnvironment)`  
**Options:**  
- Integration
- Preproduction
- Production

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
- task: DxpCompleteDeploy@1
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    TargetEnvironment: 'Integration'
    Timeout: 1800
```

[<= Back](../README.md)
