# Claude Code + DeepSeek Windows

English · [中文版](README.zh.md)

Double-click install of Claude Code with DeepSeek API for Windows users.

Uses the Git for Windows route — regular users don't need to open a terminal.

Official docs: https://docs.anthropic.com/zh-CN/docs/claude-code/setup

## Install

1. Download and unzip this folder.
2. Double-click `setup.bat`.
3. Enter your DeepSeek API Key when prompted.
4. After installation, double-click `Claude Code DeepSeek` on the desktop.
5. In the pop-up window, select your project folder.

## During Installation

The installer shows numbered setup steps and heartbeat messages during long-running work. First-time installation may take several minutes while Git for Windows, Node.js, npm packages, and Claude Code are installed.

If you see messages like `仍在执行：安装 Claude Code`, the installer is still running. Keep the window open while those messages continue.

## Install a Specific Claude Code Version

To install a known working Claude Code version, run PowerShell manually:

```powershell
cd windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ClaudeCodeVersion <known-working-version>
```

## What the Script Does

- Checks for and installs Git for Windows.
- Checks for and installs Node.js LTS.
- Installs/updates Claude Code via npm.
- Creates `.env` to store DeepSeek configuration.
- Creates the `claude-deepseek` command.
- Creates the desktop shortcut `Claude Code DeepSeek`.

## Daily Use

Double-click `Claude Code DeepSeek` on the desktop and select your project folder.

Terminal users can also:

```powershell
claude-deepseek
```

Or specify a project directory:

```powershell
claude-deepseek C:\Users\me\projects\my-project
```

## Test DeepSeek Connection

Right-click `verify-deepseek.ps1` and select "Run with PowerShell".

Or in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-deepseek.ps1
```

## Upgrade

Double-click `setup.bat` again.

## Uninstall

- Delete `%USERPROFILE%\bin\claude-deepseek.cmd`
- Delete `Claude Code DeepSeek` from the desktop
- Delete the project folder

---

For more questions, see the [main README](../README.md)
