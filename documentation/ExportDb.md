# Export DB (Optimizely DXP) #
Export specified DB from DXP and will be downloadable via link.  
When the database bacpac file has been created. You can download the file from the specified downloadLink.  
There a variable set in the task with the name `DbExportDownloadLink`. That variable can be used by other tasks in the pipeline to retrieve that information and for example send a email with this information to project group members.  
   
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

#### Environment
**[pickList]** - **required**  
Specify from which environment the database export should be done.  
**Example:** `Integration`  
**Default value:** `$(Environment)`  
**Options:**  
- Integration
- Preproduction
- Production
- ADE1
- ADE2
- ADE3

#### DatabaseName
**[pickList]** - **required**  
Specify the type of database you want to export. The CMS or Commerce database.  
**Example:** `epicms`  
**Default value:** `epicms`  
**Options:**  
- epicms
- epicommerce

#### Retention hours (in hours)
**[int]** - **required**  
Specify how long the bacpac file will be available. Default 24 h and max 72 h.  
**Example:** `24`  
**Default value:** `24`

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
If you want to run in Verbose mode and see all verbose messages.  
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
- task: DxpExportDb@2
inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    Environment: 'Integration'
    DatabaseName: 'epicms'
    RetentionHours: 24
    Timeout: 1800  
    RunBenchmark: true
    RunVerbose: false
```

[<= Back](../README.md)
