<#


.DESCRIPTION
    Help functions for Epinova DXP deployment extension.
#>

Set-StrictMode -Version Latest
function Write-DxpHostInfo() {
    $version = Get-Host | Select-Object Version
    Write-Host $version
}

Export-ModuleMember -Function @( 'Write-DxpHostInfo' )