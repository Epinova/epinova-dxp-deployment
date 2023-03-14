function Send-ContextInfo {
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


    #$url = "https://app-dxpbenchmark-3cpox1-inte.azurewebsites.net/PipelineRun"
    $url = "https://localhost:7002/PipelineRun"

    $postParams = @{ 
        "SessionId"="4bacdddc-807c-43d1-8e93-99c1dfff7670"
        "Task"="PStest"
        "TaskVersion"="1.2.10"
        "Environment"="Integration"
        "DxpProjectId"="bfea291e-6886-4904-a12f-d6c2e09dc3d5"
        "OrganisationId"="438a6774-a643-4b82-a962-19a7553be261" #System.CollectionId
        "OrganisationName"="Epinova-Sweden" #System.CollectionUri
        "ProjectId"="12f9e23a-c64f-490e-b63c-54d70eac71cb" #System.TeamProjectId
        "ProjectName"="Percytest" #System.TeamProject
        "Branch"="development" #Build.SourceBranchName
        "AgentOS"="windows-latest"#Agent.OS
        "EpiCloudVersion"="v1.2.0" #Make sure that Initialize-EpiCload set variable that we can read.
        "PowerShellVersion"="7.2.1" #$PSVersionTable
        "PowerShellEdition"="pwsh" #$PSVersionTable
        "Elapsed"="1000"
        "Result"="Succeeded"
        "FileSize"="100"
        }
    $json = $postParams | ConvertTo-Json
    $result = Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri $url -Body $json
    Write-Host $result
    $sessionId = $result.sessionId
    $message = $result.message
    #$sessionId = ($result | ConvertTo-Json).sessionId
    #$message = ($result | ConvertTo-Json).message
    Write-Host $sessionId
    Write-Host $message
}

Send-ContextInfo