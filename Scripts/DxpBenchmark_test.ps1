
# $url = "https://app-dxpbenchmark-3cpox1-inte.azurewebsites.net/PipelineRun"

# $postParams = @{ 
#     "Task"="PStest"

#     }
# $json = $postParams | ConvertTo-Json


# #Agent.OS
# #Build.Repository.Uri
# #Build.SourceBranchName
# #System.CollectionId
# #System.CollectionUri
# #System.TeamProject
# #System.TeamProjectId
# #Execution time
# #Result Succeeded/Failed
# #If deploy nuget file size


# Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri $url -Body $json #-OutFile output.csv

function Send-ContextInfo {
    $url = "https://app-dxpbenchmark-3cpox1-inte.azurewebsites.net/PipelineRun"

    $postParams = @{ 
        "Task"="PStest"
    
        }
    $json = $postParams | ConvertTo-Json
    Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri $url -Body $json
    
}

Send-ContextInfo