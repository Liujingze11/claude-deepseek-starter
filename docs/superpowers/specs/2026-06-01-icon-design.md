# Icon Design for Claude Code + DeepSeek Starter

## Overview

给桌面启动器和安装器添加自定义图标。使用 "CLAUDE / DEEPSEEK" 紧凑排版风格，预构建各平台所需格式，安装脚本复制时绝不影响原有功能。

## Icon Design

### Launcher Icon

- Base: rounded rect (rx 22), `#0f172a` dark slate
- Top: "CLAUDE" in bold system-ui, `#4fc3f7` cyan
- Middle: horizontal separator line, `#334155`
- Bottom: "DEEPSEEK" in bold system-ui, `#94a3b8` muted gray

### Installer Icon

- Same as launcher, with differences:
  - Background: `#1a237e` deep blue
  - Separator: `#3949ab`
  - Badge: orange `#f59e0b` "INST" pill at bottom-right corner

### Small Sizes

At 16px the text becomes illegible. For sizes <= 32px, the .ico/.icns can use a simplified version (just "C" on dark rounded rect, same color scheme). The SVG source always renders the full version; the simplified variant lives only in the multi-size binary containers.

## File Formats & Sizes

| Platform | Format | Sizes | File |
|----------|--------|-------|------|
| Windows | `.ico` | 16, 32, 48, 256 | `icons/launcher.ico`, `icons/installer.ico` |
| macOS | `.icns` | 16-1024 | `icons/launcher.icns`, `icons/installer.icns` |
| Linux | `.png` | 128 | `icons/launcher.png`, `icons/installer.png` |

Source files: `icons/launcher.svg`, `icons/installer.svg`.

## Repo Structure

```
icons/
├── launcher.svg
├── installer.svg
├── launcher.ico
├── installer.ico
├── launcher.icns
├── installer.icns
├── launcher.png
└── installer.png
```

## Platform Integration

### Windows (`windows/install.ps1`)

Add `IconLocation` to existing WScript.Shell shortcut creation:

```powershell
$icoPath = Join-Path $InstallDir "icons\launcher.ico"
if (Test-Path $icoPath) {
  $shortcut.IconLocation = $icoPath
}
$shortcut.Save()
```

`.lnk` natively falls back to default icon when IconLocation points to missing file. No error handling needed beyond `Test-Path`.

### macOS (`macos/install.command`)

Replace desktop `.command` file with a minimal `.app` bundle:

```
~/Desktop/Claude Code DeepSeek.app/
├── Contents/
│   ├── MacOS/
│   │   └── run.sh          # same logic as run-claude.command
│   └── Resources/
│       └── launcher.icns    # optional; copied if exists
```

Create with plain shell (no Xcode needed). Copy icns with `|| true` so missing file is not an error.

Also delete old `~/Desktop/Claude Code DeepSeek.command` if it exists (idempotency).

### Linux (`linux/install.sh`)

Create a `.desktop` file for the launcher:

```desktop
[Desktop Entry]
Name=Claude Code DeepSeek
Exec=$HOME/.local/bin/claude-deepseek
Icon=$PROJECT_DIR/icons/launcher.png
Terminal=true
Type=Application
Categories=Development;
```

Copy `.desktop` to `~/.local/share/applications/`. `Icon=` pointing to missing file triggers desktop environment fallback icon automatically.

## Safety Guarantees

- All icon copy operations use `|| true` (bash) or `if (Test-Path)` guard (PowerShell)
- Icon file existence is never a precondition for any other step
- Startup scripts (`run-claude.*`) are never modified — icons only affect desktop shortcut appearance
- If `icons/` directory is entirely deleted, behavior reverts to pre-icon state

## Non-requirements

- Do not add conversion tools to the install scripts (pre-built binaries)
- Do not attempt to give `.command` or `.bat` files custom icons (platform limitation)
- Do not create icons for the CLI-only `~/.local/bin/claude-deepseek` command
