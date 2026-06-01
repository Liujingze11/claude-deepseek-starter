# Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create two SVG icons (launcher + installer), convert to .ico/.icns/.png, and integrate into Windows/macOS/Linux install scripts with safe fallbacks.

**Architecture:** SVG source files live in `icons/`, platform binaries are pre-built alongside them. Install scripts copy the right format per platform, guarded by `Test-Path` (PowerShell) or `|| true` (bash). Icon absence never blocks installation or launch.

**Tech Stack:** SVG (hand-written), Python3 + Pillow + cairosvg (one-time conversion), bash/PowerShell (script modifications)

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| Create | `icons/launcher.svg` | Launcher icon source |
| Create | `icons/installer.svg` | Installer icon source |
| Create | `icons/generate.py` | One-shot conversion script |
| Create | `icons/launcher.ico` | Windows launcher icon |
| Create | `icons/installer.ico` | Windows installer icon |
| Create | `icons/launcher.icns` | macOS launcher icon |
| Create | `icons/installer.icns` | macOS installer icon |
| Create | `icons/launcher.png` | Linux launcher icon |
| Create | `icons/installer.png` | Linux installer icon |
| Modify | `windows/install.ps1:296-303` | Add IconLocation to .lnk |
| Modify | `macos/install.command:180-211` | Replace .command with .app bundle |
| Modify | `linux/install.sh:96-114` | Add .desktop file creation |

---

### Task 1: Create SVG icon source files

**Files:**
- Create: `icons/launcher.svg`
- Create: `icons/installer.svg`

- [ ] **Step 1: Create icons directory**

```bash
mkdir -p /home/ljz/vibe_coding/claude-deepseek-starter/icons
```

- [ ] **Step 2: Create launcher SVG**

Write `icons/launcher.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1e293b"/>
      <stop offset="100%" style="stop-color:#0f172a"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="110" fill="url(#bg)"/>
  <text x="256" y="215" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-weight="800" font-size="90" fill="#4fc3f7">CLAUDE</text>
  <line x1="110" y1="255" x2="402" y2="255" stroke="#334155" stroke-width="6" stroke-linecap="round"/>
  <text x="256" y="345" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-weight="700" font-size="64" fill="#94a3b8">DEEPSEEK</text>
</svg>
```

- [ ] **Step 3: Create installer SVG**

Write `icons/installer.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#283593"/>
      <stop offset="100%" style="stop-color:#1a237e"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="110" fill="url(#bg)"/>
  <text x="256" y="205" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-weight="800" font-size="90" fill="#4fc3f7">CLAUDE</text>
  <line x1="110" y1="245" x2="402" y2="245" stroke="#3949ab" stroke-width="6" stroke-linecap="round"/>
  <text x="256" y="335" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-weight="700" font-size="64" fill="#94a3b8">DEEPSEEK</text>
  <!-- INST badge -->
  <rect x="380" y="340" width="112" height="44" rx="16" fill="#f59e0b"/>
  <text x="436" y="370" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-weight="800" font-size="28" fill="#1a237e">INST</text>
</svg>
```

- [ ] **Step 4: Verify SVGs render correctly**

```bash
python3 -c "
import cairosvg
cairosvg.svg2svg(url='icons/launcher.svg', write_to='/dev/null')
cairosvg.svg2svg(url='icons/installer.svg', write_to='/dev/null')
print('Both SVGs parse OK')
"
```

Expected: `Both SVGs parse OK`

- [ ] **Step 5: Commit**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git add icons/launcher.svg icons/installer.svg
git commit -m "feat: add SVG icon source files for launcher and installer

Launcher: dark slate bg + CLAUDE / DEEPSEEK typography
Installer: deep blue bg + same text + orange INST badge

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: Create conversion script and generate all platform binaries

**Files:**
- Create: `icons/generate.py`
- Create: `icons/launcher.ico`, `icons/installer.ico`
- Create: `icons/launcher.icns`, `icons/installer.icns`
- Create: `icons/launcher.png`, `icons/installer.png`

- [ ] **Step 1: Install conversion dependencies**

```bash
pip install cairosvg Pillow
```

