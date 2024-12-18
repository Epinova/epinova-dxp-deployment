@{
    RootModule        = 'EpinovaDxpToolBucket.psm1'
    ModuleVersion     = '0.15.1'
    GUID              = '94759945-9241-47c5-8c9c-72270402b363'
    Author            = 'Ove Lartelius'
    CompanyName       = 'Epinova AB, LOL IT AB'
    Copyright         = '(c) 2023 Epinova AB. All rights reserved.'
    Description       = 'Module contain help functions for the Epinova Optimizely DXP vs Azure Portal and run in Octopus deploy. Use EpiCloud v1.7'
    PowerShellVersion = '5.0'
    FunctionsToExport = 'Invoke-DxpBlobsDownload', 'Invoke-DxpDatabaseDownload', 'Get-DxpStorageContainers', 'Get-DxpStorageContainerSasLink', 'Invoke-DxpAwaitStatus', 'Invoke-DxpCompleteDeploy', 'Invoke-DxpDeployNuGetPackage', 'Invoke-DxpDeployTo', 'Invoke-DxpExpectStatus', 'Invoke-DxpResetDeploy', 'Invoke-DxpSmokeTestIfFailReset'
    CmdletsToExport   = @()
    AliasesToExport   = @()
}