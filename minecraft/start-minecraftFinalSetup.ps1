$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

if ($env:OPS) {
  Write-Host "Setting/adding ops"
  Remove-Item -Path ops.txt.converted -ErrorAction Ignore
  $env:OPS -split ',' | Out-File -FilePath ops.txt
}

if ($env:WHITELIST) {
  Write-Host "Setting whitelist"
  Remove-Item -Path white-list.txt.converted -ErrorAction Ignore
  $env:WHITELIST -split ',' | Out-File -FilePath white-list.txt
}

# if [ -n "$ICON" -a ! -e server-icon.png ]; then
#   log "Using server icon from $ICON..."
#   # Not sure what it is yet...call it "img"
#   curl -sSL -o /tmp/icon.img $ICON
#   specs=$(identify /tmp/icon.img | awk '{print $2,$3}')
#   if [ "$specs" = "PNG 64x64" ]; then
#     mv /tmp/icon.img /data/server-icon.png
#   else
#     log "Converting image to 64x64 PNG..."
#     convert /tmp/icon.img -resize 64x64! /data/server-icon.png
#   fi
# fi

# Make sure files exist and are valid JSON (for pre-1.12 to 1.12 upgrades)
Write-Host "Checking for JSON files."
Get-ChildItem -Filter '*.json' | ForEach-Object {
  if (!(Get-Content -Path $_ -Raw) -replace '\s', '') {
    Write-Host "Fixing JSON $_"
    '[]' | Out-File -FilePath $_
  }
}


# # If any modules have been provided, copy them over
# mkdir -p /data/mods
# if [ -d /mods ]; then
#   log "Copying any mods over..."
#   rsync -a --out-format="update:%f:Last Modified %M" --prune-empty-dirs --update /mods /data
# fi

# [ -d /data/config ] || mkdir /data/config
# for c in /config/*
# do
#   if [ -f "$c" ]; then
#     log Copying configuration `basename "$c"`
#     cp -rf "$c" /data/config
#   fi
# done

# mkdir -p /data/plugins
# if [ "$TYPE" = "SPIGOT" ]; then
#   if [ -d /plugins ]; then
#     log "Copying any Bukkit plugins over..."
#     # Copy plugins over using rsync to allow deeply nested updates of plugins
#     # only updates files if the source file is newer and print updated files
#     rsync -a --out-format="update:%f:Last Modified %M" --prune-empty-dirs --update /plugins /data
#   fi
# fi

$EXTRA_ARGS = ""
# Optional disable console
if ($env:CONSOLE -eq 'FALSE') {
  $EXTRA_ARGS += "--noconsole"
}

# Optional disable GUI for headless servers
# if [[ ${GUI} = false || ${GUI} = FALSE ]]; then
# Workaround - Server without nogui blows up in Windows containers
$EXTRA_ARGS = "$EXTRA_ARGS nogui"
# fi

# put these prior JVM_OPTS at the end to give any memory settings there higher precedence
$INIT_MEMORY = (($env:INIT_MEMORY, $env:MEMORY) -ne $null)[0]
$MAX_MEMORY = (($env:MAX_MEMORY, $env:MEMORY) -ne $null)[0]
Write-Host "Setting initial memory to $INIT_MEMORY and max to $MAX_MEMORY"

# Workaround - the version of log4j used by Minecraft blows up on code page 65001, and you can't change it on Nano Server
$ENCODING_HACK = "-Dsun.stdout.encoding=UTF-8"
$expandedDOpts = "$ENCODING_HACK"
if ($env:JVM_DD_OPTS) {
  $env:JVM_DD_OPTS -split '\s' | ForEach-Object {
    $dopt = $_ -replace ':', '='
    $expandedDOpts = "$expandedDOpts -D$dopt"
  }
}

$mcServerRunnerArgs = "--stop-duration 60s"

if ($env:TYPE -eq "FEED-THE-BEAST") {
  # if [ ! -e "${FTB_DIR}/ops.json" -a -e /data/ops.txt ]; then
  #   cp -f /data/ops.txt ${FTB_DIR}/
  # fi

  # if [ ! -e "${FTB_DIR}/whitelist.json" -a -e /data/white-list.txt ]; then
  #   cp -f /data/white-list.txt ${FTB_DIR}/
  # fi

  # cp -f /data/eula.txt "${FTB_DIR}/"

  # cat > "${FTB_DIR}/settings-local.sh" <<EOF
  # export MIN_RAM="${INIT_MEMORY}"
  # export MAX_RAM="${MAX_MEMORY}"
  # export JAVA_PARAMETERS="${JVM_XX_OPTS} -Xms${INIT_MEMORY} ${JVM_OPTS} $expandedDOpts"
  # EOF

  # # patch CurseForge cfg file, if present
  # if [ -f "${FTB_DIR}/settings.cfg" ]; then
  #   sed -i "s/MAX_RAM=[^;]*/MAX_RAM=${MAX_MEMORY}/" "${FTB_DIR}/settings.cfg"
  # fi

  # cd "${FTB_DIR}"
  # log "Running FTB ${FTB_SERVER_START} in ${FTB_DIR} ..."
  # if isTrue ${DEBUG_EXEC}; then
  #   set -x
  # fi
  # exec mc-server-runner ${mcServerRunnerArgs} "${FTB_SERVER_START}"
} else {
  # If we have a bootstrap.txt file... feed that in to the server stdin
  if (Test-Path -Path '/data/bootstrap.txt') {
    $bootstrapArgs = "--bootstrap /data/bootstrap.txt"
  }

  Write-Host "Starting the Minecraft server ..."
  $JVM_OPTS="-Xms$INIT_MEMORY -Xmx$MAX_MEMORY ${JVM_OPTS} -d64"
  $JAVA_ARGS = @($env:JVM_XX_OPTS, $JVM_OPTS, $expandedDOpts, "-jar", $env:SERVER, "$@", $EXTRA_ARGS) | ? {$_}
  $mcServerRunnerArgs = @($bootstrapArgs, $mcServerRunnerArgs, 'java', $JAVA_ARGS) | ? {$_}
  Start-Process -FilePath mc-server-runner -ArgumentList $mcServerRunnerArgs -NoNewWindow -PassThru -Wait | Out-Null
}
