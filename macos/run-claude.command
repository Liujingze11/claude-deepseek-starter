#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${ENV_NAME:-claude-code-deepseek}"
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
DIRECT_NPM_PREFIX="${DIRECT_NPM_PREFIX:-$HOME/.claude-deepseek/npm-global}"

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

activate_runtime() {
  case "${CLAUDE_DEEPSEEK_INSTALL_MODE:-conda}" in
    system)
      DIRECT_NPM_PREFIX="${CLAUDE_DEEPSEEK_NPM_PREFIX:-$DIRECT_NPM_PREFIX}"
      export PATH="$DIRECT_NPM_PREFIX/bin:$PATH"
      command -v claude >/dev/null 2>&1 || fail "找不到 claude。请先双击 install.command 完成安装。"
      ;;
    conda|"")
      load_conda
      conda activate "$ENV_NAME"
      ;;
    *)
      fail "未知安装模式: ${CLAUDE_DEEPSEEK_INSTALL_MODE}。请重新运行 install.command。"
      ;;
  esac
}

load_env_file() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    fail "缺少 .env。请先双击 install.command 完成安装。"
  fi

  set -a
  # shellcheck disable=SC1091
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

activate_runtime
cd "$PROJECT_PATH"
exec claude
