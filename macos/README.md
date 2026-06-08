# Claude Code + DeepSeek macOS

English · [中文版](README.zh.md)

A one-click install pack for Mac users: double-click to install Claude Code with DeepSeek API.

Uses Miniforge + conda isolated environment. No need for Homebrew, Node.js, or npm to be pre-installed.

## Install

1. Download and unzip this folder.
2. Double-click `install.command`.
3. If macOS warns "cannot be opened", right-click `install.command`, select "Open", then click "Open".
4. Enter your DeepSeek API Key when prompted.
5. After installation, double-click `Claude Code DeepSeek` on the desktop.
6. In the pop-up window, select your project folder.

## During Installation

The installer shows numbered setup steps and heartbeat messages during long-running work. First-time installation may take several minutes while Miniforge, conda packages, npm packages, and Claude Code are downloaded.

During the Claude Code step, npm runs with `--loglevel=info --progress=true`, and the installer prints a heartbeat every 10 seconds. If you see messages like `仍在执行：安装 Claude Code`, the installer is still running. Keep the window open while those messages continue.

## Install a Specific Claude Code Version

To install a known working Claude Code version:

```bash
cd macos
CLAUDE_CODE_VERSION=<known-working-version> ./install.command
```

## What the Script Does

- Detects whether your Mac is Apple Silicon or Intel.
- If conda is not present, installs the appropriate Miniforge to `~/miniforge3`.
- Creates the conda environment `claude-code-deepseek`.
- Installs Node.js, npm, git, curl, and Claude Code in the isolated environment.
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
```

Then delete this folder.

---

For more questions, see the [main README](../README.md)
