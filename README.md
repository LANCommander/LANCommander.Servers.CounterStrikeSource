# Counter-Strike: Source Server (Docker)

This repository provides a Dockerized **Counter-Strike: Source** game server suitable for running a CS:S server in a clean, reproducible way.  
The image is designed for **headless operation**, automatically downloads and updates the game server via SteamCMD, supports file overlaying using overlayfs, and includes optional SourceMod/MetaMod support.

---

## Features

- Counter-Strike: Source game server support
- Automatically downloads and updates the game server via SteamCMD
- Optional SourceMod/MetaMod installation and management
- Supports file overlaying using overlayfs (no file copying required)
- Pre-execution script support (`/config/autoexec.sh`)
- Non-root runtime using `gosu`
- Configurable automatic updates

## Docker Compose Example

```yaml
services:
  css-server:
    image: lancommander/counterstrikesource:latest
    container_name: my-css-server

    # Expose game server ports
    ports:
      - "27015:27015/udp"  # Game server port
      - "27020:27020/udp"  # SourceTV port (optional)

    # Bind mounts
    volumes:
      - ./config:/config      # Game server configuration and overlay directory

    environment:
      STEAM_APP_UPDATE: "true"               # Enable automatic updates
      STEAMCMD_ARGS: "./srcds_run -game cstrike -console +map de_dust2"
      INSTALL_SOURCEMOD: "true"              # Enable SourceMod installation
      INSTALL_SOURCEMOD_DEFAULT_PLUGINS: "false"  # Optional: install default plugins

    # For overlayfs support, add one of these:
    # Option 1: Full privileges (less secure)
    privileged: true
    # Option 2: Minimal privileges (recommended)
    # cap_add:
    #   - SYS_ADMIN

    restart: unless-stopped
```

---

## Directory Layout (Host)

```text
.
└── config/
    ├── game/              # Game files downloaded by SteamCMD (auto-created)
    │   └── cstrike/       # Counter-Strike: Source game directory
    ├── overlay/           # Files to overlay on game directory (optional)
    │   └── cstrike/       # Counter-Strike: Source overlay directory
    │       ├── addons/    # SourceMod/MetaMod installation location
    │       │   ├── sourcemod/
    │       │   │   ├── plugins/     # Place your .smx plugin files here
    │       │   │   ├── configs/     # SourceMod configuration files
    │       │   │   └── ...
    │       │   └── metamod/
    │       ├── maps/      # Custom maps
    │       ├── cfg/       # Server configuration files (server.cfg, etc.)
    │       └── ...        # Any other files you want to overlay
    ├── merged/            # Overlayfs merged view (auto-created, if overlayfs enabled)
    ├── .overlay-work/     # Overlayfs work directory (auto-created)
    ├── autoexec.sh        # Optional: Script executed before SteamCMD update
    └── ...                # Your game server configuration files
```

The `config` directory **must be writable** by Docker. The `game` directory is automatically created and populated by SteamCMD on first startup.

---

## Configuration

### Pre-Execution Script

You can create a script at `/config/autoexec.sh` that will be executed **before** SteamCMD runs. This is useful for:
- Installing additional dependencies
- Setting up environment variables
- Downloading additional files
- Modifying configuration before the game server starts

Example `config/autoexec.sh`:
```bash
#!/usr/bin/env bash
echo "Running pre-execution setup..."
# Download custom files, set environment variables, etc.
export MY_CUSTOM_VAR="value"
```

The script will be made executable automatically if it's not already.

### File Overlaying

The overlay directory (`/config/overlay`) allows you to overlay files on top of the game directory without copying files. This is useful for:
- Replacing game files (maps, scripts, assets)
- Adding custom content
- Modifying game files without touching the base installation

**How it works:**
- Files in `/config/overlay` will appear in the merged view at `/config/merged`
- If a file exists in both `/config/game` and `/config/overlay`, the version in `/config/overlay` takes precedence
- The game server runs from the merged directory when overlayfs is active

**Requirements:**
- Container must run with `--cap-add SYS_ADMIN` or `--privileged` flag
- If overlayfs cannot be mounted, the container falls back to using the game directory directly

**Example overlay structure:**
```text
config/overlay/
├── maps/
│   └── custom_map.bsp
├── scripts/
│   └── server.cfg
└── addons/
    └── custom_addon.vdf
```

---

## SourceMod Installation

This image includes support for automatically installing SourceMod and MetaMod:Source. SourceMod is a powerful administration plugin framework for Source engine games.

### Enabling SourceMod

To enable SourceMod installation, set the `INSTALL_SOURCEMOD` environment variable to `"true"`:

```yaml
environment:
  INSTALL_SOURCEMOD: "true"
```

When enabled, the container will automatically:
- Install MetaMod:Source (required dependency for SourceMod)
- Install SourceMod
- Place all files in the overlay directory (`/config/overlay/cstrike/addons/`)

### Installing Plugins

Once SourceMod is installed, you can add custom plugins by placing `.smx` files in:

```
config/overlay/cstrike/addons/sourcemod/plugins/
```