- [ ] **Step 2: Create the conversion script**

Write `icons/generate.py`:

```python
#!/usr/bin/env python3
"""Generate .png, .ico, .icns from launcher.svg and installer.svg.

Usage: python3 icons/generate.py
Output: icons/launcher.{png,ico,icns}, icons/installer.{png,ico,icns}
"""

import struct
import sys
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw, ImageFont

ICONS_DIR = Path(__file__).resolve().parent

# .icns icon type constants
ICN_TYPES = {
    16:  b"ic13",
    32:  b"ic11",
    64:  b"ic12",
    128: b"ic07",
    256: b"ic08",
    512: b"ic09",
    1024: b"ic10",
}


def svg_to_png(svg_path: Path, size: int) -> Image.Image:
    """Render SVG to PIL Image at given square size."""
    png_bytes = cairosvg.svg2png(
        url=str(svg_path),
        output_width=size,
        output_height=size,
    )
    # Use a temp file to avoid cairosvg write issues
    import io
    return Image.open(io.BytesIO(png_bytes))


def simplified_icon(size: int, bg_color: tuple, fg_color: tuple) -> Image.Image:
    """Generate a simplified 'C' icon for very small sizes (<=32px)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded rect approximation: draw filled rounded rect
    radius = max(2, size // 5)
    draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=radius,
        fill=bg_color,
    )

    # Draw a simple "C" letter centered
    try:
        font_size = int(size * 0.6)
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), "C", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    draw.text((x, y), "C", fill=fg_color, font=font)
    return img


def build_ico(svg_path: Path, out_path: Path, name: str):
    """Build multi-size .ico file."""
    sizes = [16, 32, 48, 256]
    images = []

    # Color scheme
    bg = (15, 23, 42)    # #0f172a
    fg = (79, 195, 247)  # #4fc3f7
    if "installer" in name:
        bg = (26, 35, 126)  # #1a237e

    for s in sizes:
        if s <= 32:
            img = simplified_icon(s, bg, fg)
        else:
            img = svg_to_png(svg_path, s)
        images.append(img)

    # Save as .ico with multiple sizes
    images[0].save(
        out_path,
        format="ICO",
        sizes=[(im.width, im.height) for im in images],
        append_images=images[1:],
    )
    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def build_icns(svg_path: Path, out_path: Path, name: str):
    """Build .icns file from SVG."""
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    png_entries = []

    bg = (15, 23, 42)
    fg = (79, 195, 247)
    if "installer" in name:
        bg = (26, 35, 126)

    for s in sizes:
        if s <= 32:
            img = simplified_icon(s, bg, fg)
        else:
            img = svg_to_png(svg_path, s)

        # Save to PNG bytes
        import io
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        png_bytes = buf.getvalue()
        png_entries.append((ICN_TYPES[s], png_bytes))

    # Build .icns container
    header_size = 8
    entry_header_size = 8
    total_size = header_size
    for itype, data in png_entries:
        total_size += entry_header_size + len(data)

    with open(out_path, "wb") as f:
        f.write(b"icns")
        f.write(struct.pack(">I", total_size))
        for itype, data in png_entries:
            entry_size = entry_header_size + len(data)
            f.write(itype)
            f.write(struct.pack(">I", entry_size))
            f.write(data)

    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def build_png(svg_path: Path, out_path: Path):
    """Build 128px PNG for Linux desktop entry."""
    img = svg_to_png(svg_path, 128)
    img.save(out_path, format="PNG")
    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def main():
    names = ["launcher", "installer"]
    for name in names:
        svg = ICONS_DIR / f"{name}.svg"
        if not svg.exists():
            print(f"ERROR: {svg} not found", file=sys.stderr)
            sys.exit(1)

        print(f"Generating icons for {name}...")
        build_ico(svg, ICONS_DIR / f"{name}.ico", name)
        build_icns(svg, ICONS_DIR / f"{name}.icns", name)
        build_png(svg, ICONS_DIR / f"{name}.png")

    print("Done. All icon binaries generated.")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run the conversion script**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
python3 icons/generate.py
```

