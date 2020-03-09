$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

if (!(Test-Path -Path "$pwd\eula.txt")) {
  if ($env:EULA -ne 'TRUE') {
    Write-Host ""
    Write-Host "Please accept the Minecraft EULA at"
    Write-Host "  https://account.mojang.com/documents/minecraft_eula"
    Write-Host "by adding the following immediately after 'docker run':"
    Write-Host "  -e EULA=TRUE"
    Write-Host ""
    exit 1
  }

  "# Generated via Docker on $(date)" | Out-File -FilePath eula.txt
  "eula=$env:EULA" | Out-File -FilePath eula.txt -Append
}


# log "Running as uid=$(id -u) gid=$(id -g) with /data as '$(ls -lnd /data)'"

# if ! touch /data/.verify_access; then
#   log "ERROR: /data doesn't seem to be writable. Please make sure attached directory is writable by uid=$(id -u)"
#   exit 2
# fi

# rm /data/.verify_access || true

# if [[ $PROXY ]]; then
#     export http_proxy="$PROXY"
#     export https_proxy="$PROXY"
#     log "INFO: Giving proxy time to startup..."
#     sleep 5
# fi

$env:SERVER_PROPERTIES = "/data/server.properties"
$env:VERSIONS_JSON = "https://launchermeta.mojang.com/mc/game/version_manifest.json"

# 2017-12-14 - Workaround for Azure Container Instances, where the network is not always immediately available for Windows Containers
$isNetworkAvailable = $false
while (!$isNetworkAvailable) {
  try {
    Invoke-WebRequest -Uri $env:VERSIONS_JSON | Out-Null
    $isNetworkAvailable = $true
  } catch {
    $date = Get-Date -Format g
    Write-Host "$date - Waiting on the network to become available"
    Start-Sleep -Seconds 5
  }
}

Write-Host "Checking version information."
$env:VANILLA_VERSION = switch -regex ("X$env:VERSION") {
  "^(X|XLATEST)$" {
    (Invoke-WebRequest -Uri $env:VERSIONS_JSON | ConvertFrom-Json).latest.release
    break
  }
  "^XSNAPSHOT$" {
    (Invoke-WebRequest -Uri $env:VERSIONS_JSON | ConvertFrom-Json).latest.snapshot
    break
  }
  "^X[1-9].*$" {
    $env:VERSION
    break
  }
  default {
    (Invoke-WebRequest -Uri $env:VERSIONS_JSON | ConvertFrom-Json).latest.release
    break
  }
}

$env:ORIGINAL_TYPE = $env:TYPE

Write-Host "Checking type information."
switch -regex ($env:TYPE) {
  # *BUKKIT|SPIGOT)
  #   exec /start-deployBukkitSpigot $@
  # ;;

  # PAPER)
  #   exec /start-deployPaper $@
  # ;;

  # FORGE)
  #   exec /start-deployForge $@
  # ;;

  # FABRIC)
  #   exec /start-deployFabric $@
  # ;;

  # FTB|CURSEFORGE)
  #   exec /start-deployFTB $@
  # ;;
  "^VANILLA$" {
    & $PSScriptRoot\start-deployVanilla.ps1
    break
  }
  # SPONGEVANILLA)
  #   exec /start-deploySpongeVanilla $@
  # ;;

  # CUSTOM)
  #   exec /start-deployCustom $@
  # ;;
  default {
    Write-Host "Invalid type: '$env:TYPE'"
    Write-Host "Must be: VANILLA, FORGE, BUKKIT, SPIGOT, PAPER, FTB, CURSEFORGE, SPONGEVANILLA"
    exit 1
  }
}
