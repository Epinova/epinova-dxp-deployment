# Complete deploy (Optimizely DXP)
Both "Deploy nuget package (Optimizely DXP)" and "Move deploy (Optimizely DXP)" tasks deploy a package to a environment. That will deploy the package to a slot. The task "Complete deploy (Optimizely DXP)" will complete the deploy and move the package from slot to the real environment.  
  
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
  
### Group: Benchmark
#### Run benchmark
**[boolean]** - **required**  
If you want to send information about your execution, to get benchmark data back.  
If you are interested of more benchmark data you can contact Epinova.  
By using this function you agree with sending over the following information: Task, TaskVersion, Environment, TargetEnvironment, DxpProjectId, OrganisationId, OrganisationName, ProjectId, ProjectName, Branch, AgentOS, EpiCloudVersion, PowerShellVersion, PowerShellEdition, Elapsed, Result, CmsFileSize, CmsPackageName, CommerceFileSize, CommercePackageName.  
**Example:** `true`  
**Default value:** `false`
  
### Group: ErrorHandlingOptions
#### Run Verbose
**[boolean]** - **required**  
If you want to run in verbose mode and see all information.  
**Example:** `true`  
**Default value:** `false`  
  
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
- task: DxpCompleteDeploy@2
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    TargetEnvironment: 'Integration'
    Timeout: 1800  
    RunBenchmark: true
    RunVerbose: false
```

[<= Back](../README.md)
