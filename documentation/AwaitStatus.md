# Await status (Optimizely DXP)
Task that await for status AwaitingVerification/Reset. Can be used when have a release setup that often timeout and need a extra task that awaits the correct status. So if target environment is in status InProgress/Resetting when it starts. The task will run and check the status until target environment is in status AwaitingVerification/Reset/Succeeded.

If status is AwaitingVerification/Reset/Succeeded when task starts, nothing will happen. If the task starts and status is anything else then AwaitingVerification/Reset/Succeeded/InProgress/Resetting the task will fail with error.  
  
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
- ADE1
- ADE2
- ADE3

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
- task: DxpAwaitStatus@2
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
