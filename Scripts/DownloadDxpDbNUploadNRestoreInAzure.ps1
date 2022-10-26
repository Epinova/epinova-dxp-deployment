 #This whole script file should go in https://github.com/Epinova/epinova-dxp-deployment/tree/master/Scripts
 
  function Connect-AzureSubscriptionAccount{
    if($null -eq $azureConnection -or $null -eq $azureConnection.Account){
        try{
            $azureConnection = Connect-AzAccount -SubscriptionId $SubscriptionId
            Write-Host "Connected to subscription $SubscriptionId"
        }
        catch {
            $message = $_.Exception.message
            Write-Error $message
            exit
        }
    }
}
  
  <#Set-StrictMode -Version Latest 

Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name C:\DevStuff\Project\Modules\EpinovaDxpToolBucket -Verbose

 #E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

 [string] $clientkey = "XKCGeIibVxfLZUQRIIWaHepFzbOgAtoCIaPRPCtjAQoNhCW4"
 [string] $clientsecret = "YpI0Rk4YAkhTwXR0AhaqFg8dJJjWJyjYrL1xem9cacjHTATnMt3hG3ZiiTSP/T65"
 [string] $projectid = "2417b89d-2014-42ac-a2a9-ae30016a90ce"
 [string] $environment = "Integration"
 [string] $databaseName = "epicms"
 [string] $downloadFolder = "C:\Users\sameer.ajmal\downloads"
 [int] $retentionHours = 1
 [int] $timeout = 1800

Set-ExecutionPolicy -Scope CurrentUser Unrestricted
#Get-DxpProjectBlobs -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
$downloadedBacPacFile = Invoke-DxpDatabaseDownload -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "$environment" -DatabaseName "$databaseName" -DownloadFolder "$downloadFolder" -RetentionHours $retentionHours -Timeout $timeout

 #>

 #Upload bacpac file from disc to storage account

 #This function should be going into EpinovaAzureToolBucket.psm1

  function Upload-Bacpac-File{
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true)]
        [validatenotnullorempty()]
        [string] $Subscriptionid = "364b5ea6-c54a-4b26-bd43-a7931b0ab230",

        [parameter(mandatory = $true)]
        [validatenotnullorempty()]
        [string] $Resourcegroupname = "rg-mycoolwebsite16-abn-inte",

        [parameter(mandatory = $true)]
        [string] $Storageaccountname = "stmycoolwebsite16inte",

        [parameter(mandatory = $true)]
        [string] $Containername = "db-backups",

        [parameter(mandatory = $true)]
        [string] $FileName = "epicms_Integration_20221006124443.bacpac"
    )

    write-host "upload-blobs - inputs:----------------------------"
    write-host "subscriptionid:                 $SubscriptionId"
    write-host "resourcegroupname:        $ResourceGroupName"
    write-host "storageaccountname:       $Storageaccountname"
    write-host "sourcecontainername:            $Containername"
    write-host "------------------------------------------------"

    $sourcestorageaccount = get-azstorageaccount -resourcegroupname $ResourceGroupName -name $Storageaccountname 
    $sourcecontext = $sourcestorageaccount.context 

    write-host "start upload blobs"
    Set-AzStorageBlobContent -Container $Containername -File "C:\Users\sameer.ajmal\Downloads\epicms_Integration_20221006124443.bacpac" -Blob $FileName -Context $sourcecontext
    write-host "upload-blobs finished"

    }

# Import bacpac to database with an S3 performance level
#This function should be going into EpinovaAzureToolBucket.psm1

function Import-Bacpac-To-Database{

   [cmdletbinding()]
    param(
        [parameter(mandatory = $true)]
        [validatenotnullorempty()]
        [string] $ServerName = "sql-mycoolwebsite16-abn-inte",

        [parameter(mandatory = $true)]
        [validatenotnullorempty()]
        [string] $DatabaseName = "sqldb-mycoolwebsite16-abn-opticms-inte",

        [parameter(mandatory = $true)]
        [string] $ResourceGroupName = "rg-mycoolwebsite16-abn-inte",

        [parameter(mandatory = $true)]
        [string] $Storageaccountname = "stmycoolwebsite16inte",

        [parameter(mandatory = $true)]
        [validatenotnullorempty()]
        [string] $StorageContainername = "db-backups",

        [parameter(mandatory = $true)]
        [string] $AdminSqlLogin = "someLogin",

        [parameter(mandatory = $true)]
        [string] $Password = "KXIN-rhxh3holt-s8it",
        
        [parameter(mandatory = $true)]
        [string] $BacpacFilename = "epicms_Integration_20221006124443.bacpac"
    )

    $importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -DatabaseMaxSizeBytes 10GB `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageaccountname).Value[0] `
    -StorageUri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
    -AdministratorLogin "$adminSqlLogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)


    # Check import status and wait for the import to complete
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write("Importing")
    while ($importStatus.Status -eq "InProgress")
    {
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        [Console]::Write(".")
        Start-Sleep -s 10
    }
    [Console]::WriteLine("")
    $importStatus

    # Scale down to S0 after import is complete
    Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -DatabaseName $databaseName  `
        -Edition "Standard" `
        -RequestedServiceObjectiveName "S0"
}

 # Upload-Bacpac-File -Subscriptionid "$SubscriptionId" -Resourcegroupname "$Resourcegroupname" -Storageaccountname "$Storageaccountname" -Containername "$Containername" -FileName "$FileName"

  Import-Bacpac-To-Database -ServerName "$ServerName" -DatabaseName "$DatabaseName" -ResourceGroupName "$ResourceGroupName" -Storageaccountname "$Storageaccountname" -StorageContainername "$StorageContainername" -AdminSqlLogin "$AdminSqlLogin" -Password "$Password" -BacpacFilename "$BacpacFilename"

