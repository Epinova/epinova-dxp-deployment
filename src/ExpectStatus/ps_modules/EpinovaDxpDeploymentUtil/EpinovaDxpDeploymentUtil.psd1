@{
    RootModule        = 'EpinovaDxpDeploymentUtil.psm1'
    ModuleVersion     = '0.0.3'
    GUID              = '00740cd5-5e72-4fb7-9a6b-1afd534df2d2'
    Author            = 'Ove Lartelius'
    CompanyName       = 'Epinova AB, LOL IT AB'
    Copyright         = '(c) 2021 Epinova AB. All rights reserved.'
    Description       = 'Module contain help functions for the Epinova DXP deployment extension.'
    PowerShellVersion = '5.0'
    FunctionsToExport = 'Write-DxpHostVersion', 'Test-DxpProjectId'
    CmdletsToExport   = @()
    AliasesToExport   = @()
}