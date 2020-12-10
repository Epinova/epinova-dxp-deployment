# Download DXP Database and BLOBS (Episerver DXP)
PowerShell script that make it posible to download both database backup and BLOBS from Episerver DXP project. You can download from all environments (Integration/Preproduction/Production).

Example:  
```powershell
.\DownloadDxpDbNBlobs.ps1 -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" -environment "Integration" -databaseName "epicms" -downloadFolder "C:\downloads"
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

### databaseName
**[pickList]** - **required**  
Specify the type of database you want to export. The CMS or Commerce database.  
**Example:** `epicms`  
**Default value:** `epicms`  
**Options:**  
- epicms
- epicommerce

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
The name of the container that contains the blobs.  
**Example:** `mysitemedia`  
**Default value:** `Blobs`

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

### timeout
**[int]** - **optional**  
Specify the number of seconds when the task should timeout.  
**Example:** `3600`  
**Default value:** `1800` (30 minutes)


## Examples ##
### Download all Blobs and database from Integration
This example will download all blob files and the CMS database backup from the integration environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpDbNBlobs.ps1 
    -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9" 
    -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" 
    -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" 
    -environment "Integration" 
    -databaseName "epicms"
    -downloadFolder "C:\downloads"
```
### Download 100 Blobs and database from Preproduction
This example will download 100 blob files and the CMS database backup from the preproduction environment and put them in the c:\downloads folder.
```powershell
.\DownloadDxpDbNBlobs.ps1 
    -clientKey "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9"  
    -clientSecret "mRgLgE3uCx7RVHc5gzFu1gWtssxcYraL0CvLCMJblkbxweO9mRgLgE/d" 
    -projectId "1921827e-2eca-2fb3-8015-a89f016bacc5" 
    -environment "Preproduction" 
    -databaseName "epicms"
    -downloadFolder "C:\downloads" 
    -maxFilesToDownload 100
```



