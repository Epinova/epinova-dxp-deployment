# Get DXP container SAS link (Optimizely DXP)
PowerShell script create a SAS link  to a DXP container from Optimizely (formerly known as Episerver).  
This SAS link can be used in "Microsoft Azure Storage Explorer" to be able to see the blobs/content in the container.

Example:  
```powershell
.\GetDxpContainerSasLink.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -container "mysitemedia"
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

### projectId
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

### container
**[string]** - **required**  
The name of the container that you would like to get SAS link for.  
**Example:** `mysitemedia`  

### retensionHours
**[int]** - **optional**  
The number of hours that the SAS token shoul be valid. Default is 2 hours.  
**Example:** `mysitemedia`  

  
## Examples ##
### Get SAS link for 'mysitemedia' container in Integration environment
```powershell
$sasLink = Get-DxpStorageContainerSasLink -ClientKey $ClientKey -ClientSecret $ClientSecret -ProjectId $ProjectId -Environment $Environment -Container "baerum-assets"
Write-Host "Sas link object: $sasLink"
Write-Host "Sas link: $($sasLink.sasLink)"
```
Example of the result:  
```
Sas link: https://bkoxxxxxinte.blob.core.windows.net/bxxxxx-assets?sv=2018-03-28&sr=c&sig=HURwEki%xxxx9%2BfI8CipjdqQXrZ%2B2Yay6AxxxbRaOzUI%3D&st=2021-11-20T01%3A04%3A43Z&se=2021-11-20T03%3A04%3A43Z&sp=rl
```




