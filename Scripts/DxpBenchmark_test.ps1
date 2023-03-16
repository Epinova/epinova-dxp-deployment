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

    # {
    #     2023-03-14T15:38:43.0412676Z   "Branch": "merge",
    #     2023-03-14T15:38:43.0413593Z   "Result": "",
    #     2023-03-14T15:38:43.0415646Z   "PowerShellVersion": "v7.2.10",
    #     2023-03-14T15:38:43.0416904Z   "Task": "DxpExpectStatus-TEST",
    #     2023-03-14T15:38:43.0418585Z   "OrganisationId": "4465472b-c920-479f-975c-32466c8c89b9",
    #     2023-03-14T15:38:43.0419183Z   "PowerShellEdition": "Core",
    #     2023-03-14T15:38:43.0419658Z   "AgentOS": "Linux",
    #     2023-03-14T15:38:43.0420122Z   "Environment": "Integration",
    #     2023-03-14T15:38:43.0420552Z   "D
    #     2023-03-14T15:38:43.0421265Z xpProjectId": "c0f148a9-03e0-4d5d-a585-af47003dee5f",
    #     2023-03-14T15:38:43.0421775Z   "Elapsed": 0,
    #     2023-03-14T15:38:43.0422205Z   "EpiCloudVersion": "v1.2.0",
    #     2023-03-14T15:38:43.0422654Z   "FileSize": 0,
    #     2023-03-14T15:38:43.0423117Z   "ProjectName": "Elite Hotels public web",
    #     2023-03-14T15:38:43.0423619Z   "SessionId": "",
    #     2023-03-14T15:38:43.0424213Z   "ProjectId": "add96c9a-eeb4-4ce6-9cf2-2a09262bff47",
    #     2023-03-14T15:38:43.0424799Z   "OrganisationName": "Epinova-Sweden",
    #     2023-03-14T15:38:43.0425245Z   "TaskVersion": "2.6.12"
    #     2023-03-14T15:38:43.0425664Z }

    $postParams = @{ 
        "SessionId"="ACAC16F0-7CEF-4CFB-AD7B-DC626E9682C4"
        "Task"="DxpExpectStatus-TEST"
        "TaskVersion"="2.6.12"
        "Environment"="Integration"
        "DxpProjectId"="c0f148a9-03e0-4d5d-a585-af47003dee5f"
        "OrganisationId"="4465472b-c920-479f-975c-32466c8c89b9" #System.CollectionId
        "OrganisationName"="Epinova-Sweden" #System.CollectionUri
        "ProjectId"="add96c9a-eeb4-4ce6-9cf2-2a09262bff47" #System.TeamProjectId
        "ProjectName"="Elite Hotels public web" #System.TeamProject
        "Branch"="merge" #Build.SourceBranchName
        "AgentOS"="Linux"#Agent.OS
        "EpiCloudVersion"="v1.2.0" #Make sure that Initialize-EpiCload set variable that we can read.
        "PowerShellVersion"="v7.2.10" #$PSVersionTable
        "PowerShellEdition"="Core" #$PSVersionTable
        "Elapsed"=0
        "Result"=""
        "FileSize"=0
        }
    $json = $postParams | ConvertTo-Json
    $result = Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri $url -Body $json
    Write-Host $result
    $sessionId = $result.sessionId
    $message = $result.message
    Write-Host $sessionId
    Write-Host $message

    
    # $postParams = @{ 
    #     "SessionId"=$SessionId
    #     "Task"=$taskName
    #     "TaskVersion"=$taskVersion
    #     "Environment"=$Environment
    #     "DxpProjectId"=$ProjectId
    #     "OrganisationId"=$env:SYSTEM_COLLECTIONID #System.CollectionId
    #     "OrganisationName"=$orgName #System.CollectionUri
    #     "ProjectId"=$env:SYSTEM_TEAMPROJECTID #System.TeamProjectId
    #     "ProjectName"=$env:SYSTEM_TEAMPROJECT #System.TeamProject
    #     "Branch"=$env:BUILD_SOURCEBRANCHNAME #Build.SourceBranchName
    #     "AgentOS"=$env:AGENT_OS #Agent.OS
    #     "EpiCloudVersion"=$epiCloudVersion.Version #Make sure that Initialize-EpiCload set variable that we can read.
    #     "PowerShellVersion"="v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)" #$PSVersionTable
    #     "PowerShellEdition"=$PSVersionTable.PSEdition #$PSVersionTable
    #     "Elapsed"=$Elapsed
    #     "Result"=$Result
    #     "FileSize"=$FileSize
    #     }
    # $json = $postParams | ConvertTo-Json
    # Write-Host $json
}

Send-ContextInfo