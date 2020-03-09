$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

function setServerProp($prop, $val) {
  if ($val) {
    switch -regex ($val) {
      # normalize booleans
      "^(TRUE|FALSE)$" {
        $val = $val.ToLowerInvariant();
      }
    }
    Write-Host "Setting $prop to '$val' in $env:SERVER_PROPERTIES"
    (Get-Content -Path $env:SERVER_PROPERTIES -Raw) -replace "(?m)^$prop\s*=.*", "$prop=$val" `
      | Out-File -FilePath $env:SERVER_PROPERTIES
  } else {
    Write-Host "Skip setting $prop"
  }
}

function customizeServerProps {
  if ($env:WHITELIST) {
    Write-Host "Creating whitelist"
    setServerProp "whitelist" "true"
    setServerProp "white-list" "true"
  }

  # If not provided, generate a reasonable default message-of-the-day,
  # which shows up in the server listing in the client
  if (!$env:MOTD) {
    # snapshot is the odd case where we have to look at version to identify that label
    $label = if (($env:ORIGINAL_TYPE -eq "VANILLA") -and ($env:VERSION -eq "SNAPSHOT")) {
      "SNAPSHOT"
    } else {
      $env:ORIGINAL_TYPE
    }

    # Convert label to title-case
    $label = (Get-Culture).TextInfo.ToTitleCase($label.ToLowerInvariant())
    $env:MOTD = "A $label Minecraft Server powered by Docker"
  }

  setServerProp "server-name" $env:SERVER_NAME
  setServerProp "server-port" $env:SERVER_PORT
  setServerProp "motd" $env:MOTD
  setServerProp "allow-nether" $env:ALLOW_NETHER
  setServerProp "announce-player-achievements" $env:ANNOUNCE_PLAYER_ACHIEVEMENTS
  setServerProp "enable-command-block" $env:ENABLE_COMMAND_BLOCK
  setServerProp "spawn-animals" $env:SPAWN_ANIMALS
  setServerProp "spawn-monsters" $env:SPAWN_MONSTERS
  setServerProp "spawn-npcs" $env:SPAWN_NPCS
  setServerProp "spawn-protection" $env:SPAWN_PROTECTION
  setServerProp "generate-structures" $env:GENERATE_STRUCTURES
  setServerProp "view-distance" $env:VIEW_DISTANCE
  setServerProp "hardcore" $env:HARDCORE
  setServerProp "snooper-enabled" $env:SNOOPER_ENABLED
  setServerProp "max-build-height" $env:MAX_BUILD_HEIGHT
  setServerProp "force-gamemode" $env:FORCE_GAMEMODE
  setServerProp "max-tick-time" $env:MAX_TICK_TIME
  setServerProp "enable-query" $env:ENABLE_QUERY
  setServerProp "query.port" $env:QUERY_PORT
  setServerProp "enable-rcon" $env:ENABLE_RCON
  setServerProp "rcon.password" $env:RCON_PASSWORD
  setServerProp "rcon.port" $env:RCON_PORT
  setServerProp "max-players" $env:MAX_PLAYERS
  setServerProp "max-world-size" $env:MAX_WORLD_SIZE
  setServerProp "level-name" $env:LEVEL
  setServerProp "level-seed" $env:SEED
  setServerProp "pvp" $env:PVP
  setServerProp "generator-settings" $env:GENERATOR_SETTINGS
  setServerProp "online-mode" $env:ONLINE_MODE
  setServerProp "allow-flight" $env:ALLOW_FLIGHT
  setServerProp "level-type" $env:LEVEL_TYPE.ToUpperInvariant()
  setServerProp "resource-pack" $env:RESOURCE_PACK
  setServerProp "resource-pack-sha1" $env:RESOURCE_PACK_SHA1

  if ($env:DIFFICULTY) {
    $env:DIFFICULTY = switch -regex ($env:DIFFICULTY) {
      "^(peaceful|0)$" {
        "0"
        break
      }
      "^(easy|1)$" {
        "1"
        break
      }
      "^(normal|2)$" {
        "2"
        break
      }
      "^(hard|3)$" {
        "3"
        break
      }
      default {
        Write-Host "DIFFICULTY must be peaceful, easy, normal, or hard."
        exit 1
      }
    }
    setServerProp "difficulty" $env:DIFFICULTY
  }

  if ($env:MODE) {
    Write-Host "Setting mode"
    $env:MODE = switch -regex ($env:MODE) {
      "^(su.*|0)$" {
        "0"
        break
      }
      "^(c.*|1)$" {
        "1"
        break
      }
      "^(a.*|2)$" {
        "2"
        break
      }
      "^(sp.*|3)$" {
        "3"
        break
      }
      default {
        Write-Error "Invalid game mode: $env:MODE"
        exit 1
      }
    }
    setServerProp "gamemode" $env:MODE
  }
}

# Deploy server.properties file
if ($env:TYPE -eq "FEED-THE-BEAST") {
  $env:SERVER_PROPERTIES = "$env:FTB_DIR/server.properties"
  Write-Host "detected FTB, changing properties path to $env:SERVER_PROPERTIES"
}

if (!(Test-Path $env:SERVER_PROPERTIES)) {
  Write-Host "Creating server.properties in $env:SERVER_PROPERTIES"
  Copy-Item -Path $PSScriptRoot\server.properties -Destination $env:SERVER_PROPERTIES
  customizeServerProps
} elseif ($env:OVERRIDE_SERVER_PROPERTIES) {
  switch -regex ($env:OVERRIDE_SERVER_PROPERTIES) {
    "^(TRUE|1)$" {
      customizeServerProps
      break
    }
    default {
      Write-Host "server.properties already created, skipping"
    }
  }
} else {
  Write-Host "server.properties already created, skipping"
}

& $PSScriptRoot\start-finalSetup05EnvVariables.ps1
