if (-not ($env:PSModulePath.Contains("$PSScriptRoot"))){
    $env:PSModulePath = "$PSScriptRoot;" + $env:PSModulePath   
}
#Write-Host $env:PSModulePath

#Uninstall-Module -Name EpinovaDxpDeploymentUtil
#Get-Module -Name EpinovaDxpDeploymentUtil -ListAvailable

#Write-DxpHostInfo

try{
    if (-not (Get-Module -Name EpinovaDxpDeploymentUtil -ListAvailable)) {
        Write-Host "Could not find EpinovaDxpDeploymentUtil. Install it."
        Install-Module EpinovaDxpDeploymentUtil -Scope CurrentUser -Force
    }else{
        Get-Module -Name EpinovaDxpDeploymentUtil -ListAvailable
    }

    Write-DxpHostInfo
}
catch{
    $errorMessage = $_.Exception.Message
    Write-Host $errorMessage
}
Write-Host "---THE END---"