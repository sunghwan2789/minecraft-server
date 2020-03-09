# escape=`

ARG HOST_TAG=1809

ARG BUNDLE_IMAGE_NAME=bundle
ARG BUNDLE_TAG=ltsc2019
FROM ${BUNDLE_IMAGE_NAME}:pwsh-${BUNDLE_TAG} AS pwsh
FROM ${BUNDLE_IMAGE_NAME}:java-${BUNDLE_TAG} AS java
FROM ${BUNDLE_IMAGE_NAME}:mc-monitor-${BUNDLE_TAG} AS mc-monitor
FROM ${BUNDLE_IMAGE_NAME}:rcon-cli-${BUNDLE_TAG} AS rcon-cli
FROM ${BUNDLE_IMAGE_NAME}:mc-server-runner-${BUNDLE_TAG} AS mc-server-runner

FROM mcr.microsoft.com/windows/nanoserver:${HOST_TAG}

USER ContainerAdministrator
ENV JAVA_HOME C:\java
RUN echo Updating PATH: %JAVA_HOME%\bin;C:\pwsh;C:\bundle;%PATH% `
    && setx /M PATH "%JAVA_HOME%\bin;C:\pwsh;C:\bundle;%PATH%"
USER ContainerUser

ARG JAVA_BUNDLE_DIRECTORY=C:\java
COPY --from=pwsh C:\bundle C:\pwsh
COPY --from=java $JAVA_BUNDLE_DIRECTORY $JAVA_HOME
COPY --from=mc-monitor C:\bundle C:\bundle
COPY --from=rcon-cli C:\bundle C:\bundle
COPY --from=mc-server-runner C:\bundle C:\bundle

SHELL [ "pwsh", "-c", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';" ]

# Note: 'localhost' can bizarrely resolve to external addresses on some networks
HEALTHCHECK --start-period=1m CMD mc-monitor status --host 127.0.0.1 --port $env:SERVER_PORT

# TODO: Create minecraft user

EXPOSE 25565 25575

VOLUME ["C:\\data","C:\\mods","C:\\config"]
COPY minecraft C:\minecraft
WORKDIR C:\data

CMD [ "pwsh", "-File", "C:\\minecraft\\start.ps1" ]

ENV JVM_XX_OPTS="-XX:+UseG1GC" `
  MEMORY="1G" `
  TYPE=VANILLA `
  VERSION=LATEST `
#   FORGEVERSION=RECOMMENDED `
#   SPONGEBRANCH=STABLE `
#   SPONGEVERSION= `
#   FABRICVERSION=LATEST `
  LEVEL=world `
  PVP=true `
  DIFFICULTY=easy `
  ENABLE_RCON=true `
  RCON_PORT=25575 `
  RCON_PASSWORD=minecraft `
#   RESOURCE_PACK= `
#   RESOURCE_PACK_SHA1= `
  LEVEL_TYPE=DEFAULT `
  GENERATOR_SETTINGS= `
  WORLD= `
#   MODPACK= `
#   MODS= `
  SERVER_PORT=25565 `
  ONLINE_MODE=TRUE `
  CONSOLE=true `
  SERVER_NAME="Dedicated Server" `
  REPLACE_ENV_VARIABLES="FALSE" `
  ENV_VARIABLE_PREFIX="CFG_"
