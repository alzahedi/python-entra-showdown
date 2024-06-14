
param(
    [string]
    $SPN_CLIENT_ID,
    [string]
    $SPN_CLIENT_SECRET,
    [string]
    $TENANT_ID,
    [string]
    $SUBSCRIPTION_ID,
    [string]
    $RESOURCE_GROUP_NAME,
    [string]
    $LOCATION
)

try {
    choco config get cacheLocation
}
catch {
    Write-Output "Chocolatey not detected, trying to install now"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

$chocolateyAppList = 'azure-cli|2.50.0,python38|3.8.10,vscode|1.79.2,vscode-python|2022.19.13071014,materialicon-vscode|4.28.0'

$appsToInstall = $chocolateyAppList -split "," | foreach { "$($_.Trim())" }

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

# load env path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 

# login to azure
az login --service-principal --username $SPN_CLIENT_ID --password $SPN_CLIENT_SECRET --tenant $TENANT_ID
# set subscription
az account set --subscription $SUBSCRIPTION_ID

function downloadArcAgent() {
    <#

    .SYNOPSIS
    Downloads the Azure Arc Connected Machine Agent from the Microsoft download site.

    #>
    $ProgressPreference="SilentlyContinue"; 
    Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi
}

function getTokenFromArc(){
    $apiVersion = "2020-06-01"
    $resource = "https://management.azure.com/"
    $endpoint = "{0}?resource={1}&api-version={2}" -f $env:IDENTITY_ENDPOINT,$resource,$apiVersion
    $secretFile = ""
    try
    {
        Invoke-WebRequest -Method GET -Uri $endpoint -Headers @{Metadata='True'} -UseBasicParsing
    }
    catch
    {
        $wwwAuthHeader = $_.Exception.Response.Headers["WWW-Authenticate"]
        if ($wwwAuthHeader -match "Basic realm=.+")
        {
            $secretFile = ($wwwAuthHeader -split "Basic realm=")[1]
        }
    }
    Write-Host "Secret file path: " $secretFile`n
    $secret = cat -Raw $secretFile
    $response = Invoke-WebRequest -Method GET -Uri $endpoint -Headers @{Metadata='True'; Authorization="Basic $secret"} -UseBasicParsing
    if ($response)
    {
        $token = (ConvertFrom-Json -InputObject $response.Content).access_token
        return $token
    }
    return $null
}

function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory=$true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}

# Create Resource Group - idempotent
#
Write-Host "Creating resource group and adding skip Auto-onboarding tag, since we want to test additional permutations..."
az group create --name $RESOURCE_GROUP_NAME `
                --location $LOCATION `
                --tags "ArcSQLServerExtensionDeployment=Disabled"


# Download and install the Azure Arc Agent                
Write-Host "Downloading Arc Agent..."
downloadArcAgent

Write-Host "Starting Arc Agent installation..."
$exitCode = (Start-Process -FilePath msiexec.exe -ArgumentList @("/i", "AzureConnectedMachineAgent.msi" ,"/l*v", "installationlog.txt", "/qn") -Wait -Passthru).ExitCode

if($exitCode -ne 0) {
    $message=(net helpmsg $exitCode)
    throw "Installation failed: $message See installationlog.txt for additional details."
}

$vmName = hostname

# Run connect command
#
& "$Env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
--service-principal-id $SPN_CLIENT_ID `
--service-principal-secret $SPN_CLIENT_SECRET `
--resource-group $RESOURCE_GROUP_NAME `
--tenant-id $TENANT_ID `
--location $LOCATION `
--subscription-id $SUBSCRIPTION_ID `
--resource-name $vmName `
--cloud "AzureCloud" `
--tags "Project=arceedata" `
--correlation-id "d009f5dd-dba8-4ac7-bac9-b54ef3a6671a" # Do no change!

if($LastExitCode -eq 0){Write-Host -ForegroundColor yellow "To view your onboarded server(s), navigate to https://ms.portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.HybridCompute%2Fmachines"}

Write-Host "Arc Agent Installation complete."

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 

# Get token from arc
$token = getTokenFromArc
$parsedToken = Parse-JWTtoken -token $token
$appId = $parsedToken.appid

# Go ahead and replace spn client id with app id
$userDirectory = $env:USERPROFILE
Write-Host "User directory is $userDirectory"

Push-Location $userDirectory\.azure

(Get-Content azureProfile.json).Replace($SPN_CLIENT_ID, $appId) | Set-Content azureProfile.json

Pop-Location

$GIT_ROOT = git rev-parse --show-toplevel
cd "$GIT_ROOT"

New-Item .env | Out-Null

$content = "TENANT_ID=$TENANT_ID"

Add-Content ".env" $content

python -m venv venv

.\venv\Scripts\Activate.ps1

pip install -r requirements.txt

Write-Host "Pre-requisites installed successfully"

python .\decrypt-token-store.py

Write-Host "Token decrypted successfully"