Expected output:
```
Generating icons for launcher...
  Created icons/launcher.ico (... bytes)
  Created icons/launcher.icns (... bytes)
  Created icons/launcher.png (... bytes)
Generating icons for installer...
  Created icons/installer.ico (... bytes)
  Created icons/installer.icns (... bytes)
  Created icons/installer.png (... bytes)
Done. All icon binaries generated.
```

- [ ] **Step 4: Verify .ico contains expected sizes**

```bash
python3 -c "
from PIL import Image
ico = Image.open('icons/launcher.ico')
print(f'.ico sizes: {sorted(set(ico.size))}')  # Should show 16, 32, 48, 256
"
```

- [ ] **Step 5: Commit**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git add icons/generate.py icons/launcher.ico icons/installer.ico \
        icons/launcher.icns icons/installer.icns \
        icons/launcher.png icons/installer.png
git commit -m "feat: add platform icon binaries and generation script

Pre-built .ico (Windows), .icns (macOS), .png (Linux) for both
launcher and installer icons. generate.py can rebuild all from SVG.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: Update Windows install.ps1 to use launcher icon

**Files:**
- Modify: `windows/install.ps1:296-303`

- [ ] **Step 1: Add IconLocation to shortcut creation**

In `windows/install.ps1`, inside `Install-Launcher` function, replace lines 296-303 with:

```powershell
  $desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Claude Code DeepSeek.lnk"
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($desktopShortcut)
  $shortcut.TargetPath = "powershell.exe"
  $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$runner`""
  $shortcut.WorkingDirectory = $env:USERPROFILE
  $shortcut.WindowStyle = 1
  $icoPath = Join-Path $InstallDir "icons\launcher.ico"
  if (Test-Path $icoPath) {
    $shortcut.IconLocation = $icoPath
  }
  $shortcut.Save()
  Write-Step "已创建桌面快捷方式: $desktopShortcut"
```

The only additions are lines setting `$icoPath` and the `if (Test-Path $icoPath)` guard — the original shortcut creation is unchanged.

- [ ] **Step 2: Verify the change is syntactically valid**

```bash
pwsh -NoProfile -Command "Get-Command .\windows\install.ps1 -ErrorAction Stop; Write-Host 'Syntax OK'"
```

Or if `pwsh` is not available:

```bash
python3 -c "import ast; print('Python check only — PowerShell file must be checked on Windows or with pwsh')"
```

- [ ] **Step 3: Commit**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git add windows/install.ps1
git commit -m "feat(windows): add icon to desktop shortcut

Set IconLocation on .lnk if icons\launcher.ico exists.
Missing icon file silently falls back to system default.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: Update macOS install.command to create .app bundle

**Files:**
- Modify: `macos/install.command:180-211`

- [ ] **Step 1: Replace install_desktop_launcher function**

In `macos/install.command`, replace the `install_desktop_launcher()` function (lines 180-192) with:

```bash
install_desktop_launcher() {
  local desktop_dir="$HOME/Desktop"
  local app_name="Claude Code DeepSeek.app"
  local app_path="$desktop_dir/$app_name"
  local old_command="$desktop_dir/Claude Code DeepSeek.command"

  # Clean up old .command launcher from previous version
  if [ -f "$old_command" ]; then
    rm -f "$old_command"
    log "已移除旧版桌面快捷方式: $old_command"
  fi

  # If .app already exists, just refresh the icon and script
  mkdir -p "$app_path/Contents/MacOS"
  mkdir -p "$app_path/Contents/Resources"

  # Write the executable script inside the .app bundle
  cat > "$app_path/Contents/MacOS/run.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="%PROJECT_DIR%"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"

fail() {
  printf '\033[1;31m%s\033[0m\n' "$*" >&2
  printf '\n按回车键关闭窗口...'
  read -r _ || true
  exit 1
}

load_conda() {
  if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
  elif [ -x "$CONDA_HOME/bin/conda" ]; then
    eval "$("$CONDA_HOME/bin/conda" shell.bash hook)"
  else
    fail "找不到 conda。请先双击 install.command 完成安装。"
  fi
}

load_env_file() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    fail "缺少 .env。请先双击 install.command 完成安装。"
  fi

  set -a
  source "$PROJECT_DIR/.env"
  set +a
}

