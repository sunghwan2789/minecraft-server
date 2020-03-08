# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2019

SHELL [ "powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';" ]

# Directory that bundle should be installed to
ARG BUNDLE_DESTINATION

# Directory that bundle binary located in
ARG BUNDLE_HOME

# List of key=value environment variable that delimited with |
ARG ENVIRONMENT_VARIABLES

RUN $bundleHome = (($env:BUNDLE_HOME, $env:BUNDLE_DESTINATION) -ne $null)[0]; `
  $newPath = ('{0};{1}' -f $bundleHome, $env:PATH); `
  Write-Host ('Updating PATH: {0}' -f $newPath); `
  setx /M PATH $newPath; `
  `
  if ($env:ENVIRONMENT_VARIABLES) { `
    Write-Host 'Setting environmet variables ...'; `
    ($env:ENVIRONMENT_VARIABLES -split '\|') | ForEach-Object { `
      Write-Host ('  {0}' -f $_); `
      setx /M ($_ -split '=', 2); `
    } `
  }

# URL that can download bundle archive
ARG BUNDLE_URL=https://github.com/PowerShell/PowerShell/releases/download/v6.2.4/PowerShell-6.2.4-win-x64.zip

# Command that is used to verify installation
ARG VERIFY_COMMAND="pwsh -Version"

RUN Write-Host ('Downloading {0} ...' -f $env:BUNDLE_URL); `
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
  Invoke-WebRequest -Uri $env:BUNDLE_URL -OutFile bundle.zip; `
  `
  Write-Host 'Expanding ...'; `
  New-Item -Path C:\temp -ItemType Directory | Out-Null; `
  tar -xf bundle.zip -C C:\temp; `
  if (((Get-ChildItem -Path C:\temp -Directory).Length -eq 1) `
    -and ((Get-ChildItem -Path C:\temp -File).Length -eq 0)) { `
    Move-Item -Path C:\temp\* -Destination $env:BUNDLE_DESTINATION; `
    Remove-Item -Path C:\temp; `
  } else { `
    Move-Item -Path C:\temp -Destination $env:BUNDLE_DESTINATION; `
  } `
  `
  Write-Host 'Removing ...'; `
  Remove-Item -Path bundle.zip; `
  `
  Write-Host 'Verifying install ...'; `
  Write-Host ('  {0}' -f $env:VERIFY_COMMAND); `
  Invoke-Expression -Command $env:VERIFY_COMMAND; `
  `
  Write-Host 'Complete.'
