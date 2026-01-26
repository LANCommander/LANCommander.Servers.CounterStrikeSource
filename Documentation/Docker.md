# Counter-Strike: Source Docker Container

This Docker container provides a fully configured Counter-Strike: Source game server that automatically downloads and updates the game via SteamCMD, supports file overlaying using OverlayFS, and includes optional SourceMod/MetaMod support.

## Quick Start

```yaml
services:
  counterstrikesource-scenario:
    image: lancommander/counterstrikesource:latest
    container_name: counterstrikesource-scenario

    ports:
      - 27016:27015/udp
      - 27021:27020/udp
      - 27080:80 # For FastDL support

    volumes:
      - "/data/Servers/Counter-Strike - Source:/config"

    environment:
      STEAM_APP_UPDATE: "true"
      START_CMD: "./srcds_run -game cstrike -console +map de_dust2"
      INSTALL_SOURCEMOD: "true"

    cap_add:
      - SYS_ADMIN

    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

## Configuration Options

### Ports

The container exposes the following ports:

- **27015/udp** - Main game server port (default). Clients connect to this port to join the server.
- **27020/udp** - SourceTV port (optional). Used for game broadcasting and recording.
- **80/tcp** - HTTP file server port (optional). Used for serving game files to clients (See [FastDL](https://developer.valvesoftware.com/wiki/FastDL)).

**Port Mapping:**
In the example configuration, ports are mapped as:
- `27016:27015/udp` - Maps host port 27016 to container port 27015
- `27021:27020/udp` - Maps host port 27021 to container port 27020
- `27080:80` - Maps host port 27021 to container port 27020

You can customize these mappings based on your network requirements. If you're running multiple servers, use different host ports for each instance.

### Volumes

The container requires a volume mount for the `/config` directory, which stores:

- **Server/** - Game files downloaded by SteamCMD (auto-created)
- **Overlay/** - Custom files that overlay on top of the game directory
- **Merged/** - OverlayFS merged view (auto-created)
- **Scripts/** - Custom PowerShell scripts for hooks

**Example:**
```yaml
volumes:
  - "/data/Servers/Counter-Strike - Source:/config"
```

The host path can be:
- An absolute path (Windows: `C:\data\...`, Linux: `/data/...`)
- A relative path (e.g., `./config:/config`)
- A named volume (e.g., `css-server-data:/config`)

**Important:** The mounted directory must be writable by the container.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `STEAM_APP_UPDATE` | Enable automatic game updates on startup (`"true"`/`"false"`) | `"true"` | No |
| `START_CMD` | Command to start the game server | `"./srcds_run -game cstrike -console +map de_dust2"` | No |
| `INSTALL_SOURCEMOD` | Enable SourceMod/MetaMod installation (`"true"`/`"false"`) | `"false"` | No |
| `SOURCEMOD_VERSION` | SourceMod version to install | `"1.12.0-git7221"` | No |
| `METAMOD_VERSION` | MetaMod version to install | `"1.12.0-git1219"` | No |
| `GAME_MOD` | Game modification directory | `"cstrike"` | No |

#### `STEAM_APP_UPDATE`

Controls whether SteamCMD updates the game server on container startup.

- `"true"` - Automatically download/update the game server
- `"false"` - Skip updates (useful for offline operation or faster startup)

**Example:**
```yaml
environment:
  STEAM_APP_UPDATE: "true"
```

#### `START_CMD`

The command executed to start the Counter-Strike: Source server. This should be the full command line including all server parameters.

**Default:**
```yaml
START_CMD: "./srcds_run -game cstrike -console +map de_dust2"
```

**Customization Examples:**

Basic server with custom map:
```yaml
START_CMD: "./srcds_run -game cstrike -console +map de_dust2"
```

Server with max players and public IP:
```yaml
START_CMD: "./srcds_run -game cstrike -console +map de_dust2 +maxplayers 24 +sv_lan 0 +ip 0.0.0.0"
```

Server with RCON password:
```yaml
START_CMD: "./srcds_run -game cstrike -console +map de_dust2 +rcon_password mypassword"
```

**Common Server Parameters:**
- `+map <mapname>` - Set the starting map (e.g., `de_dust2`, `cs_office`)
- `+maxplayers <number>` - Maximum number of players (default: 32)
- `+sv_lan 0` - Enable internet play (0 = internet, 1 = LAN only)
- `+ip <address>` - Server IP address (use `0.0.0.0` for all interfaces)
- `+port <port>` - Server port (default: 27015)
- `+rcon_password <password>` - RCON password for remote administration
- `+hostname "<name>"` - Server name displayed in server browser

#### `INSTALL_SOURCEMOD`

Enables automatic installation of SourceMod and MetaMod:Source, which provide plugin support and enhanced server administration.

- `"true"` - Install SourceMod and MetaMod
- `"false"` - Skip SourceMod installation

When enabled, the container will:
1. Download and install MetaMod:Source (required dependency)
2. Download and install SourceMod
3. Place all files in `/config/Overlay/cstrike/addons/`

**Example:**
```yaml
environment:
  INSTALL_SOURCEMOD: "true"
