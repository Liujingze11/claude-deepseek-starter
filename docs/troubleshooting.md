# Troubleshooting

## Install Looks Stuck

If the installer prints heartbeat messages, it is still running. First-time installation can take several minutes because dependencies are downloaded from GitHub, conda-forge, npm, winget, or other package sources.

Keep the window open while progress or heartbeat messages continue.

## Miniforge Download Fails

On macOS, if Node.js 18+, npm, and git are already installed, you can skip Miniforge:

```bash
cd macos
INSTALL_MODE=system ./install.command
```

Check whether your network can reach GitHub. If you use a proxy, configure it before running the installer:

```bash
export HTTPS_PROXY=http://proxy-host:proxy-port
export HTTP_PROXY=http://proxy-host:proxy-port
```

Then re-run the installer.

On macOS, the installer uses HTTP/1.1, resume support, and retries for Miniforge downloads by default. If downloads still disconnect repeatedly, run:

```bash
cd macos
CURL_HTTP_VERSION=http1.1 ./install.command
```

You can also download the matching Miniforge installer manually, then let the installer continue:

```bash
cd macos
MINIFORGE_INSTALLER=/path/to/Miniforge3-MacOSX-arm64.sh ./install.command
```

If you have a mirror URL:

```bash
cd macos
MINIFORGE_URL=https://mirror.example.com/Miniforge3-MacOSX-arm64.sh ./install.command
```

## conda Environment Creation Fails

This usually means conda-forge is unreachable or the network was interrupted. Re-run the installer after the network is stable. The installer reuses the existing environment when possible.

## npm Install Times Out

The installer configures npm with longer timeouts and retries:

```bash
npm config set fetch-timeout 1200000
npm config set fetch-retries 5
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
```

If npm still fails, configure your npm proxy:

```bash
npm config set proxy http://proxy-host:proxy-port
npm config set https-proxy http://proxy-host:proxy-port
```

Then re-run the installer.

During the Claude Code install step, npm runs with `--loglevel=info --progress=true`, and the installer prints a heartbeat every 10 seconds. If npm does not show a percentage, the heartbeat still means the install is running.

## Install a Known Working Claude Code Version

macOS:

```bash
cd macos
CLAUDE_CODE_VERSION=<known-working-version> ./install.command
```

Linux:

```bash
cd linux
CLAUDE_CODE_VERSION=<known-working-version> ./install.sh
```

Windows:

```powershell
cd windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ClaudeCodeVersion <known-working-version>
```

## Windows winget Issues

`winget` is provided by Microsoft App Installer. If `winget` is missing, update or install App Installer from Microsoft Store. If Microsoft Store is disabled, ask your administrator to install Git for Windows and Node.js LTS manually, then re-run `windows/setup.bat`.

## `claude: command not found` After It Worked Before

Claude Code can disappear after an interrupted npm global package update. On Linux, `claude-deepseek` checks for this before launch and repairs the dedicated conda environment automatically.

If automatic repair still fails, remove the broken package from that conda environment and reinstall:

```bash
conda activate claude-code-deepseek
rm -rf "$(npm root -g)"/@anthropic-ai/claude-code
rm -rf "$(npm root -g)"/@anthropic-ai/.claude-code-*
npm install -g --include=optional --ignore-scripts=false --foreground-scripts @anthropic-ai/claude-code
```

The repair only touches the npm global package directory of the active conda environment. It does not remove project files, system Node.js packages, or other conda environments.

## `claude native binary not installed`

This means the JavaScript wrapper package exists, but the platform-native Claude Code binary was not installed. It usually happens when npm optional dependencies were skipped, postinstall scripts did not run, or an update was interrupted.

On Linux, run `claude-deepseek` again. The launcher checks whether the native binary is still a tiny placeholder file and reinstalls Claude Code inside `claude-code-deepseek` when needed.

For a manual fix:

```bash
conda activate claude-code-deepseek
rm -rf "$(npm root -g)"/@anthropic-ai/claude-code
rm -rf "$(npm root -g)"/@anthropic-ai/.claude-code-*
npm install -g --include=optional --ignore-scripts=false --foreground-scripts @anthropic-ai/claude-code
```
