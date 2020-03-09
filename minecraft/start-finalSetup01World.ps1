$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

$worldDest = if ($env:TYPE -eq "FEED-THE-BEAST") {
  "$env:FTB_BASE_DIR/$env:LEVEL"
} else {
  "/data/$env:LEVEL"
}

# If no world exists and a URL for a world is supplied, download it and unpack
if ($env:WORLD -and !(Test-Path -Path $worldDest)) {
  New-Item -Path $worldDest -ItemType Directory | Out-Null
  switch -regex ("X$env:WORLD") {
    "^XHTTP.*$" {
      Write-Host "Downloading world from $env:WORLD"

      Invoke-WebRequest -Uri $env:WORLD -OutFile '/data/world.zip'
      New-Item -Path C:\temp -ItemType Directory | Out-Null
      Expand-Archive -Path '/data/world.zip' -DestinationPath C:\temp
      Remove-Item -Path '/data/world.zip'

      $innerWorld = (Get-ChildItem -Path C:\temp -Filter 'level.dat' -Recurse).DirectoryName
      if (!$innerWorld) {
        Write-Error "World directory not found"
        exit 1
      }

      xcopy $innerWorld $worldDest /E /Y /Q
      Remove-Item -Path C:\temp -Recurse
    }
    default {
      if (Test-Path -Path $env:WORLD) {
        if (!(Test-Path -Path $worldDest)) {
          Write-Host "Cloning world directory from $env:WORLD ..."
          xcopy $env:WORLD $worldDest /E /Y /Q
        } else {
          Write-Host "Skipping clone from $env:WORLD since $worldDest exists"
        }
      } else {
        Write-Host "Invalid URL given for world: Must be HTTP or HTTPS and a ZIP file"
      }
    }
  }
}

& $PSScriptRoot\start-finalSetup02Modpack.ps1
