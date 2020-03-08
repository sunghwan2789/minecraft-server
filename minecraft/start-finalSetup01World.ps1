$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

$worldDest = if ($env:TYPE -eq "FEED-THE-BEAST") {
  "$env:FTB_BASE_DIR/$env:LEVEL"
} else {
  "/data/$env:LEVEL"
}

# If no world exists and a URL for a world is supplied, download it and unpack
if ($env:WORLD -and !(Test-Path $worldDest)) {
  New-Item $worldDest -ItemType Directory | Out-Null
  switch -regex ("X$env:WORLD") {
    "XHTTP.*" {
      Write-Host "Downloading world from $env:WORLD"
      New-Item '/temp' -ItemType Directory | Out-Null

      Invoke-WebRequest $env:WORLD -OutFile '/data/world.zip'
      Expand-Archive '/data/world.zip' -DestinationPath '/temp'
      Remove-Item '/data/world.zip'

      $innerWorld = (Get-ChildItem '/temp' -Filter 'level.dat' -Recurse).DirectoryName
      if (!$innerWorld) {
        Write-Error "World directory not found"
        exit 1
      }

      xcopy $innerWorld $worldDest /C /S /Y
      Remove-Item '/temp' -Recurse
    }
    default {
      if (Test-Path $env:WORLD) {
        if (!(Test-Path $worldDest)) {
          Write-Host "Cloning world directory from $env:WORLD ..."
          xcopy $env:WORLD $worldDest /C /S /Y
        } else {
          Write-Host "Skipping clone from $env:WORLD since $worldDest exists"
        }
      } else {
        Write-Host "Invalid URL given for world: Must be HTTP or HTTPS and a ZIP file"
      }
    }
  }
}

& "$PSScriptRoot\start-finalSetup02Modpack.ps1"