**Example:**
```bash
# Place your plugin file
cp my_plugin.smx ./config/overlay/cstrike/addons/sourcemod/plugins/

# Restart the container to load the plugin
docker restart my-css-server
```

Plugins are automatically loaded when the server starts. You can manage plugins via the SourceMod admin console or by adding/removing `.smx` files from the plugins directory.

### Default Plugins

You can optionally install a set of default plugins by setting:

```yaml
environment:
  INSTALL_SOURCEMOD: "true"
  INSTALL_SOURCEMOD_DEFAULT_PLUGINS: "true"
```

This will install a curated set of common SourceMod plugins. Note that SourceMod already includes a baseline set of plugins, so this is optional.

### SourceMod Configuration

SourceMod configuration files should be placed in:

```
config/overlay/cstrike/addons/sourcemod/configs/
```

Common configuration files:
- `admins_simple.ini` - Admin user configuration
- `core.cfg` - Core SourceMod settings
- `database.cfg` - Database configuration (if using database features)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `STEAM_APP_UPDATE` | Enable automatic game updates on startup (`true`/`false`) | `true` |
| `STEAMCMD_ARGS` | Command to run the game server | `"./srcds_run -game cstrike -console +map de_dust2"` |
| `INSTALL_SOURCEMOD` | Enable SourceMod/MetaMod installation (`true`/`false`) | `false` |
| `INSTALL_SOURCEMOD_DEFAULT_PLUGINS` | Install default plugin pack (`true`/`false`) | `false` |
| `SOURCEMOD_VERSION` | SourceMod version to install | `1.12.0-git7221` |
| `METAMOD_VERSION` | MetaMod version to install | `1.12.0-git1219` |

### `STEAM_APP_UPDATE`

Set to `false` or `0` to disable automatic updates. When disabled, SteamCMD will not run on container startup.

### `STEAMCMD_ARGS`

The command to start the Counter-Strike: Source server. Default example:

```bash
STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2"
```

You can customize this with additional server parameters:

```bash
STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2 +maxplayers 24 +sv_lan 0"
```

---

## Running the Server

### Basic run (with automatic updates)

```bash
mkdir -p config

docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "./config:/config" \
  -e STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2" \
  lancommander/counterstrikesource:latest
```

### With SourceMod enabled

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="true" \
  -e STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2 +maxplayers 24" \
  -e INSTALL_SOURCEMOD="true" \
  lancommander/counterstrikesource:latest
```

### With custom configuration and overlay

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="true" \
  -e STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2 +maxplayers 24" \
  -e INSTALL_SOURCEMOD="true" \
  lancommander/counterstrikesource:latest
```

### Disable automatic updates

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="false" \
  -e STEAMCMD_ARGS="./srcds_run -game cstrike -console +map de_dust2" \
  lancommander/counterstrikesource:latest
```

### Using command arguments instead of STEAMCMD_ARGS

You can also pass the server command as arguments to the container:

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  lancommander/counterstrikesource:latest \
  ./srcds_run -game cstrike -console +map de_dust2
```

---

## Overlayfs Details

The container uses Linux overlayfs to merge the game directory (`/config/game`) with the overlay directory (`/config/overlay`) into a merged view (`/config/merged`). This allows you to:

1. **Replace files** without modifying the base game installation
2. **Add files** that don't exist in the base game
3. **Avoid copying** large files - overlayfs is a union filesystem

**Technical details:**
- **Lower layer**: `/config/game` (base game files from SteamCMD)
- **Upper layer**: `/config/overlay` (your custom files)
- **Merged view**: `/config/merged` (where the game server runs from)
- **Work directory**: `/config/.overlay-work` (required by overlayfs)

If overlayfs cannot be mounted (e.g., missing privileges), the container will fall back to using `/config/game` directly and log a warning.

---

## Troubleshooting

### Overlayfs not working

If you see warnings about overlayfs, ensure your container has the required privileges:

```bash
# Option 1: Add SYS_ADMIN capability (recommended)
docker run --cap-add SYS_ADMIN ...

# Option 2: Use privileged mode (less secure)
docker run --privileged ...
```

### Game server not starting

1. Verify `STEAMCMD_ARGS` contains the correct command for Counter-Strike: Source
2. Check container logs: `docker logs <container-name>`
3. Ensure the game directory was downloaded: check `/config/game/cstrike` in the container
4. Verify the server configuration files are correct (e.g., `server.cfg`)

### SourceMod not loading

1. Ensure `INSTALL_SOURCEMOD` is set to `"true"` (not just `true` without quotes in YAML)
2. Check that SourceMod was installed: verify `/config/overlay/cstrike/addons/sourcemod` exists
3. Check server console logs for SourceMod loading messages
4. Verify MetaMod is installed: check for `/config/overlay/cstrike/addons/metamod.vdf`
5. Ensure plugins are compiled `.smx` files (not `.sp` source files)

### Permission errors

The container runs as a non-root user (`steamcmd`, UID 10001). If you encounter permission errors:

1. Ensure mounted volumes are writable
2. Check file ownership in the container
3. Review logs for specific permission error messages

---

## License

SteamCMD and game servers are distributed under their respective licenses.
This repository contains only Docker build logic and helper scripts licensed under MIT.
