# Download DXP BLOBS (Episerver DXP)
PowerShell script that make it posible to download BLOBS from Episerver DXP project. You can download from all environments (Integration/Preproduction/Production).
Also support to download application logs or web logs.

Example:  
```powershell
.\DownloadDxpBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -downloadFolder "C:\downloads"
```
Set-ExecutionPolicy Unrestricted

Set-ExecutionPolicy Restricted

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

### downloadFolder
**[string]** - **required**  
Specify the local folder were you want to download the blobs to. Script will give you a error message and exit if folder down not exist.  
**Example:** `c:\downloads\funnyblobs`  
**Default value:** `d:\downloads`

### maxFilesToDownload
**[int]** - **required**  
The number of files that you max want to download. 0=All, 100=Max 100 files will be downloaded.  
**Example:** `0`  
**Default value:** `0`

### container
**[string]** - **optional**  
Type of files that you want to download.  
**Example:** `WebLogs`  
**Default value:** `Blobs`
**Options:**  
- AppLogs
- WebLogs
- Blobs

### overwriteExistingFiles
**[boolean]** - **optional**  
Specify if you should overwrite files that exist on disc. If this flag is 'false' and file exist on disc, the file will  not be downloaded and it will not be calculated as a download. 
**Example:** `WebLogs`  
**Default value:** `Blobs`
**Options:**  
- AppLogs
- WebLogs
- Blobs

### retentionHours
**[int]** - **optional**  
Number of hours that the sasToken created to get access to the files will be valid. Most cases you will not need to change this value.  
**Example:** `2`  
**Default value:** `24`
  
## Examples ##
### Download all Blobs from Integration
This example will download all blob files from the integration environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -downloadFolder "C:\downloads"
```
### Download 100 Blobs from Preproduction
This example will download 100 blob files from the integration environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Preproduction" -downloadFolder "C:\downloads" -maxFilesToDownload 100
```
### Download all web logs from Integration
This example will download all web log files from the integration environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -downloadFolder "C:\downloads" -container "WebLogs"
```

### Download all application logs from Integration
This example will download all application log files from the integration environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -downloadFolder "C:\downloads" -container "AppLogs"
```



