Remove-Module -Name "EpinovaDxpToolBucket" -Verbose
Import-Module -Name E:\dev\epinova-dxp-deployment\Modules\EpinovaDxpToolBucket -Verbose

#Indutrade intra
[string] $clientKey = "2iM3FlZfnNs5HLC3HeZmQa3gJk4XbAWlamh2BrORNcobAWkf"
[string] $clientSecret = "Aj0swN1wpymdJnWVqUqO7nLColgMwfjM3Q7OB148i0rwimBRPtEHsUlYqN1X8H8Q"
[string] $projectId = "4971827e-2eca-4fb3-8015-a98f016bacc5"

Set-ExecutionPolicy Unrestricted
#Get-DxpProjectBlobs -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "Blobs" -OverwriteExistingFiles 1 -RetentionHours 2
Get-DxpProjectBlobs -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId -Environment "Integration" -DownloadFolder "E:\dev\temp\_blobDownloads" -MaxFilesToDownload 10 -Container "contentassets" -OverwriteExistingFiles 1 -RetentionHours 2