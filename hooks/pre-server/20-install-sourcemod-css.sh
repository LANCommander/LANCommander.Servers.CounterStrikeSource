#!/bin/sh
set -e

echo "[sourcemod] Hook starting"

# ---------------------------------------------------------------------
# Behavior toggles
# ---------------------------------------------------------------------
# Set to "true" to install SourceMod/MetaMod
INSTALL_SOURCEMOD="${INSTALL_SOURCEMOD:-false}"

# Set to "true" to install a small set of common default plugins (optional)
INSTALL_SOURCEMOD_DEFAULT_PLUGINS="${INSTALL_SOURCEMOD_DEFAULT_PLUGINS:-false}"

# ---------------------------------------------------------------------
# Pinned versions (override as needed)
# ---------------------------------------------------------------------
# Defaults pin to SourceMod/MetaMod 1.12 "stable drops" with specific build artifacts.
# If you prefer a different major (e.g., 1.11), override these in env.
SOURCEMOD_MAJOR_VERSION="${SOURCEMOD_MAJOR_VERSION:-1.12}"
SOURCEMOD_VERSION="${SOURCEMOD_VERSION:-1.12.0-git7221}"
METAMOD_MAJOR_VERSION="${METAMOD_MAJOR_VERSION:-1.12}"
METAMOD_VERSION="${METAMOD_VERSION:-1.12.0-git1219}"

# ---------------------------------------------------------------------
# Paths (assumes CS:S under $GAME_DIR/cstrike)
# Install to overlay directory so files are merged via overlayfs
# ---------------------------------------------------------------------
: "${OVERLAY_DIR:=/config/overlay}"
: "${GAME_MOD:=cstrike}"
OVERLAY_GAME_PATH="${OVERLAY_DIR}/${GAME_MOD}"
ADDONS_PATH="${OVERLAY_GAME_PATH}/addons"

# ---------------------------------------------------------------------
# URLs (derived from pinned versions)
# ---------------------------------------------------------------------
METAMOD_URL="${METAMOD_URL:-https://mms.alliedmods.net/mmsdrop/${METAMOD_MAJOR_VERSION}/mmsource-${METAMOD_VERSION}-linux.tar.gz}"
SOURCEMOD_URL="${SOURCEMOD_URL:-https://sm.alliedmods.net/smdrop/${SOURCEMOD_MAJOR_VERSION}/sourcemod-${SOURCEMOD_VERSION}-linux.tar.gz}"

# Default plugin pack (pinned)
# NOTE: This is intentionally a single, explicit artifact so behavior is deterministic.
# You can override SOURCEMOD_DEFAULT_PLUGINS_URL to point at your own curated pack.
SOURCEMOD_DEFAULT_PLUGINS_VERSION="${SOURCEMOD_DEFAULT_PLUGINS_VERSION:-1.0.0}"
SOURCEMOD_DEFAULT_PLUGINS_URL="${SOURCEMOD_DEFAULT_PLUGINS_URL:-https://github.com/alliedmodders/sourcemod/raw/master/plugins/sourcemod-plugins.zip}"

# ---------------------------------------------------------------------
# Guardrails
# ---------------------------------------------------------------------
if [ "$INSTALL_SOURCEMOD" != "true" ]; then
  echo "[sourcemod] INSTALL_SOURCEMOD is not true; skipping"
  exit 0
fi

if [ -z "${GAME_DIR:-}" ]; then
  echo "[sourcemod] GAME_DIR is not set; skipping"
  exit 0
fi

# Check if game directory exists (needed to verify game is installed)
GAME_PATH="${GAME_DIR}/${GAME_MOD}"
if [ ! -d "$GAME_PATH" ]; then
  echo "[sourcemod] Game path not found: $GAME_PATH; skipping"
  exit 0
fi

# Ensure overlay directory structure exists
mkdir -p "$OVERLAY_GAME_PATH"

# Ensure tools exist
command -v curl >/dev/null 2>&1 || { echo "[sourcemod] curl not found"; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "[sourcemod] tar not found"; exit 1; }

# ---------------------------------------------------------------------
# Install MetaMod (idempotent)
# Install to overlay directory so it's merged via overlayfs
# ---------------------------------------------------------------------
if [ ! -f "${ADDONS_PATH}/metamod.vdf" ]; then
  echo "[sourcemod] Installing MetaMod:Source (pinned: ${METAMOD_VERSION}) to overlay directory"
  curl -fsSL "$METAMOD_URL" | tar -xz -C "$OVERLAY_GAME_PATH"
