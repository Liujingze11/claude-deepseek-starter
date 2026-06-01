[中文](README.zh.md)

# Claude Code + DeepSeek Windows

Double-click install of Claude Code with DeepSeek API for Windows colleagues.

Uses the Git for Windows route — regular colleagues don't need to open a terminal.

Official docs: https://docs.anthropic.com/zh-CN/docs/claude-code/setup

## Install

1. Download and unzip this folder.
2. Double-click `setup.bat`.
3. Enter your DeepSeek API Key when prompted.
4. After installation, double-click `Claude Code DeepSeek` on the desktop.
5. In the pop-up window, select your project folder.

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