```

### Security Options

The container requires elevated privileges to use OverlayFS for file overlaying.

#### `cap_add: SYS_ADMIN`

Adds the `SYS_ADMIN` capability, which is required for mounting OverlayFS. This is the recommended approach as it provides minimal necessary privileges.

```yaml
cap_add:
  - SYS_ADMIN
```

#### `security_opt: apparmor:unconfined`

On Ubuntu hosts with AppArmor enabled, you may need to disable AppArmor restrictions for the container. This is often necessary for OverlayFS to function properly.

```yaml
security_opt:
  - apparmor:unconfined
```

**Alternative Options:**

If you prefer less security but simpler configuration, you can use privileged mode:

```yaml
privileged: true
```

**Note:** Privileged mode grants the container extensive access to the host system and is less secure than using `cap_add: SYS_ADMIN`.

### Restart Policy

```yaml
restart: unless-stopped
```

This ensures the container automatically restarts if it stops unexpectedly, but won't restart if you manually stop it.

**Other options:**
- `no` - Never restart
- `always` - Always restart, even after manual stop
- `on-failure` - Restart only on failure

## Directory Structure

The `/config` directory contains the following structure:

```
/config/
├── Server/              # Game files from SteamCMD (auto-created)
│   └── cstrike/         # Counter-Strike: Source game directory
├── Overlay/             # Custom files overlay (your modifications)
│   └── cstrike/
│       ├── addons/      # SourceMod/MetaMod installation location
│       │   ├── sourcemod/
│       │   │   ├── plugins/     # Place .smx plugin files here
│       │   │   ├── configs/     # SourceMod configuration files
│       │   │   └── ...
│       │   └── metamod/
│       ├── maps/        # Custom maps
│       ├── cfg/         # Server configuration files (server.cfg, etc.)
│       └── ...
├── Merged/              # OverlayFS merged view (auto-created)
├── .overlay-work/       # OverlayFS work directory (auto-created)
└── Scripts/
    └── Hooks/           # Custom PowerShell scripts for hooks
```

## SourceMod Configuration

### Installing Plugins

Once SourceMod is installed, add plugins by placing compiled `.smx` files in:

```
/config/Overlay/cstrike/addons/sourcemod/plugins/
```

**Example:**
```bash
# Copy plugin to the overlay directory
cp my_plugin.smx "/data/Servers/Counter-Strike - Source/Scenario/Overlay/cstrike/addons/sourcemod/plugins/"

