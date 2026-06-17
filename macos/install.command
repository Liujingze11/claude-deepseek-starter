#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
MINIFORGE_VERSION="${MINIFORGE_VERSION:-latest}"
MINIFORGE_URL="${MINIFORGE_URL:-}"
MINIFORGE_INSTALLER="${MINIFORGE_INSTALLER:-}"
LAUNCHER_NAME="${LAUNCHER_NAME:-claude-deepseek}"
CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"
DOWNLOAD_MAX_TIME_SECONDS="${DOWNLOAD_MAX_TIME_SECONDS:-1800}"
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-5}"
DOWNLOAD_RETRY_DELAY_SECONDS="${DOWNLOAD_RETRY_DELAY_SECONDS:-3}"
CURL_HTTP_VERSION="${CURL_HTTP_VERSION:-http1.1}"
CURL_CONNECT_TIMEOUT_SECONDS="${CURL_CONNECT_TIMEOUT_SECONDS:-30}"
CURL_SPEED_LIMIT_BYTES="${CURL_SPEED_LIMIT_BYTES:-1024}"
CURL_SPEED_TIME_SECONDS="${CURL_SPEED_TIME_SECONDS:-60}"
NPM_FETCH_TIMEOUT_MS="${NPM_FETCH_TIMEOUT_MS:-1200000}"
NPM_FETCH_RETRIES="${NPM_FETCH_RETRIES:-5}"
NPM_FETCH_RETRY_MINTIMEOUT_MS="${NPM_FETCH_RETRY_MINTIMEOUT_MS:-20000}"
NPM_FETCH_RETRY_MAXTIMEOUT_MS="${NPM_FETCH_RETRY_MAXTIMEOUT_MS:-120000}"
HEARTBEAT_INTERVAL_SECONDS="${HEARTBEAT_INTERVAL_SECONDS:-30}"
NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS="${NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS:-10}"
TOTAL_STEPS=7
CURRENT_STEP=0

log() {
  printf '\033[1;34m[setup]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[setup:warn]\033[0m %s\n' "$*" >&2
}

format_elapsed() {
  local total="$1"
  printf '%02d:%02d' "$((total / 60))" "$((total % 60))"
}

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  log "[$CURRENT_STEP/$TOTAL_STEPS] $*"
}

run_with_heartbeat() {
  local interval="$HEARTBEAT_INTERVAL_SECONDS"
  if [ "${1:-}" = "--interval" ]; then
    if [ "$#" -lt 2 ]; then
      die "run_with_heartbeat 缺少 --interval 秒数"
    fi
    interval="${2:-$HEARTBEAT_INTERVAL_SECONDS}"
    shift 2
  fi

  local label="${1:-任务}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  if [ "$#" -eq 0 ]; then
    die "run_with_heartbeat 缺少要执行的命令: $label"
  fi

  local start pid heartbeat_pid status elapsed
  start="$(date +%s)"

  "$@" &
  pid="$!"

  (
    while kill -0 "$pid" 2>/dev/null; do
      sleep "$interval"
      if kill -0 "$pid" 2>/dev/null; then
        elapsed="$(($(date +%s) - start))"
        log "仍在执行：${label}。已用时：$(format_elapsed "$elapsed")。请不要关闭窗口。"
      fi
    done
  ) &
  heartbeat_pid="$!"

  set +e
  wait "$pid"
  status="$?"
  kill "$heartbeat_pid" 2>/dev/null || true
  wait "$heartbeat_pid" 2>/dev/null || true
  set -e

  return "$status"
}

curl_retry_all_errors_args() {
  if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
    printf '%s\n' '--retry-all-errors'
  fi
}

curl_http_version_args() {
  case "${CURL_HTTP_VERSION:-auto}" in
    http1.1)
      printf '%s\n' '--http1.1'
      ;;
    http2)
      printf '%s\n' '--http2'
      ;;
    auto|"")
      ;;
    *)
      warn "未知 CURL_HTTP_VERSION=${CURL_HTTP_VERSION}，将使用 curl 默认 HTTP 版本"
      ;;
  esac
}

download_file() {
  local url="${1:-}"
  local output="${2:-}"
  [ -n "$url" ] || die "download_file 缺少下载 URL"
  [ -n "$output" ] || die "download_file 缺少输出路径"

  local retry_all_errors
  local retry_args=()
  local http_version_args=()
  retry_all_errors="$(curl_retry_all_errors_args || true)"
  if [ -n "$retry_all_errors" ]; then
    retry_args+=("$retry_all_errors")
  fi
  while IFS= read -r arg; do
    [ -n "$arg" ] && http_version_args+=("$arg")
  done < <(curl_http_version_args)

  log "开始下载：$url"
  log "如下载长时间卡住或反复断开，可设置代理后重试，例如：export HTTPS_PROXY=http://127.0.0.1:7890"

  curl "${http_version_args[@]}" \
    -fL --progress-bar \
    --connect-timeout "$CURL_CONNECT_TIMEOUT_SECONDS" \
    --max-time "$DOWNLOAD_MAX_TIME_SECONDS" \
    --retry "$DOWNLOAD_RETRIES" \
    --retry-delay "$DOWNLOAD_RETRY_DELAY_SECONDS" \
    "${retry_args[@]}" \
    --continue-at - \
    --speed-limit "$CURL_SPEED_LIMIT_BYTES" \
    --speed-time "$CURL_SPEED_TIME_SECONDS" \
    "$url" -o "$output"
}

