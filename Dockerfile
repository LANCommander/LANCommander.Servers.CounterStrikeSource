# syntax=docker/dockerfile:1.7

# Override to build against a locally built base, e.g. lancommander/steamcmd:local
ARG BASE_IMAGE=lancommander/steamcmd:latest
FROM ${BASE_IMAGE}

# SteamCMD settings
ENV STEAM_APP_ID="232330"
ENV START_EXE="srcds_run"
ENV START_ARGS="-game cstrike -console +map de_dust2"
ENV INSTALL_SOURCEMOD="true"
ENV SOURCEMOD_MAJOR_VERSION="1.12"
ENV SOURCEMOD_VERSION="1.12.0-git7221"
ENV GAME_MOD="cstrike"
ENV METAMOD_MAJOR_VERSION="1.12"
ENV METAMOD_VERSION="1.12.0-git1219"
ENV HTTP_FILESERVER_ENABLED="true"
ENV HTTP_FILESERVER_WEB_ROOT="/config/Merged/cstrike"
ENV HTTP_FILESERVER_FILE_PATTERN="^/(maps|materials|models|sound)/.*\.(bz2|ztmp|bsp|nav|res|mdl|vvd|vtx|phy|ani|vmt|vtf|wav|mp3)$"

# ----------------------------
# Dependencies
# ----------------------------
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bzip2 \
    tar \
    unzip \
    xz-utils \
    p7zip-full \
    gosu \
  && rm -rf /var/lib/apt/lists/*

EXPOSE 27015/udp
EXPOSE 27020/udp
EXPOSE 80/tcp

# ----------------------------
# LANCommander match statistics (https://github.com/LANCommander/LANCommander.MatchStatistics.SourceMod)
#   - MATCH_STATS_ENABLED: auto (on when MATCH_STATS_SERVER_URL and MATCH_STATS_TOKEN are set),
#     true or false. When on, the SourceMod plugin is copied into <GAME_MOD>/addons/sourcemod
#   - The MATCH_STATS_* settings become lc_* cvars in <GAME_MOD>/cfg/sourcemod/lancommander.cfg.
#     Empty settings are left out, so they can be set in cfg/sourcemod/sourcemod.cfg instead
# ----------------------------
ENV MATCH_STATS_ENABLED="auto" \
    MATCH_STATS_SERVER_URL="" \
    MATCH_STATS_TOKEN="" \
    MATCH_STATS_GAME_ID="" \
    MATCH_STATS_SERVER_ID="" \
    MATCH_STATS_REPORTER_NAME="" \
    MATCH_STATS_MIN_PLAYERS="" \
    MATCH_STATS_MODE="" \
    MATCH_STATS_RECORD_BOTS="" \
    MATCH_STATS_RECORD_CHAT="" \
    MATCH_STATS_ATTACH_DEMOS=""

ARG MATCH_STATS_VERSION=1.0.0
ARG MATCH_STATS_SHA256=7cabe64ea1b927702667a9ec60dc87943e524d7a242b31396aebfe637933d177

ADD --checksum=sha256:${MATCH_STATS_SHA256} \
    https://github.com/LANCommander/LANCommander.MatchStatistics.SourceMod/releases/download/v${MATCH_STATS_VERSION}/LANCommander.SourceMod.MatchStatistics-v${MATCH_STATS_VERSION}.zip \
    /tmp/match-stats.zip

RUN unzip -q /tmp/match-stats.zip 'addons/*' -x 'addons/sourcemod/scripting/*' -d /opt/lancommander-stats && \
    rm /tmp/match-stats.zip

# COPY Modules/ "${BASE_MODULES}/"
COPY Hooks/ "${BASE_HOOKS}/"

USER lancommander

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]