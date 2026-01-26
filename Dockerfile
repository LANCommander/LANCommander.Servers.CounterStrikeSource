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
ENV HTTP_FILESERVER_ENABLED="true"
ENV HTTP_FILESERVER_WEB_ROOT="/config/Merged/cstrike"
ENV HTTP_FILESERVER_FILE_PATTERN="^/(maps|materials|models|sound)/.*\.(bz2|ztmp|bsp|nav|res|mdl|vvd|vtx|phy|ani|vmt|vtf|wav|mp3)$"

EXPOSE 27015/udp
EXPOSE 27020/udp
EXPOSE 80/tcp

# COPY Modules/ "${BASE_MODULES}/"
COPY Hooks/ "${BASE_HOOKS}/"

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]