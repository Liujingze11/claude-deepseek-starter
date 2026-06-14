#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
MINIFORGE_VERSION="${MINIFORGE_VERSION:-latest}"
CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"
DOWNLOAD_MAX_TIME_SECONDS="${DOWNLOAD_MAX_TIME_SECONDS:-1800}"
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-5}"
DOWNLOAD_RETRY_DELAY_SECONDS="${DOWNLOAD_RETRY_DELAY_SECONDS:-3}"
NPM_FETCH_TIMEOUT_MS="${NPM_FETCH_TIMEOUT_MS:-1200000}"
NPM_FETCH_RETRIES="${NPM_FETCH_RETRIES:-5}"
NPM_FETCH_RETRY_MINTIMEOUT_MS="${NPM_FETCH_RETRY_MINTIMEOUT_MS:-20000}"
NPM_FETCH_RETRY_MAXTIMEOUT_MS="${NPM_FETCH_RETRY_MAXTIMEOUT_MS:-120000}"
HEARTBEAT_INTERVAL_SECONDS="${HEARTBEAT_INTERVAL_SECONDS:-30}"
NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS="${NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS:-10}"
NPM_NATIVE_BINARY_MIN_BYTES="${NPM_NATIVE_BINARY_MIN_BYTES:-1000000}"
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
    interval="$2"
    shift 2
  fi

  local label="$1"
  shift

  local start pid heartbeat_pid status elapsed
  start="$(date +%s)"

  "$@" &
  pid="$!"

  (
    while kill -0 "$pid" 2>/dev/null; do
      sleep "$interval"
      if kill -0 "$pid" 2>/dev/null; then
        elapsed="$(($(date +%s) - start))"
        log "仍在执行：$label。已用时：$(format_elapsed "$elapsed")。请不要关闭窗口。"
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

download_file() {
  local url="$1"
  local output="$2"
  local retry_all_errors
  retry_all_errors="$(curl_retry_all_errors_args)"

  if [ -n "$retry_all_errors" ]; then
    curl -fL --progress-bar \
      --connect-timeout 30 \
      --max-time "$DOWNLOAD_MAX_TIME_SECONDS" \
      --retry "$DOWNLOAD_RETRIES" \
      --retry-delay "$DOWNLOAD_RETRY_DELAY_SECONDS" \
      --retry-all-errors \
      "$url" -o "$output"
  else
    curl -fL --progress-bar \
      --connect-timeout 30 \
      --max-time "$DOWNLOAD_MAX_TIME_SECONDS" \
      --retry "$DOWNLOAD_RETRIES" \
      --retry-delay "$DOWNLOAD_RETRY_DELAY_SECONDS" \
      "$url" -o "$output"
  fi
}

configure_npm_network() {
  npm config set fetch-timeout "$NPM_FETCH_TIMEOUT_MS"
  npm config set fetch-retries "$NPM_FETCH_RETRIES"
  npm config set fetch-retry-mintimeout "$NPM_FETCH_RETRY_MINTIMEOUT_MS"
  npm config set fetch-retry-maxtimeout "$NPM_FETCH_RETRY_MAXTIMEOUT_MS"
  npm config set ignore-scripts false
  npm config set optional true
  npm config delete omit >/dev/null 2>&1 || true
}

die() {
  printf '\033[1;31m[setup:error]\033[0m %s\n' "$*" >&2
  exit 1
}

ensure_curl() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    log "未检测到 curl，尝试通过 apt-get 安装"
    run_with_heartbeat "更新 apt 软件包索引" sudo apt-get update
    run_with_heartbeat "安装 curl" sudo apt-get install -y curl
    return
  fi

  die "缺少 curl。请先安装 curl，例如：sudo apt-get install -y curl"
}

detect_miniforge_installer() {
  local machine
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) echo "Miniforge3-Linux-x86_64.sh" ;;
    aarch64|arm64) echo "Miniforge3-Linux-aarch64.sh" ;;
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
  run_with_heartbeat "下载 Miniforge" download_file "$url" "$tmp_file"
  run_with_heartbeat "安装 Miniforge 到 $CONDA_HOME" bash "$tmp_file" -b -p "$CONDA_HOME"
  rm -f "$tmp_file"
}

