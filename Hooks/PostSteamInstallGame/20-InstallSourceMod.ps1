#Requires -Modules Logging
#Requires -Modules Hooks

Invoke-Hook "PreInstallSourceMod"

Write-Log "Installing SourceMod..."

$metaModUrl = $Env:METAMOD_URL
$sourceModUrl = $Env:SOURCEMOD_URL

if (-not $metaModUrl) {
    $metaModUrl = "https://mms.alliedmods.net/mmsdrop/${Env:METAMOD_MAJOR_VERSION}/mmsource-${Env:METAMOD_VERSION}-linux.tar.gz"
}

if (-not $sourceModUrl) {
    $sourceModUrl = "https://sm.alliedmods.net/smdrop/${Env:SOURCEMOD_MAJOR_VERSION}/sourcemod-${Env:SOURCEMOD_VERSION}-linux.tar.gz"
}

if (-not $Env:INSTALL_SOURCEMOD) {
    Write-Log "INSTALL_SOURCEMOD is not set. Skipping SourceMod installation."
    return
}

$gameDir = "${Env:OVERLAY_DIR}/${Env:GAME_MOD}"

if (-not (Test-Path -Path $gameDir)) {
    Write-Log "Game directory $gameDir does not exist. Creating it."
    New-Item -ItemType Directory -Path $gameDir | Out-Null
}

if (-not (Test-Path -Path "$gameDir/addons/metamod.vdf")) {
    Write-Log "Downloading MetaMod from $metaModUrl"
    curl --output /tmp/mmsource.tar.gz "$metaModUrl"

    Write-Log "Extracting MetaMod to $gameDir"
    tar -xzf /tmp/mmsource.tar.gz -C $gameDir
} else {
    Write-Log "MetaMod is already installed. Skipping MetaMod installation."
}

if (-not (Test-Path -Path "$gameDir/addons/sourcemod")) {
    Write-Log "Downloading SourceMod from $sourceModUrl"
    curl --output /tmp/sourcemod.tar.gz "$sourceModUrl"

    Write-Log "Extracting SourceMod to $gameDir"
    tar -xzf /tmp/sourcemod.tar.gz -C $gameDir
} else {
    Write-Log "SourceMod is already installed. Skipping SourceMod installation."
    return
}

Invoke-Hook "PostInstallSourceMod"