# Restart the container to load the plugin
docker restart counterstrikesource-scenario
```

### SourceMod Configuration Files

Place SourceMod configuration files in:

```
/config/Overlay/cstrike/addons/sourcemod/configs/
```

**Common configuration files:**
- `admins_simple.ini` - Admin user configuration
- `core.cfg` - Core SourceMod settings
- `database.cfg` - Database configuration (if using database features)

### Server Configuration

Place server configuration files in:

```
/config/Overlay/cstrike/cfg/
```

**Example `server.cfg`:**
```
hostname "My Counter-Strike: Source Server"
sv_lan 0
maxplayers 24
rcon_password "your_rcon_password"
```

## OverlayFS

The container uses Linux OverlayFS to merge the base game files with your custom files:

- **Lower layer**: `/config/Server` (base game files from SteamCMD)
- **Upper layer**: `/config/Overlay` (your custom files)
- **Merged view**: `/config/Merged` (where the game server runs from)

**Benefits:**
- Replace files without modifying the base installation
- Add custom content (maps, plugins, configs)
- No file copying required - OverlayFS is a union filesystem
- Easy updates - base game files can be updated without losing customizations

If OverlayFS cannot be mounted (e.g., missing privileges), the container will fall back to using `/config/Server` directly and log a warning.

## Troubleshooting

### Container Won't Start

1. **Check logs:**
   ```bash
   docker logs counterstrikesource-scenario
   ```

2. **Verify permissions:**
   Ensure the mounted volume is writable:
   ```bash
   # Linux
   chmod -R 755 "/data/Servers/Counter-Strike - Source/Scenario"
   
   # Windows
   # Ensure the directory has proper permissions in Windows
   ```

3. **Check security options:**
   Ensure `cap_add: SYS_ADMIN` is set, or use `privileged: true`

### Game Server Not Starting

1. **Verify START_CMD:**
   Check that `START_CMD` contains a valid server command:
   ```yaml
   START_CMD: "./srcds_run -game cstrike -console +map de_dust2"
   ```

2. **Check server directory:**
   Verify that game files were downloaded:
   ```bash
   docker exec counterstrikesource-scenario ls -la /config/Server/cstrike
   ```

3. **Review server logs:**
   Check container logs for server startup messages and errors

### SourceMod Not Loading

1. **Verify installation:**
   Ensure `INSTALL_SOURCEMOD: "true"` is set (with quotes in YAML)

2. **Check installation directory:**
   ```bash
   docker exec counterstrikesource-scenario ls -la /config/Overlay/cstrike/addons/sourcemod
   ```

3. **Verify MetaMod:**
   Check that MetaMod is installed:
   ```bash
   docker exec counterstrikesource-scenario ls -la /config/Overlay/cstrike/addons/metamod.vdf
   ```

4. **Check server console:**
   Look for SourceMod loading messages in the container logs

### OverlayFS Warnings

If you see warnings about OverlayFS:

1. **Verify capabilities:**
   Ensure `cap_add: SYS_ADMIN` is present in your docker-compose.yml

2. **Check AppArmor:**
   On Ubuntu, add `security_opt: apparmor:unconfined`

3. **Alternative:**
   Use `privileged: true` (less secure but simpler)

### Port Already in Use

If you get port binding errors:

1. **Check for existing containers:**
   ```bash
   docker ps -a
   ```

2. **Use different ports:**
   Change the port mapping in docker-compose.yml:
   ```yaml
   ports:
     - 27017:27015/udp  # Use a different host port
   ```

3. **Stop conflicting containers:**
   ```bash
   docker stop <container-name>
   ```

### Permission Errors

The container runs as a non-root user. If you encounter permission errors:

1. **Check file ownership:**
   ```bash
   docker exec counterstrikesource-scenario ls -la /config
   ```

2. **Verify volume mount:**
   Ensure the host directory is accessible and writable

3. **Review logs:**
   Check container logs for specific permission error messages

## Advanced Usage

### Custom Hooks

You can create custom PowerShell scripts that execute at various points in the container's lifecycle. Place scripts in:

```
/config/Scripts/Hooks/{HookName}/
```

**Available hooks:**
- `PreSteamInstall` - Before SteamCMD runs
- `PostSteamInstall` - After SteamCMD completes
- `PreInstallSourceMod` - Before SourceMod installation
- `PostInstallSourceMod` - After SourceMod installation

**Example hook script** (`/config/Scripts/Hooks/PostSteamInstall/10-CustomSetup.ps1`):
```powershell
Write-Host "Running custom setup..."
# Your custom commands here
```

### HTTP File Server

The container includes an optional HTTP file server (port 80) for serving game files to clients. This is useful for fast downloads of custom maps and content.

The file server is configured via environment variables:
- `HTTP_FILESERVER_ENABLED` - Enable/disable the file server
- `HTTP_FILESERVER_WEB_ROOT` - Root directory for file serving
- `HTTP_FILESERVER_FILE_PATTERN` - Pattern for files to serve

### Multiple Server Instances

To run multiple Counter-Strike: Source servers on the same host:

1. **Use different container names:**
   ```yaml
   container_name: counterstrikesource-server1
   ```

2. **Use different ports:**
   ```yaml
   ports:
     - 27016:27015/udp
     - 27021:27020/udp
   ```

3. **Use different volume mounts:**
   ```yaml
   volumes:
     - "/data/Servers/Counter-Strike - Source/Server1:/config"
   ```

4. **Use different maps/names:**
   ```yaml
   environment:
     START_CMD: "./srcds_run -game cstrike -console +map cs_office +hostname 'Server 1'"
   ```

## Additional Resources

- [Counter-Strike: Source Server Documentation](https://developer.valvesoftware.com/wiki/Counter-Strike:_Source_Dedicated_Server)
- [SourceMod Documentation](https://wiki.alliedmods.net/Category:SourceMod_Documentation)
- [MetaMod:Source Documentation](https://wiki.alliedmods.net/Metamod:Source)