load_conda() {
  if command -v conda >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    eval "$(conda shell.bash hook)"
  elif [ -x "$CONDA_HOME/bin/conda" ]; then
    # shellcheck disable=SC1091
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

anthropic_scope_dir() {
  printf '%s/@anthropic-ai\n' "$1"
}

cleanup_claude_code_temp_dirs() {
  local scope_dir
  scope_dir="$(anthropic_scope_dir "$1")"
  [ -d "$scope_dir" ] || return 0
  rm -rf "$scope_dir"/.claude-code-*
}

claude_code_binary_path() {
  printf '%s/@anthropic-ai/claude-code/bin/claude.exe\n' "$1"
}

file_size_bytes() {
  stat -c%s "$1" 2>/dev/null || printf '0\n'
}

claude_command_in_conda_env() {
  local claude_cmd
  claude_cmd="$(command -v claude 2>/dev/null || true)"
  [ -n "$claude_cmd" ] || return 1
  case "$claude_cmd" in
    "$CONDA_PREFIX"/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_claude_code_healthy() {
  local npm_root binary_path binary_size
  npm_root="$(npm root -g 2>/dev/null)" || return 1
  binary_path="$(claude_code_binary_path "$npm_root")"

  claude_command_in_conda_env || return 1
  [ -f "$binary_path" ] || return 1

  binary_size="$(file_size_bytes "$binary_path")"
  [ "$binary_size" -ge "$NPM_NATIVE_BINARY_MIN_BYTES" ] || return 1

  claude --version >/dev/null 2>&1
}

install_claude_code_package() {
  npm install -g \
    --include=optional \
    --ignore-scripts=false \
    --foreground-scripts \
    --loglevel=info \
    --progress=true \
    "@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION"
  hash -r
}

install_claude_code() {
  local npm_root scope_dir status
  log "安装/更新 Claude Code 到 conda 环境: $ENV_NAME"
  conda activate "$ENV_NAME"
  npm_root="$(npm root -g)"
  scope_dir="$(anthropic_scope_dir "$npm_root")"
  cleanup_claude_code_temp_dirs "$npm_root"
  log "正在通过 npm 下载/安装 Claude Code；网络慢时可能需要几分钟。"
  set +e
  run_with_heartbeat --interval "$NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS" "安装 Claude Code $CLAUDE_CODE_VERSION" install_claude_code_package
  status="$?"
  set -e
  hash -r

  if [ "$status" -ne 0 ]; then
    warn "Claude Code 安装失败，正在清理 npm 残留后重试。"
    rm -rf "$scope_dir/claude-code" "$scope_dir"/.claude-code-*
    run_with_heartbeat --interval "$NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS" "重新安装 Claude Code $CLAUDE_CODE_VERSION" install_claude_code_package
    hash -r
  fi

  if ! is_claude_code_healthy; then
    warn "检测到 Claude Code native binary 未正确安装，正在强制清理并重装。"
    rm -rf "$scope_dir/claude-code" "$scope_dir"/.claude-code-*
    run_with_heartbeat --interval "$NPM_INSTALL_HEARTBEAT_INTERVAL_SECONDS" "修复 Claude Code native binary" install_claude_code_package
    hash -r
  fi

  is_claude_code_healthy || die "Claude Code 安装后自检失败。请检查网络、npm 代理，或设置 CLAUDE_CODE_VERSION 为已知可用版本后重试。"
  claude --version
}

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
    log "已创建 $PROJECT_DIR/.env"
  fi

  if grep -Eq '^ANTHROPIC_AUTH_TOKEN=sk-' "$PROJECT_DIR/.env"; then
    log ".env 已配置 DeepSeek API Key"
    return
  fi

  printf '\n请输入 DeepSeek API Key（输入时不显示，不会上传到 GitHub；可直接回车稍后手动编辑 .env）：'
  local api_key
  read -r -s api_key || true
  printf '\n'
  if [ -n "$api_key" ]; then
    set_env_value "$PROJECT_DIR/.env" "ANTHROPIC_AUTH_TOKEN" "$api_key"
    chmod 600 "$PROJECT_DIR/.env"
    log "DeepSeek API Key 已写入 .env"
  else
    log "已跳过 API Key 写入；稍后编辑 .env 里的 ANTHROPIC_AUTH_TOKEN"
  fi
}

main() {
  step "检查 Linux 环境"
  [ "$(uname -s)" = "Linux" ] || die "此脚本面向 Linux/Ubuntu。当前系统: $(uname -s)"
  ensure_curl

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
  install_launcher

  log "完成。运行下面命令启动 Claude Code + DeepSeek："
  printf '\n  cd 你的项目目录\n  claude-deepseek\n\n'
}

main "$@"
