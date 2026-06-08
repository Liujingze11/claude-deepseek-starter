# Troubleshooting

## Install Looks Stuck

If the installer prints heartbeat messages, it is still running. First-time installation can take several minutes because dependencies are downloaded from GitHub, conda-forge, npm, winget, or other package sources.

Keep the window open while progress or heartbeat messages continue.

## Miniforge Download Fails

Check whether your network can reach GitHub. If you use a proxy, configure it before running the installer:

```bash
export HTTPS_PROXY=http://proxy-host:proxy-port
export HTTP_PROXY=http://proxy-host:proxy-port
```

Then re-run the installer.

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

Claude Code can disappear after an interrupted npm global package update. Remove leftover temporary package directories and reinstall:

```bash
conda activate claude-code-deepseek
rm -rf "$(npm root -g)"/.claude-code-*
npm install -g @anthropic-ai/claude-code
```
