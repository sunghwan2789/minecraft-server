$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

$env:SERVER = "minecraft_server." + ($env:VANILLA_VERSION -replace '\s', '_') + ".jar"

if (!(Test-Path -Path $env:SERVER) -or ($null -ne $env:FORCE_REDOWNLOAD)) {
  Write-Host "Downloading $env:SERVER ..."

  Write-Debug "Finding version manifest for $env:VANILLA_VERSION"
  $versions = (Invoke-WebRequest -Uri $env:VERSIONS_JSON | ConvertFrom-Json).versions
  $versionManifestUrl = ($versions | Where-Object { $_.id -eq $env:VANILLA_VERSION })[0].url
  if (!$versionManifestUrl) {
    Write-Error "Couldn't find a matching manifest entry for $env:VANILLA_VERSION"
    exit 1
  }
  Write-Debug "Found version manifest at $versionManifestUrl"

  $serverDownloadUrl = (Invoke-WebRequest -Uri $versionManifestUrl | ConvertFrom-Json).downloads.server.url
  if (!$serverDownloadUrl) {
    Write-Error "Failed to obtain version manifest from $versionManifestUrl"
    exit 1
  }

  Write-Debug "Downloading server from $serverDownloadUrl"
  Invoke-WebRequest -Uri $serverDownloadUrl -OutFile $env:SERVER
}

# Continue to Final Setup
& $PSScriptRoot\start-finalSetup01World.ps1
