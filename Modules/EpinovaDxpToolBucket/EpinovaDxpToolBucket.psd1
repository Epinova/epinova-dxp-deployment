@{
    RootModule        = 'EpinovaDxpToolBucket.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '94759945-9241-47c5-8c9c-72270402b363'
    Author            = 'Ove Lartelius'
    CompanyName       = 'Epinova AB, LOL IT AB'
    Copyright         = '(c) 2021 Epinova AB. All rights reserved.'
    Description       = 'Module contain help functions for the Epinova DXP vs Azure Portal.'
    PowerShellVersion = '5.0'
    FunctionsToExport = 'Write-DxpHostVersion', 'Get-DxpDateTimeStamp', 'Invoke-DxpProgress', 'Connect-DxpEpiCloud', 'Import-AzureStorageModule', 'Test-DxpProjectId'
    CmdletsToExport   = @()
    AliasesToExport   = @()
}