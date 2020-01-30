# Smoke and reset (Episerver DXC)
This task smoke test a slot and decide if we should continue the release, or reset the environment slot, because something is not working as expected. The smoke test is a simple check if one or many specified URLs returns HTTPStatus = 200 (OK).  

[<= Back](../README.md)

## Parameters
### Group: Settings
#### DXC target environment ClientKey
**[string]** - **required**  
The DXC API ClientKey for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** `$(ClientKey)`

#### DXC target environment ClientSecret
**[string]** - **required**  
The DXC API ClientSecret for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9` 
**Default value:** `$(ClientSecret)`

#### Project Id
**[string]** - **required**  
The DXC project id.  
**Example:** `1921827e-2eca-2fb3-8015-a89f016bacc5` 
**Default value:** `$(DXC.ProjectId)`

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


[<= Back](../README.md)
