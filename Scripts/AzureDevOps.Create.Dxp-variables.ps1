# How to create a PAT to your Azure DevOps: https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows
# Pattern: "https://dev.azure.com/$organization/$projectName/ Look in the browser for your project and you will get organization and project.
$organization = "YourOrganization" #The name of the Azure DevOps organization
$projectName  = "TheProject" #The name of the project in the Azure DevOps organization
$access_token = "sxdvx2ry64xj1ujxz5tc4xhrizx4syxjxj4xx33xoxyxmxjxcxzx" # Your PAT that you create to get access.
$groupName = "DXP-variables"

$B64Pat = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$access_token"))
#Write-Host $B64Pat

try{
    # First list groups
    $url = "https://dev.azure.com/$organization/$projectName/_apis/distributedtask/variablegroups?api-version=7.0&groupName=$groupName*"
    $response = Invoke-RestMethod -Method GET -Headers @{Authorization= "Basic $B64Pat"} -Uri $url
    #Write-Host $response
    if ($response.count -gt 0){
        Write-Host "Found variable group $($response.value.id) with name $($response.value.name)"
        Write-Host "Will not create variable group '$groupName'"
    } 
    elseif ($response.count -eq 0){
        Write-Host "Found no existing variable group with name '$groupName'"
        Write-Host "Start create variable group '$groupName'."
        $url = "https://dev.azure.com/$organization/$projectName/_apis/distributedtask/variablegroups?api-version=5.0-preview.1"
$json = @"
{
"variables": { 
    "ClientKey": { "value": "[Replace with DXP ClientKey]" }, 
    "ClientSecret": { "value": "[Replace with DXP ClientSecret]", "isSecret": false }, 
    "DXP.ProjectId": { "value": "[DXP projectid (GUID)]" },
    "Integration.SlotUrl": { "value": "https://[projectname]inte-slot.dxcloud.episerver.net" },
    "Integration.Url": { "value": "https://[projectname]inte.dxcloud.episerver.net" },
    "Integration.UrlSuffix": { "value": "/util/login" },
    "Preproduction.SlotUrl": { "value": "https://[projectname]prep-slot.dxcloud.episerver.net" },
    "Preproduction.Url": { "value": "https://[projectname]prep.dxcloud.episerver.net" },
    "Preproduction.UrlSuffix": { "value": "/util/login" },
    "Production.SlotUrl": { "value": "https://[projectname]prod-slot.dxcloud.episerver.net" },
    "Production.Url": { "value": "https://[projectname]prod.dxcloud.episerver.net" },
    "Production.UrlSuffix": { "value": "/util/login" },
    "NuGetPackageNamePrefix": { "value": "Website" }
},
"type": "Vsts",
"name": "$groupName",
"description": "Variables that will be used by release pipelines for release to Optimizely DXP."
}
"@
        $response = Invoke-RestMethod -ContentType "application/json" -Method POST -Headers @{Authorization="Basic $B64Pat"} -Uri $url -Body $json
        Write-Host $response
        Write-Host "Variable group '$groupName' is now created."
    }

} catch {
    $errorResponse = $_.Exception.Response
    #Write-Host $errorResponse
    Write-Host $_.Exception
    Write-Host "Something is wrong"
}
Write-Host "---The end---"