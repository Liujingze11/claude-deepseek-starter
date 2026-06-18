# Claude Code + DeepSeek macOS

English · [中文版](README.zh.md)

A one-click install pack for Mac users: double-click to install Claude Code with DeepSeek API.

The installer chooses the runtime automatically: if your system already has usable Node.js, npm, and git, it skips Miniforge; if Homebrew is available, it uses Homebrew to prepare dependencies; Miniforge + conda is the final fallback. No need for Homebrew, Node.js, or npm to be pre-installed.

## Install

1. Download and unzip this folder.
2. Double-click `install.command`.
3. If macOS warns "cannot be opened", right-click `install.command`, select "Open", then click "Open".
4. Enter your DeepSeek API Key when prompted.
5. After installation, double-click `Claude Code DeepSeek` on the desktop.
6. In the pop-up window, select your project folder.

## During Installation

The installer shows numbered setup steps and heartbeat messages during long-running work. First-time installation may take several minutes while Miniforge, conda packages, npm packages, and Claude Code are downloaded.

At startup, the script checks the macOS version, CPU architecture, Bash version, curl version, and system Node.js/npm/git. If system tools are usable, it installs Claude Code under `~/.claude-deepseek/npm-global`; if dependencies are missing but Homebrew exists, it installs Node.js/git with Homebrew; otherwise it selects the Apple Silicon or Intel Miniforge installer automatically.

During the Claude Code step, npm runs with `--loglevel=info --progress=true`, and the installer prints a heartbeat every 10 seconds. If you see messages like `仍在执行：安装 Claude Code`, the installer is still running. Keep the window open while those messages continue.

## Slow or Interrupted Miniforge Downloads

If your system already has usable Node.js, npm, and git, the installer skips Miniforge automatically. To force that path:

```bash
cd macos
INSTALL_MODE=system ./install.command
```

If those tools are missing, the installer downloads Miniforge with HTTP/1.1, resume support, and retries by default. It no longer sets a 30-minute total download limit by default; it retries only when the connection is too slow for too long or disconnects. If GitHub Release downloads are still slow, configure a proxy before running:

```bash
cd macos
export HTTPS_PROXY=http://127.0.0.1:7890
export HTTP_PROXY=http://127.0.0.1:7890
CURL_HTTP_VERSION=http1.1 ./install.command
```

You can also download the matching Miniforge installer with a browser or download manager, then continue:

```bash
cd macos
MINIFORGE_INSTALLER=/path/to/Miniforge3-MacOSX-arm64.sh ./install.command
```

For semi-offline installs, put the installer in either path and the script will prefer the local file:

```text
macos/vendor/Miniforge3-MacOSX-arm64.sh
vendor/Miniforge3-MacOSX-arm64.sh
```

Or use your own mirror URL:

```bash
cd macos
MINIFORGE_URL=https://mirror.example.com/Miniforge3-MacOSX-arm64.sh ./install.command
```

## Install a Specific Claude Code Version

To install a known working Claude Code version:

```bash
cd macos
CLAUDE_CODE_VERSION=<known-working-version> ./install.command
```

## Install Mode

The default is `INSTALL_MODE=auto`:

- Reuse conda when conda already exists.
- Skip Miniforge when Node.js 18+, npm, and git are available.
- Reuse conda when system Node.js is unavailable but conda already exists.
- Use Homebrew when system Node.js and conda are unavailable but Homebrew exists.
- Prefer a local Miniforge installer under `macos/vendor/` or `vendor/` when present.
- Download Miniforge only as the final fallback.

You can also choose explicitly:

```bash
INSTALL_MODE=system ./install.command  # force system Node.js/npm/git
INSTALL_MODE=brew ./install.command    # force Homebrew dependency setup
INSTALL_MODE=conda ./install.command   # force Miniforge/conda isolation
```

## What the Script Does

- Detects whether your Mac is Apple Silicon or Intel.
- Checks basic macOS, Bash, and curl information.
- Chooses system Node.js, Homebrew, or Miniforge/conda mode automatically.
- When conda is needed, installs the appropriate Miniforge to `~/miniforge3` and creates the environment `claude-code-deepseek`.
- Installs Claude Code.
- Creates `.env` to store DeepSeek configuration.
- Creates the CLI launcher `~/.local/bin/claude-deepseek`.
- Creates the desktop launcher `Claude Code DeepSeek`.

## Daily Use

Double-click `Claude Code DeepSeek` on the desktop and select your project folder.

Terminal users can also:

```bash
claude-deepseek
```

Or specify a project directory:

```bash
claude-deepseek ~/projects/my-project
```

## Test DeepSeek Connection

Double-click `verify-deepseek.command`. If the output contains `DeepSeek OK`, the API is connected.

## Upgrade

Double-click `install.command` again. It reuses the existing environment and updates Claude Code.

## Uninstall

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
rm -rf ~/Desktop/"Claude Code DeepSeek.app"
rm -rf ~/.claude-deepseek
```

Then delete this folder.

---

For more questions, see the [main README](../README.md)
