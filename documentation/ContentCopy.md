# Content copy #
In the DXP Management Portal, you can copy content (database and BLOBs) between environments to test your code with the data you want.  
Does the same thing like the "Content copy" button in the portal. It copy database and/or blobs from one environment to another.  

[More about content syncdown can be read on Episerver world.](https://world.optimizely.com/documentation/developer-guides/digital-experience-platform/self-service/content-synchronization/)  
[How content syncdown works in Episerver DXP deployment API.](https://world.optimizely.com/blogs/anders-wahlqvist/dates/2020/4/dxp-deployment-improvements/)  

_**Note:** v2 task supports windows/ubuntu/MacOS agents. v1 task only support windows._   

_**Note 2020-09-30:** At present date the sync can not handle just one database type. It will sync both cms AND commerce database. We tried to just sync the cms database but there is no support for that in the Episerver API. So if you have a cms and commerce database, both databases will sync when if you set SourceApp=cms._  
  
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
- Production => ADE1 (ProdAde1)
- Production => ADE2 (ProdAde2)
- Production => ADE3 (ProdAde3)
- Production => ADE4 (ProdAde4)
- Production => ADE5 (ProdAde5)
- Production => ADE6 (ProdAde6)
- Preproduction => ADE1 (PrepAde1)
- Preproduction => ADE2 (PrepAde2)
- Preproduction => ADE3 (PrepAde3)
- Preproduction => ADE4 (PrepAde4)
- Preproduction => ADE5 (PrepAde5)
- Preproduction => ADE6 (PrepAde6)
- Integration => ADE1 (InteAde1)
- Integration => ADE2 (InteAde2)
- Integration => ADE3 (InteAde3)
- Integration => ADE4 (InteAde4)
- Integration => ADE5 (InteAde5)
- Integration => ADE6 (InteAde6)
- ADE1 => Preproduction (Ade1Prep)
- ADE2 => Preproduction (Ade2Prep)
- ADE3 => Preproduction (Ade3Prep)
- ADE4 => Preproduction (Ade4Prep)
- ADE5 => Preproduction (Ade5Prep)
- ADE6 => Preproduction (Ade6Prep)
- ADE1 => Integration (Ade1Inte)
- ADE2 => Integration (Ade2Inte)
- ADE3 => Integration (Ade3Inte)
- ADE4 => Integration (Ade4Inte)
- ADE5 => Integration (Ade5Inte)
- ADE6 => Integration (Ade6Inte)
- ADE1 => ADE2 (Ade1Ade2)
- ADE1 => ADE3 (Ade1Ade3)
- ADE1 => ADE4 (Ade1Ade4)
- ADE1 => ADE5 (Ade1Ade5)
- ADE1 => ADE6 (Ade1Ade6)
- ADE2 => ADE1 (Ade2Ade1)
- ADE2 => ADE3 (Ade2Ade3)
- ADE2 => ADE4 (Ade2Ade4)
- ADE2 => ADE5 (Ade2Ade5)
- ADE2 => ADE6 (Ade2Ade6)
- ADE3 => ADE1 (Ade3Ade1)
- ADE3 => ADE2 (Ade3Ade2)
- ADE3 => ADE4 (Ade3Ade4)
- ADE3 => ADE5 (Ade3Ade5)
- ADE3 => ADE6 (Ade3Ade6)
- ADE4 => ADE1 (Ade4Ade1)
- ADE4 => ADE2 (Ade4Ade2)
- ADE4 => ADE3 (Ade4Ade3)
- ADE4 => ADE5 (Ade4Ade5)
- ADE4 => ADE6 (Ade4Ade6)
- ADE5 => ADE1 (Ade5Ade1)
- ADE5 => ADE2 (Ade5Ade2)
- ADE5 => ADE3 (Ade5Ade3)
- ADE5 => ADE4 (Ade5Ade3)
- ADE5 => ADE6 (Ade5Ade6)
- ADE6 => ADE1 (Ade6Ade1)
- ADE6 => ADE2 (Ade6Ade2)
- ADE6 => ADE3 (Ade6Ade3)
- ADE6 => ADE4 (Ade6Ade4)
- ADE6 => ADE5 (Ade6Ade5)


#### Include BLOB
**[boolean]** - **required**  
If BLOBs should be copied from source environment to the target environment.  
**Example:** `true`  
**Default value:** `true`

#### Include DB
**[boolean]** - **required**  
If DBs should be copied from source environment to the target environment.  
**Example:** `false`  
**Default value:** `true`

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
Example: Start content copy of database and blobs from production environment to preproduction environment.  
```yaml
- task: DxpContentCopy@2
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    Environment: 'ProdPrep'
    IncludeBlob: true
    IncludeDb: true
    Timeout: 1800  
    RunBenchmark: true
    RunVerbose: false
```

[<= Back](../README.md)
