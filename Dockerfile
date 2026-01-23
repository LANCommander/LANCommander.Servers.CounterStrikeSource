# syntax=docker/dockerfile:1.7

FROM lancommander/steamcmd:latest

# SteamCMD settings
ENV STEAM_APP_ID="232330"
ENV START_CMD="./srcds_run -game cstrike -console +map de_dust2"
ENV INSTALL_SOURCEMOD="true"
ENV SOURCEMOD_MAJOR_VERSION="1.12"
ENV SOURCEMOD_VERSION="1.12.0-git7221"
ENV GAME_MOD="cstrike"
ENV METAMOD_MAJOR_VERSION="1.12"
ENV METAMOD_VERSION="1.12.0-git1219"

EXPOSE 27015/udp
EXPOSE 27020/udp

# COPY Modules/ "${BASE_MODULES}/"
COPY Hooks/ "${BASE_HOOKS}/"

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]