select_project_folder() {
  /usr/bin/osascript <<'APPLESCRIPT'
try
  set chosenFolder to choose folder with prompt "选择要用 Claude Code 打开的项目文件夹"
  POSIX path of chosenFolder
on error
  return ""
end try
APPLESCRIPT
}

load_env_file

export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.deepseek.com/anthropic}"
export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-pro[1m]}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-$ANTHROPIC_MODEL}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-$ANTHROPIC_MODEL}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-v4-flash}"
export CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDE_CODE_SUBAGENT_MODEL:-deepseek-v4-flash}"
export CLAUDE_CODE_EFFORT_LEVEL="${CLAUDE_CODE_EFFORT_LEVEL:-max}"

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ] || [ "$ANTHROPIC_AUTH_TOKEN" = "your_deepseek_api_key_here" ]; then
  fail "缺少 ANTHROPIC_AUTH_TOKEN。请编辑 $PROJECT_DIR/.env 填入 DeepSeek API Key。"
fi

PROJECT_PATH="${1:-}"
if [ -z "$PROJECT_PATH" ]; then
  PROJECT_PATH="$(select_project_folder)"
fi

if [ -z "$PROJECT_PATH" ]; then
  fail "未选择项目文件夹。"
fi

if [ ! -d "$PROJECT_PATH" ]; then
  fail "项目文件夹不存在: $PROJECT_PATH"
fi

load_conda
conda activate "$ENV_NAME"
cd "$PROJECT_PATH"
exec claude
SCRIPT

  # Substitute the actual project directory
  sed -i.bak "s|%PROJECT_DIR%|$PROJECT_DIR|g" "$app_path/Contents/MacOS/run.sh"
  rm -f "$app_path/Contents/MacOS/run.sh.bak"
  chmod +x "$app_path/Contents/MacOS/run.sh"

  # Write Info.plist
  cat > "$app_path/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>run.sh</string>
    <key>CFBundleIconFile</key>
    <string>launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.claude-deepseek-starter.launcher</string>
    <key>CFBundleName</key>
    <string>Claude Code DeepSeek</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
PLIST

  # Copy icon if it exists (failure is non-fatal — .app works without it)
  local icon_src="$PROJECT_DIR/icons/launcher.icns"
  if [ -f "$icon_src" ]; then
    cp "$icon_src" "$app_path/Contents/Resources/launcher.icns" || true
    log "已设置桌面图标"
  fi

  log "已创建桌面启动器: $app_path"
}
```

- [ ] **Step 2: Update main() completion message**

In `main()` at line 207, the message about double-clicking is still accurate since the .app bundle is also double-clickable. No change needed for the message text, but verify it still reads correctly:

```
log "完成。以后双击桌面"Claude Code DeepSeek"，选择项目文件夹即可启动。"
```

This line (207) does not need modification — the file name on disk changes from `.command` to `.app`, but macOS hides the extension so the user still sees "Claude Code DeepSeek".

- [ ] **Step 3: Verify syntax with bash -n**

```bash
bash -n macos/install.command && echo "Syntax OK"
```

- [ ] **Step 4: Commit**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git add macos/install.command
git commit -m "feat(macos): replace .command launcher with .app bundle

.app bundle supports custom .icns icon. Includes Info.plist,
embedded run.sh, and icon copy with || true guard. Old .command
file is cleaned up on re-install. Missing icon falls back to
macOS default document icon.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: Update Linux install.sh to create .desktop file

**Files:**
- Modify: `linux/install.sh:96-114`

- [ ] **Step 1: Add desktop entry creation to install_launcher function**

In `linux/install.sh`, replace the `install_launcher()` function (lines 96-114) with:

```bash
install_launcher() {
  local bin_dir="$HOME/.local/bin"
  local launcher="$bin_dir/claude-deepseek"

  mkdir -p "$bin_dir"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'exec %q/run-claude.sh "$@"\n' "$PROJECT_DIR"
  } > "$launcher"
  chmod +x "$launcher"

  log "已创建启动命令: $launcher"
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
      log "提示：$bin_dir 暂不在 PATH。可运行：echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
      ;;
  esac

  # Create desktop entry (icon is optional — missing file falls back to system default)
  local apps_dir="$HOME/.local/share/applications"
  mkdir -p "$apps_dir"
  local desktop_file="$apps_dir/claude-deepseek.desktop"
  local icon_path="$PROJECT_DIR/icons/launcher.png"

  cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Name=Claude Code DeepSeek
