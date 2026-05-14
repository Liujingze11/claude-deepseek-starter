#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
MINIFORGE_VERSION="${MINIFORGE_VERSION:-latest}"

log() {
  printf '\033[1;34m[setup]\033[0m %s\n' "$*"
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
    sudo apt-get update
    sudo apt-get install -y curl
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
  curl -fsSL "$url" -o "$tmp_file"
  bash "$tmp_file" -b -p "$CONDA_HOME"
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
    conda create -y -n "$ENV_NAME" -c conda-forge nodejs=22 git curl ca-certificates
  fi
}

install_claude_code() {
  log "安装/更新 Claude Code 到 conda 环境: $ENV_NAME"
  conda activate "$ENV_NAME"
  npm install -g @anthropic-ai/claude-code@latest
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
  [ "$(uname -s)" = "Linux" ] || die "此脚本面向 Linux/Ubuntu。当前系统: $(uname -s)"
  ensure_curl

  ensure_conda
  load_conda
  ensure_env
  install_claude_code
  write_env_file
  install_launcher

  log "完成。运行下面命令启动 Claude Code + DeepSeek："
  printf '\n  cd 你的项目目录\n  claude-deepseek\n\n'
}

main "$@"
