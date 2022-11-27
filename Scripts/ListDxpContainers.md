# List DXP BLOB containers (Optimizely DXP)
PowerShell script that make list BLOB containers from  Optimizely (formerly known as Episerver) DXP project and environment.

Example:  
```powershell
.\ListDxpContainers.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration"
```
This is a really new script so we have not made this signed yeat. So if you get an "Execution policy" error message. You can use this following command before you run download script.
```powershell
Set-ExecutionPolicy Unrestricted
```
When you are done you can set the execution policy back to normal.
```powershell
Set-ExecutionPolicy Restricted
```

## Parameters
### clientKey
**[string]** - **required**  
The DXP API ClientKey for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9`  
**Default value:** ``

### clientSecret
**[string]** - **required**  
The DXP API ClientSecret for the current environment.  
**Example:** `mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d`  
**Default value:** ``

### -projectId
**[string]** - **required**  
The DXP project id.  
**Example:** `1921827e-2eca-2fb3-8015-a89f016bacc5`  
**Default value:** ``

### environment
**[string]** - **required**  
From witch environment that you want to download from. Integration/Preproduction/Production.  
**Example:** `Production`  
**Default value:** `Integration`  
**Options:**  
- Integration
- Preproduction
- Production
- ADE1
- ADE2
- ADE3
  
## Examples ##
### List all storage container for the Integration environment
```powershell
.\ListDxpContainers.ps1 
    -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" 
    -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" 
    -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" 
    -environment "Integration"
```



