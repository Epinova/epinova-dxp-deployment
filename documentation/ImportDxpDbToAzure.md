# Import DXP DB to Azure (Optimizely DXP)
Task that import DXP bacpac database and restore it on Azure SQL Server.  


[<= Back](../README.md)

## Parameters
### Group: Settings

#### BacpacFilePath
**[string]** - **required**  
The file path to the bacpac file that you want to restore in Azure. Example: $(DbExportBacpacFilePath). This value will be set automatically if you use task ExportDB.   
**Example2:** `$(DbExportBacpacFilePath)`  
**Example2:** `/home/vsts/work/r1/a/epicms_Integration_20221103175350.bacpac`  
**Default value:** `$(DbExportBacpacFilePath)`

#### SubscriptionId
**[string]** - **required**  
The id for the subscription in Azure that holds the SQL Server where you want to restore the database.  
**Example:** `e872f180-979f-xxx-aff7-3bbxxxx7f89`  
**Default value:** ``

#### ResourceGroupName
**[string]** - **required**  
The name on the resource group that holds the SQL Server where you want to restore the database.  
**Example:** `rg-my-group`  
**Default value:** ``

#### StorageAccountName
**[string]** - **optional**  
The name on the storage account that will be used to hold the bapac file when restore the database. If this param is not specified the script will take the first storage account found in the resource group.  
**Example:** `my-storage`  
**Default value:** ``

#### StorageAccountContainer
**[string]** - **required**  
The name on the storage account container that will be used to hold the bapac file when restore the database. If this param is not specified the script will take the first storage account container found in the resource group.  
**Example:** `db-backups`  
**Default value:** ``

#### SqlServerName
**[string]** - **required**  
The name on the Azure SQL Server where the database restore will take place.  
**Example:** `your-sql-server`  
**Default value:** ``

#### SqlDatabaseName
**[string]** - **required**  
The name on the database when we restore it.  
**Example:** `your-sql-databasename`  
**Default value:** ``

#### SqlDatabaseLogin
**[string]** - **required**  
The username / login name to the Azuree SQL Server.  
**Example:** `sa`  
**Default value:** ``

#### SqlDatabasePassword
**[string]** - **required**  
The username / login name password.  
**Example:** `******`  
**Default value:** ``

#### RunDatabaseBackup
**[boolean]** - **required**  
Backup the existing database if one exist when restore the database.  
**Example:** `true`  
**Default value:** `false`

#### SqlSku
**[picklist]** - **required**  
The SqlSku that the databsae will be set to after restore.  
**Example:** ``  
**Default value:** `Basic`
**Options:**  
- Free
- Basic
- S0
- S1
- P1
- P2
- GP_Gen4_1
- GP_S_Gen5_1
- GP_Gen5_2
- GP_S_Gen5_2
- BC_Gen4_1
- BC_Gen5_4

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
Example v1:  
```yaml
- task: DxpImportDbToAzure@2
    inputs:
    BacpacFilePath: '$(DbExportBacpacFilePath)'
    SubscriptionId: 'e872f180-979f-xxx-aff7-3bbxxxx7f89'
    ResourceGroupName: 'rg-my-group'
    StorageAccountName: 'my-storage'
    StorageAccountContainer: 'db-backups'
    SqlServerName: 'your-sql-server'
    SqlDatabaseName: 'your-sql-databasename'
    SqlDatabaseLogin: 'sa'
    SqlDatabasePassword: '$(SqlServerLoginPassword)'
    RunDatabaseBackup: true
    SqlSku: 'Basic'
    Timeout: 1800
```

[<= Back](../README.md)
