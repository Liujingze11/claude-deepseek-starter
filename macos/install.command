#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
MINIFORGE_VERSION="${MINIFORGE_VERSION:-latest}"
LAUNCHER_NAME="${LAUNCHER_NAME:-claude-deepseek}"

log() {
  printf '\033[1;34m[setup]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[setup:warn]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[setup:error]\033[0m %s\n' "$*" >&2
  printf '\n按回车键关闭窗口...'
  read -r _ || true
  exit 1
}

pause_done() {
  printf '\n按回车键关闭窗口...'
  read -r _ || true
}

ensure_macos() {
  [ "$(uname -s)" = "Darwin" ] || die "此脚本面向 macOS。当前系统: $(uname -s)"
}

ensure_curl() {
  command -v curl >/dev/null 2>&1 || die "缺少 curl。macOS 通常自带 curl，请联系 IT 检查系统环境。"
}

detect_miniforge_installer() {
  local machine
  machine="$(uname -m)"
  case "$machine" in
    arm64) echo "Miniforge3-MacOSX-arm64.sh" ;;
    x86_64) echo "Miniforge3-MacOSX-x86_64.sh" ;;
    *) die "不支持的 CPU 架构: $machine" ;;
  esac
}

ensure_conda() {
  if command -v conda >/dev/null 2>&1; then
    log "检测到系统已有 conda: $(command -v conda)"
    return
  fi

  if [ -x "$CONDA_HOME/bin/conda" ]; then
    log "检测到本地 Miniforge: $CONDA_HOME"
    return
  fi

  log "未检测到 conda，开始安装 Miniforge 到 $CONDA_HOME"
  local installer url tmp_file
  installer="$(detect_miniforge_installer)"
  if [ "$MINIFORGE_VERSION" = "latest" ]; then
    url="https://github.com/conda-forge/miniforge/releases/latest/download/$installer"
  else
    url="https://github.com/conda-forge/miniforge/releases/download/$MINIFORGE_VERSION/$installer"
  fi

  tmp_file="$(mktemp "/tmp/$installer.XXXXXX")"
  curl -fsSL "$url" -o "$tmp_file"
  bash "$tmp_file" -b -p "$CONDA_HOME"
  rm -f "$tmp_file"
}

load_conda() {
  if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
  elif [ -x "$CONDA_HOME/bin/conda" ]; then
    eval "$("$CONDA_HOME/bin/conda" shell.bash hook)"
  else
    die "conda 初始化失败"
  fi
}

ensure_env() {
  if conda env list | awk '{print $1}' | grep -Fxq "$ENV_NAME"; then
    log "conda 环境已存在: $ENV_NAME"
  else
    log "创建 conda 环境: $ENV_NAME"
    conda create -y -n "$ENV_NAME" -c conda-forge nodejs=22 git curl ca-certificates
  fi
}

install_claude_code() {
  log "安装/更新 Claude Code 到 conda 环境: $ENV_NAME"
  conda activate "$ENV_NAME"
  npm install -g @anthropic-ai/claude-code@latest
  claude --version || warn "Claude Code 已安装，但当前窗口暂时找不到 claude 命令；重新打开后通常会生效。"
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp_file
  local found=0

  tmp_file="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == "$key="* ]]; then
      printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
      found=1
    else
      printf '%s\n' "$line" >> "$tmp_file"
    fi
  done < "$file"

  if [ "$found" -eq 0 ]; then
    printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
  fi

  mv "$tmp_file" "$file"
}

write_env_file() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    chmod 600 "$PROJECT_DIR/.env"
    log "已创建 $PROJECT_DIR/.env"
  fi

  if grep -Eq '^ANTHROPIC_AUTH_TOKEN=sk-' "$PROJECT_DIR/.env"; then
    log ".env 已配置 DeepSeek API Key"
    return
  fi

  printf '\n请输入 DeepSeek API Key（输入时不显示；可直接回车稍后手动编辑 .env）：'
  local api_key
  read -r -s api_key || true
  printf '\n'
  if [ -n "$api_key" ]; then
    set_env_value "$PROJECT_DIR/.env" "ANTHROPIC_AUTH_TOKEN" "$api_key"
    chmod 600 "$PROJECT_DIR/.env"
    log "DeepSeek API Key 已写入 .env"
  else
    warn "已跳过 API Key 写入；稍后编辑 $PROJECT_DIR/.env"
  fi
}

add_user_path_hint() {
  local bin_dir="$1"
  local shell_rc="$HOME/.zshrc"
  local line='export PATH="$HOME/.local/bin:$PATH"'

  case ":$PATH:" in
    *":$bin_dir:"*) return ;;
  esac

  touch "$shell_rc"
  if ! grep -Fxq "$line" "$shell_rc"; then
    printf '\n%s\n' "$line" >> "$shell_rc"
    log "已把 $bin_dir 加入 ~/.zshrc"
  fi
}

install_cli_launcher() {
  local bin_dir="$HOME/.local/bin"
  local launcher="$bin_dir/$LAUNCHER_NAME"

  mkdir -p "$bin_dir"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'exec %q/run-claude.command "$@"\n' "$PROJECT_DIR"
  } > "$launcher"
  chmod +x "$launcher"

  add_user_path_hint "$bin_dir"
  log "已创建终端启动命令: $launcher"
}

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

main() {
  ensure_macos
  ensure_curl
  chmod +x "$PROJECT_DIR/run-claude.command" "$PROJECT_DIR/verify-deepseek.command" 2>/dev/null || true

  ensure_conda
  load_conda
  ensure_env
  install_claude_code
  write_env_file
  install_cli_launcher
  install_desktop_launcher

  log "完成。以后双击桌面“Claude Code DeepSeek”，选择项目文件夹即可启动。"
  pause_done
}

main "$@"
