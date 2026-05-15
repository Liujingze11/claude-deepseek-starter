#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  printf '\033[1;31m%s\033[0m\n' "$*" >&2
  printf '\n按回车键关闭窗口...'
  read -r _ || true
  exit 1
}

if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
else
  fail "缺少 .env。请先双击 install.command 完成安装。"
fi

ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.deepseek.com/anthropic}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-pro[1m]}"

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ] || [ "$ANTHROPIC_AUTH_TOKEN" = "your_deepseek_api_key_here" ]; then
  fail "缺少 ANTHROPIC_AUTH_TOKEN。请编辑 $PROJECT_DIR/.env 填入 DeepSeek API Key。"
fi

curl -fsS "$ANTHROPIC_BASE_URL/v1/messages" \
  -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "model": "$ANTHROPIC_MODEL",
  "max_tokens": 64,
  "messages": [
    {
      "role": "user",
      "content": "请只回复：DeepSeek OK"
    }
  ]
}
JSON

printf '\n'
printf '\n按回车键关闭窗口...'
read -r _ || true
