[CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $clientKey = "",
        [Parameter(Mandatory=$false)]
        [string] $clientSecret = "",
        [Parameter(Mandatory=$false)]
        [string] $projectId = "",
        [Parameter(Mandatory=$false)]
        [string] $environment = "Integration" #Integration | Preproduction | Production
    )

Set-StrictMode -Version Latest 
####################################################################################


function Test-IsGuid() {
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ObjectGuid
	)
	
	# Define verification regex
	[regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

	# Check guid against regex
	return $ObjectGuid -match $guidRegex
}

function WriteInfo() {
    $version = Get-Host | Select-Object Version
    Write-Host $version
}

function ImportAzureStorageModule {
    $azModuleLoaded = Get-Module -Name "Az.Storage"

    if (-not ($azureModuleLoaded -or $azModuleLoaded)) {
        try {
            $null = Import-Module -Name "Az.Storage" -ErrorAction Stop
            $azModuleLoaded = $true
        }
        catch {
            Write-Verbose "Tried to find 'Az.Storage', module couldn't be imported."
        }
    }

    if ($azModuleLoaded) {
        "Az"
    }
    else {
        throw "'Az.Storage' module is required to run this cmdlet."
    }
}

    ####################################################################################

    Write-Host "Inputs:"
    Write-Host "ClientKey: $clientKey"
    Write-Host "ClientSecret: **** (it is a secret...)"
    Write-Host "ProjectId: $projectId"
    Write-Host "Environment: $environment"

    WriteInfo

    #Check values/params
    if ((Test-IsGuid -ObjectGuid $projectId) -ne $true){
        Write-Error "The provided ProjectId is not a guid value."
        exit
    }

    if ($environment -eq "Integration" -or $environment -eq "Preproduction" -or $environment -eq "Production") {
        Write-Host "Environment param ok."
    }
    else {
        Write-Error "The environment $environment that you have specified does not exist. Ok environments: Integration | Preproduction | Production"
        exit
    }

    # if ($container -eq "AppLogs"){
    #     $container = "azure-application-logs"
    # } elseif ($container -eq "WebLogs"){
    #     $container = "azure-web-logs"
    # } elseif ($container -eq "Blobs"){
    #     $container = "mysitemedia"
    # } 

    #if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    #    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
    #        'Az modules installed at the same time is not supported.')
    #} else {
    #    Install-Module -Name Az -AllowClobber -Scope CurrentUser
    #}

    if (-not (Get-Module -Name EpiCloud -ListAvailable)) {
        Install-Module EpiCloud -Scope CurrentUser -Force
    }

    try {
        Connect-EpiCloud -ClientKey $clientKey -ClientSecret $clientSecret
    }
    catch {
        Write-Error "Could not connect to EpiCload API with specified ClientKey/ClientSecret"
        exit
    }
    
    $storageContainerSplat = @{
        ProjectId          = $projectId
        Environment = $environment
    }

    try {
        $containerResult = Get-EpiStorageContainer @storageContainerSplat
    }
    catch {
        Write-Error "Could not get storage container information from Epi. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    if ($null -eq $containerResult){
        Write-Error "Could not get Epi DXP storage containers. Make sure you have specified correct ProjectId/Environment"
        exit
    }

    Write-Host "Containers:-------------------"
    $containerResult.storageContainers | Format-Table
    Write-Host "------------------------------"

    ####################################################################################

    Write-Host "---THE END---"