configure_npm_network() {
  npm config set fetch-timeout "$NPM_FETCH_TIMEOUT_MS"
  npm config set fetch-retries "$NPM_FETCH_RETRIES"
  npm config set fetch-retry-mintimeout "$NPM_FETCH_RETRY_MINTIMEOUT_MS"
  npm config set fetch-retry-maxtimeout "$NPM_FETCH_RETRY_MAXTIMEOUT_MS"
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

macos_product_version() {
  sw_vers -productVersion 2>/dev/null || printf '%s\n' "unknown"
}

curl_version_line() {
  curl --version 2>/dev/null | sed -n '1p' || printf '%s\n' "unknown"
}

preflight_macos() {
  ensure_macos

  local macos_version machine bash_major curl_version
  macos_version="$(macos_product_version)"
  machine="$(uname -m)"
  bash_major="${BASH_VERSION%%.*}"

  case "$machine" in
    arm64|x86_64)
      ;;
    *)
      die "不支持的 CPU 架构: ${machine}。此安装器仅支持 Apple Silicon arm64 和 Intel x86_64。"
      ;;
  esac

  case "$bash_major" in
    ""|*[!0-9]*)
      warn "无法识别 Bash 版本: ${BASH_VERSION:-unknown}"
      ;;
    *)
      if [ "$bash_major" -lt 3 ]; then
        die "当前 Bash 版本过旧: ${BASH_VERSION:-unknown}。请用 macOS 自带 Terminal 运行 install.command。"
      fi
      ;;
  esac

  ensure_curl
  curl_version="$(curl_version_line)"

  log "检测到 macOS ${macos_version}，架构 ${machine}"
  log "Bash 版本: ${BASH_VERSION:-unknown}"
  log "curl 版本: ${curl_version}"
  if [ "$macos_version" = "unknown" ]; then
    warn "无法读取 macOS 版本，将继续按当前架构和工具能力尝试安装。"
  fi
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

miniforge_download_url() {
  local installer="$1"

  if [ -n "$MINIFORGE_URL" ]; then
    printf '%s\n' "$MINIFORGE_URL"
    return
  fi

  if [ "$MINIFORGE_VERSION" = "latest" ]; then
    printf 'https://github.com/conda-forge/miniforge/releases/latest/download/%s\n' "$installer"
  else
    printf 'https://github.com/conda-forge/miniforge/releases/download/%s/%s\n' "$MINIFORGE_VERSION" "$installer"
  fi
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
  local installer url tmp_file installer_file
  tmp_file=""
  installer="$(detect_miniforge_installer)"

  if [ -n "$MINIFORGE_INSTALLER" ]; then
    if [ ! -f "$MINIFORGE_INSTALLER" ]; then
      die "MINIFORGE_INSTALLER 指向的文件不存在: $MINIFORGE_INSTALLER"
    fi
    if [ ! -s "$MINIFORGE_INSTALLER" ]; then
      die "MINIFORGE_INSTALLER 指向的文件为空: $MINIFORGE_INSTALLER"
    fi
    installer_file="$MINIFORGE_INSTALLER"
    log "使用本地 Miniforge 安装包: $installer_file"
  else
    url="$(miniforge_download_url "$installer")"
    log "将使用 Miniforge 安装包: $installer"
    if [ -n "$MINIFORGE_URL" ]; then
      log "使用自定义 Miniforge 下载地址: $MINIFORGE_URL"
    fi

    tmp_file="$(mktemp "/tmp/$installer.XXXXXX")"
    if ! run_with_heartbeat "下载 Miniforge" download_file "$url" "$tmp_file"; then
      rm -f "$tmp_file"
      die "Miniforge 下载失败。请检查网络或代理后重试。可尝试：
  export HTTPS_PROXY=http://127.0.0.1:7890
  export HTTP_PROXY=http://127.0.0.1:7890
  CURL_HTTP_VERSION=http1.1 ./install.command

如果 GitHub 下载仍然很慢，也可以先手动下载对应架构安装包，再运行：
  MINIFORGE_INSTALLER=/path/to/$installer ./install.command"
    fi
    installer_file="$tmp_file"
  fi

  if ! run_with_heartbeat "安装 Miniforge 到 $CONDA_HOME" bash "$installer_file" -b -p "$CONDA_HOME"; then
    rm -f "$tmp_file"
    die "Miniforge 安装失败。请删除不完整目录后重试：$CONDA_HOME"
  fi
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
    run_with_heartbeat "创建 conda 环境 $ENV_NAME" conda create -y -n "$ENV_NAME" -c conda-forge nodejs=22 git curl ca-certificates
  fi
}

install_claude_code() {
  log "安装/更新 Claude Code 到 conda 环境: $ENV_NAME"
  conda activate "$ENV_NAME"
  log "正在通过 npm 下载/安装 Claude Code；网络慢时可能需要几分钟。"
  run_with_heartbeat --interval "$NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS" "安装 Claude Code $CLAUDE_CODE_VERSION" npm install -g --loglevel=info --progress=true "@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION"
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
  step "检查 macOS 环境"
  preflight_macos
  chmod +x "$PROJECT_DIR/run-claude.command" "$PROJECT_DIR/verify-deepseek.command" 2>/dev/null || true

  step "检查或安装 Miniforge"
  ensure_conda

  step "加载 conda"
  load_conda

  step "创建或复用 conda 环境"
  ensure_env

  step "配置 npm 网络超时和重试"
  conda activate "$ENV_NAME"
  configure_npm_network

  step "安装 Claude Code 版本: $CLAUDE_CODE_VERSION"
  install_claude_code

  step "写入配置并创建启动器"
  write_env_file
  install_cli_launcher
  install_desktop_launcher

  log "完成。以后双击桌面“Claude Code DeepSeek”，选择项目文件夹即可启动。"
  pause_done
}

main "$@"
