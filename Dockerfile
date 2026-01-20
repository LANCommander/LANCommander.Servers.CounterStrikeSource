# syntax=docker/dockerfile:1.7

FROM lancommander/steamcmd:latest

# SteamCMD settings
ENV STEAM_APP_ID="232330"
ENV STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2"
ENV INSTALL_SOURCEMOD="true"
ENV INSTALL_SOURCEMOD_DEFAULT_PLUGINS="true"
ENV SOURCEMOD_MAJOR_VERSION="1.12"
ENV SOURCEMOD_VERSION="1.12.0-git7221"
ENV GAME_MOD="cstrike"
ENV METAMOD_MAJOR_VERSION="1.12"
ENV METAMOD_VERSION="1.12.0-git1219"

# Copy hook script to the location expected by base image
COPY hooks/pre-server/20-install-sourcemod-css.sh /config/hooks/pre-server/20-install-sourcemod-css.sh
RUN chmod +x /config/hooks/pre-server/20-install-sourcemod-css.sh

EXPOSE 27015/udp
EXPOSE 27020/udp

WORKDIR /config