else
  echo "[sourcemod] MetaMod already installed"
fi

# ---------------------------------------------------------------------
# Install SourceMod (idempotent)
# Install to overlay directory so it's merged via overlayfs
# ---------------------------------------------------------------------
if [ ! -d "${ADDONS_PATH}/sourcemod" ]; then
  echo "[sourcemod] Installing SourceMod (pinned: ${SOURCEMOD_VERSION}) to overlay directory"
  curl -fsSL "$SOURCEMOD_URL" | tar -xz -C "$OVERLAY_GAME_PATH"
else
  echo "[sourcemod] SourceMod already installed"
fi

# ---------------------------------------------------------------------
# Optional: install default plugins (only if enabled)
# ---------------------------------------------------------------------
# Strategy:
# - If you supply a curated plugin pack, set SOURCEMOD_DEFAULT_PLUGINS_URL to that artifact.
# - Otherwise, this section is a no-op unless explicitly enabled.
#
# NOTE: "Default plugins" is subjective; most SourceMod distributions already ship with a
# baseline set of plugins. This hook is designed to optionally layer additional plugins.
if [ "$INSTALL_SOURCEMOD_DEFAULT_PLUGINS" = "true" ]; then
  echo "[sourcemod] INSTALL_SOURCEMOD_DEFAULT_PLUGINS is true; installing default plugin pack (pinned: ${SOURCEMOD_DEFAULT_PLUGINS_VERSION})"

  # Prefer unzip if present; fall back to tar if the URL points at a tarball.
  TMP="/tmp/sourcemod-plugins.$$"
  mkdir -p "$TMP"

  # Download plugin pack
  curl -fsSL "$SOURCEMOD_DEFAULT_PLUGINS_URL" -o "$TMP/plugins.pack"

  # Detect archive type by extension (simple, deterministic)
  case "$SOURCEMOD_DEFAULT_PLUGINS_URL" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -oq "$TMP/plugins.pack" -d "$TMP/unpacked"
      else
        echo "[sourcemod] unzip not available; cannot install zip plugin pack"
        rm -rf "$TMP"
        exit 1
      fi
      ;;
    *.tar.gz|*.tgz)
      mkdir -p "$TMP/unpacked"
      tar -xzf "$TMP/plugins.pack" -C "$TMP/unpacked"
      ;;
    *)
      echo "[sourcemod] Unrecognized plugin pack type for URL: $SOURCEMOD_DEFAULT_PLUGINS_URL"
      echo "[sourcemod] Provide a .zip, .tar.gz, or .tgz pack."
      rm -rf "$TMP"
      exit 1
      ;;
  esac

  # Copy .smx files into addons/sourcemod/plugins (do not overwrite by default)
  PLUGINS_DIR="${ADDONS_PATH}/sourcemod/plugins"
  mkdir -p "$PLUGINS_DIR"

  # Copy only .smx files found in the pack
  FOUND="$(find "$TMP/unpacked" -type f -name '*.smx' 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$FOUND" = "0" ]; then
    echo "[sourcemod] No .smx files found in plugin pack; nothing to install"
  else
    echo "[sourcemod] Installing ${FOUND} plugin(s) into ${PLUGINS_DIR}"
    # Only copy new plugins; keep existing ones intact
    find "$TMP/unpacked" -type f -name '*.smx' -print0 2>/dev/null \
      | while IFS= read -r -d '' f; do
          base="$(basename "$f")"
          if [ -f "${PLUGINS_DIR}/${base}" ]; then
            echo "[sourcemod] Plugin already exists, skipping: ${base}"
          else
            cp "$f" "${PLUGINS_DIR}/${base}"
            echo "[sourcemod] Installed: ${base}"
          fi
        done
  fi

  rm -rf "$TMP"
else
  echo "[sourcemod] Default plugins not enabled; skipping"
fi

# ---------------------------------------------------------------------
# Permissions (best-effort; container may not be root depending on your entrypoint)
# ---------------------------------------------------------------------
if command -v chown >/dev/null 2>&1; then
  chown -R steamcmd:steamcmd "$ADDONS_PATH" 2>/dev/null || true
fi

echo "[sourcemod] Hook complete"