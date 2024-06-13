
try {
    choco config get cacheLocation
}
catch {
    Write-Output "Chocolatey not detected, trying to install now"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

$chocolateyAppList = 'azure-cli|2.50.0,python38|3.8.10,vscode|1.79.2,vscode-python|2022.19.13071014,materialicon-vscode|4.28.0'

appsToInstall = $chocolateyAppList -split "," | foreach { "$($_.Trim())" }

foreach ($app in $appsToInstall) {

    $name = $app.Split("|")[0]
    $version = $app.Split("|")[1]
    $params = $app.Split("|")[2]
    
    Write-Host "Installing: $name | $version with extra params: [$params]"

    if ($null -eq $params) {
        Write-Host "choco install $name --version $version  /y -Force | Write-Output"
        & choco install $name --version $version  /y -Force | Write-Output
    }
    else {
        Write-Host "Installing: $name | $version"
        & choco install $name --version $version  --params $params /y -Force | Write-Output
    }
}