# Smoke test if fail reset (Episerver DXP)
This task smoke test a slot and decide if we should continue the release, or reset the environment slot, because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  

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
Specify the target environment that you are going to do smoke test against. If the smoke test fails, this is the environment that will be reset.  
**Example:** `Integration`  
**Default value:** `$(TargetEnvironment)`  
**Options:**  
- Integration
- Preproduction
- Production

#### URLs
**[multiline]** - **required**  
Specify the URLs that will be used in the smoke test. Use ',' as delimiter between the URLs.   
**Example 1:** `https://fake017znx5inte.dxcloud.episerver.net/login?ReturnUrl=%2f`  
**Example 2:** `https://fake017znx5inte.dxcloud.episerver.net/login?ReturnUrl=%2f,https://fake017znx5inte.dxcloud.episerver.net/some-public-page`  
**Default value:** `$(EnvironmentSlotUrl)`  

#### Sleep before start (in seconds)
**[int]** - **required**  
The sleep time before the script will start to test the URL(s). Most of the time the slot need some extra time to get up and runing. Even if the status says that it is up and runing. But after alot of tests we think that 20 seconds should be enough.  
**Example:** `30`  
**Default value:** `20`

### Group: Retry
#### Number of retries
**[int]** - **required**  
The number of retries that the script will make before return error and reset the deployment.  
**Example:** `5`  
**Default value:** `5`

#### Sleep before retry (in seconds) (in seconds)
**[int]** - **required**  
The sleep time before the script will start to test the URL(s) again. This will only happend if the HTTP status response from one/many of the URLs is not responding with HTTP status 200.  
**Example:** `30`  
**Default value:** `30`


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
- task: DxpSmokeTestIfFailReset@1
    inputs:
    ClientKey: '$(ClientKey)'
    ClientSecret: '$(ClientSecret)'
    ProjectId: '$(DXP.ProjectId)'
    TargetEnvironment: 'Integration'
    Urls: '$(Integration.SlotUrl)$(Integration.UrlSuffix)'
    SleepBeforeStart: 20
    NumberOfRetries: 5
    SleepBeforeRetry: 30
    Timeout: 1800
```

[<= Back](../README.md)
