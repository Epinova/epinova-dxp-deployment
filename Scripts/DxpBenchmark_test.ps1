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
    #$url = "https://app-dxpbenchmark-3cpox1-prod.azurewebsites.net/PipelineRun"
    $url = "https://localhost:7002/PipelineRun"

    # $postParams = @{ 
    #     "SessionId"="ACAC16F0-7CEF-4CFB-AD7B-DC626E9682C4"
    #     "Task"="DxpExpectStatus-TEST"
    #     "TaskVersion"="2.6.12"
    #     "TargetEnvironment"=""
    #     "Environment"="Integration"
    #     "DxpProjectId"="c0f148a9-03e0-4d5d-a585-af47003dee5f"
    #     "OrganisationId"="4465472b-c920-479f-975c-32466c8c89b9" #System.CollectionId
    #     "OrganisationName"="Epinova-Sweden" #System.CollectionUri
    #     "ProjectId"="add96c9a-eeb4-4ce6-9cf2-2a09262bff47" #System.TeamProjectId
    #     "ProjectName"="Elite Hotels public web" #System.TeamProject
    #     "Branch"="merge" #Build.SourceBranchName
    #     "AgentOS"="Linux"#Agent.OS
    #     "EpiCloudVersion"="v1.2.0" #Make sure that Initialize-EpiCload set variable that we can read.
    #     "PowerShellVersion"="v7.2.10" #$PSVersionTable
    #     "PowerShellEdition"="Core" #$PSVersionTable
    #     "Elapsed"=0
    #     "Result"=""
    #     "FileSize"=0
    #     "PackageName"="asdasdsda.nuget"
    #     }

    $postParams = @{
        "ProjectId"="add96c9a-eeb4-4ce6-9cf2-2a09262bff47"
        "OrganisationId"="4465472b-c920-479f-975c-32466c8c89b9"
        "DxpProjectId"="c0f148a9-03e0-4d5d-a585-af47003dee5f"
        "OrganisationName"="Epinova-Sweden"
        "Elapsed"=10570
        "AgentOS"="Linux"
        "Task"="DxpExpectStatus"
        "PowerShellVersion"="v7.2.10"
        "Result"="Succeeded"
        "ProjectName"="Elite Hotels public web"
        "TaskVersion"="2.6.36"
        "PowerShellEdition"="Core"
        "TargetEnvironment"="Integration"
        "EpiCloudVersion"="v1.2.0"
        "Branch"="develop"
        "ReleaseReason"=$null
        "AgentVersion"=$null
        "Pipeline"=$null
        "ReleaseName"=$null
        "StageName"=$null
        }

    $json = $postParams | ConvertTo-Json
    $result = Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri $url -Body $json
    #Write-Host $result
    $sessionId = $result.sessionId
    $message = $result.message
    Write-Host $sessionId
    Write-Host $message

    #Invoke-RestMethod -Method 'Post' -ContentType "application/json" -Uri "https://1b680dac-bf88-4fcb-872d-94e2d8c7d150.webhook.we.azure-automation.net/webhooks?token=fFJVjF2DeIqtLsqjREjGgFZ5CSe67bV%2fkIhvS%2bfRNzA%3d" -TimeoutSec 5
}

Send-ContextInfo