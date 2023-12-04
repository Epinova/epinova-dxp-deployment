Set-ExecutionPolicy -Scope CurrentUser Unrestricted

. "$PSScriptRoot\Params.ps1" #$clientkey, $clientSecret, $projectId, $environment is set in this Params file to be reused by all scripts.
$bacpacFilePath = "E:\dev\temp\TestEpiCloud13\alloy.cms.sqldb.2.bacpac"
$nupkgFilePath = "E:\dev\temp\TestEpiCloud13\AlloyMvcTemplate.Cms.App.0.0.0.9.nupkg"

# First we need to get the SAS URL to the package location where the nupkg and bacpac files can be uploaded.
$packageLocation = Get-EpiDeploymentPackageLocation -ClientKey $clientKey -ClientSecret $clientSecret -ProjectId $projectId
Write-Host "Retrieved package location"

# Upload the bacpac file
$bacpacFileInfo = Get-Item -Path $bacpacFilePath
#$packageFileInfo = Get-Item -Path "E:\dev\temp\TestEpiCloud13\cms.sqldb.1.bacpac"
Add-EpiDeploymentPackage -SasUrl $packageLocation -Path $bacpacFileInfo.FullName
$bacpacFile = $bacpacFileInfo.Name
Write-Host "Uploaded $($bacpacFileInfo.FullName)"

# Upload the nupkg file
$nupkgFileInfo = Get-Item -Path $nupkgFilePath
#$packageFileInfo = Get-Item -Path "E:\dev\temp\TestEpiCloud13\Nas.Portal.Cms.App.0.0.0.6.nupkg"
Add-EpiDeploymentPackage -SasUrl $packageLocation -Path $nupkgFileInfo.FullName
$nupkgFile = $nupkgFileInfo.Name
Write-Host "Uploaded $($nupkgFileInfo.FullName)"

# Now when the files are uploaded we can start a deploy of the uploaded files to the integration environment.
$DeploymentHash = @{
    ClientKey          = $clientKey
    ClientSecret       = $clientSecret
    ProjectId          = $projectId
    TargetEnvironment  = $environment
    DeploymentPackage  = @($nupkgFile, $bacpacFile)
    #DeploymentPackage  = @('Nas.Portal.Cms.App.0.0.0.6.nupkg', 'cms.sqldb.1.bacpac')
    DirectDeploy       = $true
    Wait               = $true
    PollingIntervalSec = 10
    WaitTimeoutMinutes = 30
    ShowProgress       = $true
}
Start-EpiDeployment @DeploymentHash