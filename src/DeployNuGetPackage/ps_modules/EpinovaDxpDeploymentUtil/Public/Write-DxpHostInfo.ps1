function Write-DxpHostInfo() {
    $version = Get-Host | Select-Object Version
    Write-Host $version
}