#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"
NPM_NATIVE_BINARY_MIN_BYTES="${NPM_NATIVE_BINARY_MIN_BYTES:-1000000}"
ORIGINAL_DIR="$(pwd)"

log() {
  printf '\033[1;34m[claude-deepseek]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[claude-deepseek:warn]\033[0m %s\n' "$*" >&2
}

fail() {
  printf '\033[1;31m[claude-deepseek:error]\033[0m %s\n' "$*" >&2
  exit 1
}

load_conda() {
  if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
  elif [ -x "$CONDA_HOME/bin/conda" ]; then
    eval "$("$CONDA_HOME/bin/conda" shell.bash hook)"
  else
    fail "找不到 conda。请先运行 ./install.sh"
  fi
}

load_env_file() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    fail "缺少 $PROJECT_DIR/.env。请先运行 ./install.sh"
  fi

  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
}

export_deepseek_env() {
  export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.deepseek.com/anthropic}"
  export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-pro[1m]}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-deepseek-v4-pro[1m]}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-deepseek-v4-pro[1m]}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-v4-flash}"
  export CLAUDE_CODE_SUBAGENT_MODEL="${CLAUDE_CODE_SUBAGENT_MODEL:-deepseek-v4-flash}"
  export CLAUDE_CODE_EFFORT_LEVEL="${CLAUDE_CODE_EFFORT_LEVEL:-max}"

  if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ] || [ "$ANTHROPIC_AUTH_TOKEN" = "your_deepseek_api_key_here" ]; then
    fail "缺少 ANTHROPIC_AUTH_TOKEN。请编辑 $PROJECT_DIR/.env 填入 DeepSeek API Key。"
  fi
}

configure_npm_for_claude_code() {
  npm config set ignore-scripts false >/dev/null
  npm config set optional true >/dev/null
  npm config delete omit >/dev/null 2>&1 || true
}

anthropic_scope_dir() {
  printf '%s/@anthropic-ai\n' "$1"
}

has_claude_code_temp_dirs() {
  local scope_dir
  scope_dir="$(anthropic_scope_dir "$1")"
  [ -d "$scope_dir" ] || return 1
  find "$scope_dir" -maxdepth 1 -type d -name '.claude-code-*' -print -quit | grep -q .
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

install_claude_code_once() {
  local npm_root="$1"
  configure_npm_for_claude_code
  cleanup_claude_code_temp_dirs "$npm_root"
  npm install -g \
    --include=optional \
    --ignore-scripts=false \
    --foreground-scripts \
    --loglevel=info \
    "@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION"
  hash -r
}

repair_claude_code() {
  local npm_root scope_dir
  npm_root="$(npm root -g)"
  scope_dir="$(anthropic_scope_dir "$npm_root")"

  log "检测到 Claude Code 更新未完成，正在修复当前 conda 环境：$ENV_NAME"
  if install_claude_code_once "$npm_root" && is_claude_code_healthy; then
    log "修复完成，继续启动 Claude Code。"
    return
  fi

  warn "普通修复未完成，正在清理坏包后重新安装。"
  rm -rf "$scope_dir/claude-code" "$scope_dir"/.claude-code-*
  install_claude_code_once "$npm_root"
  is_claude_code_healthy || fail "Claude Code 自动修复失败。请检查网络、npm 代理或运行：cd $PROJECT_DIR && ./install.sh"
  log "修复完成，继续启动 Claude Code。"
}

acquire_repair_lock() {
  local lock_dir waited lock_pid
  lock_dir="${CONDA_PREFIX:-$HOME}/.claude-deepseek-repair.lock"
  waited=0

  while ! mkdir "$lock_dir" 2>/dev/null; do
    lock_pid=""
    if [ -f "$lock_dir/pid" ]; then
      lock_pid="$(sed -n '1p' "$lock_dir/pid" 2>/dev/null || true)"
    fi
    if [ -z "$lock_pid" ] && find "$lock_dir" -maxdepth 0 -mmin +30 2>/dev/null | grep -q .; then
      warn "发现旧的修复锁，正在清理。"
      rm -rf "$lock_dir"
      continue
    fi
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      warn "发现上次中断留下的修复锁，正在清理。"
      rm -rf "$lock_dir"
      continue
    fi
    if [ "$waited" -eq 0 ]; then
      log "另一个 claude-deepseek 正在修复 Claude Code，等待它完成。"
    fi
    sleep 5
    waited=$((waited + 5))
    [ "$waited" -lt 900 ] || fail "等待 Claude Code 修复锁超时：$lock_dir"
  done

  printf '%s\n' "$$" > "$lock_dir/pid"
  REPAIR_LOCK_DIR="$lock_dir"
}

release_repair_lock() {
  if [ -n "${REPAIR_LOCK_DIR:-}" ]; then
    rm -f "$REPAIR_LOCK_DIR/pid"
    rmdir "$REPAIR_LOCK_DIR" 2>/dev/null || true
    REPAIR_LOCK_DIR=""
  fi
}

ensure_claude_code_healthy() {
  local npm_root
  npm_root="$(npm root -g)"

  if is_claude_code_healthy && ! has_claude_code_temp_dirs "$npm_root"; then
    return
  fi

  acquire_repair_lock
  trap release_repair_lock EXIT

  if is_claude_code_healthy && ! has_claude_code_temp_dirs "$npm_root"; then
    release_repair_lock
    trap - EXIT
    return
  fi

  repair_claude_code
  release_repair_lock
  trap - EXIT
}

resolve_project_dir() {
  TARGET_PROJECT_DIR="$ORIGINAL_DIR"
  CLAUDE_ARGS=("$@")

  if [ "$#" -gt 0 ] && [ -d "$1" ]; then
    TARGET_PROJECT_DIR="$(cd -- "$1" && pwd)"
    shift
    CLAUDE_ARGS=("$@")
  fi
}

load_env_file
export_deepseek_env
resolve_project_dir "$@"
load_conda
conda activate "$ENV_NAME"
hash -r
ensure_claude_code_healthy
cd -- "$TARGET_PROJECT_DIR"
exec claude "${CLAUDE_ARGS[@]}"