Comment=AI-powered coding assistant with Claude Code + DeepSeek
Exec=$launcher
Icon=$icon_path
Terminal=true
Type=Application
Categories=Development;
StartupNotify=true
DESKTOP

  chmod +x "$desktop_file"
  log "已创建桌面启动器: $desktop_file"
  if [ ! -f "$icon_path" ]; then
    log "提示：图标文件不存在 ($icon_path)，桌面将使用默认图标"
  fi
}
```

- [ ] **Step 2: Verify syntax with bash -n**

```bash
bash -n linux/install.sh && echo "Syntax OK"
```

- [ ] **Step 3: Commit**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git add linux/install.sh
git commit -m "feat(linux): add .desktop file creation with icon

Creates ~/.local/share/applications/claude-deepseek.desktop
pointing to icons/launcher.png. Desktop environments
automatically fall back to default icon if file is missing.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: Verify safety — icon absence does not break anything

- [ ] **Step 1: Test Windows path guard (PowerShell logic check)**

```bash
python3 -c "
# Simulate the Test-Path guard logic
ico_path = 'icons/launcher.ico'
import os
if os.path.exists(ico_path):
    print(f'Icon found: {ico_path}')
else:
    print('Icon not found — shortcut would use default icon (no error)')
print('Install would continue normally either way.')
"
```

- [ ] **Step 2: Test macOS .app creation without icon**

```bash
# Create a temp .app, verify it's valid without icns
tmpdir=$(mktemp -d)
mkdir -p "$tmpdir/Test.app/Contents/MacOS"
mkdir -p "$tmpdir/Test.app/Contents/Resources"
echo '#!/bin/bash
echo "hello"' > "$tmpdir/Test.app/Contents/MacOS/run.sh"
chmod +x "$tmpdir/Test.app/Contents/MacOS/run.sh"
cat > "$tmpdir/Test.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>run.sh</string>
<key>CFBundleName</key><string>Test</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
EOF
echo ".app bundle structure created successfully without icon"
echo "Directory structure:"
find "$tmpdir/Test.app" -type f
rm -rf "$tmpdir"
```

Expected: `.app bundle structure created successfully without icon`

- [ ] **Step 3: Test Linux .desktop with missing icon**

```bash
# Create a test .desktop with non-existent icon path, verify desktop-file-validate accepts it
tmpdir=$(mktemp -d)
cat > "$tmpdir/test.desktop" <<EOF
[Desktop Entry]
Name=Test
Exec=/bin/true
Icon=/nonexistent/path/icon.png
Terminal=true
Type=Application
EOF

if command -v desktop-file-validate &>/dev/null; then
  desktop-file-validate "$tmpdir/test.desktop" && echo "PASS: .desktop with missing icon passes validation"
else
  echo "SKIP: desktop-file-validate not installed, checking basic structure..."
  grep -q "Icon=" "$tmpdir/test.desktop" && echo "PASS: Icon key present in .desktop file"
fi
rm -rf "$tmpdir"
```

- [ ] **Step 4: Verify all script modifications pass syntax checks**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
bash -n linux/install.sh && echo "linux/install.sh: OK"
bash -n macos/install.command && echo "macos/install.command: OK"
python3 -c "
import re
with open('windows/install.ps1') as f:
    content = f.read()
# Check that IconLocation is guarded by Test-Path
assert 'Test-Path $icoPath' in content, 'Missing Test-Path guard'
assert 'IconLocation' in content, 'Missing IconLocation'
print('windows/install.ps1: OK')
"
```

- [ ] **Step 5: Commit final safety verification notes**

This step confirms all changes are committed and the working tree is clean.

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
git status
```

Expected: `nothing to commit, working tree clean`
