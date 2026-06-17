#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/macos/install.command"
RUN_CLAUDE_SCRIPT="$REPO_ROOT/macos/run-claude.command"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file"; then
    printf 'Expected to find: %s\n' "$expected" >&2
    printf 'Actual output:\n' >&2
    cat "$file" >&2
    fail "missing expected text"
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$file"; then
    printf 'Did not expect to find: %s\n' "$unexpected" >&2
    printf 'Actual output:\n' >&2
    cat "$file" >&2
    fail "found unexpected text"
  fi
}

assert_file_absent() {
  local file="$1"
  [ ! -e "$file" ] || fail "expected file to be absent: $file"
}

source_install_functions() {
  local partial="$TMP_DIR/install-functions.sh"
  sed '/^main "\$@"/,$d' "$INSTALL_SCRIPT" > "$partial"
  # shellcheck disable=SC1090
  source "$partial"
}

run_install_snippet() {
  local snippet="$1"
  local stdout="$2"
  local stderr="$3"
  local script="$TMP_DIR/snippet-$RANDOM.sh"

  cat > "$script" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
source "$TMP_DIR/install-functions.sh"
$snippet
EOF
  bash "$script" >"$stdout" 2>"$stderr" </dev/null
}

test_run_with_heartbeat_requires_a_command() {
  source_install_functions

  local stdout="$TMP_DIR/heartbeat-no-command.out"
  local stderr="$TMP_DIR/heartbeat-no-command.err"
  set +e
  run_install_snippet 'run_with_heartbeat' "$stdout" "$stderr"
  local status="$?"
  set -e

  [ "$status" -ne 0 ] || fail "run_with_heartbeat without a command should fail"
  assert_contains "$stderr" "run_with_heartbeat 缺少要执行的命令: 任务"
  assert_not_contains "$stderr" "unbound variable"
}

test_run_with_heartbeat_interval_requires_a_value() {
  source_install_functions

  local stdout="$TMP_DIR/heartbeat-no-interval.out"
  local stderr="$TMP_DIR/heartbeat-no-interval.err"
  set +e
  run_install_snippet 'run_with_heartbeat --interval' "$stdout" "$stderr"
  local status="$?"
  set -e

  [ "$status" -ne 0 ] || fail "run_with_heartbeat --interval without a value should fail"
  assert_contains "$stderr" "run_with_heartbeat 缺少 --interval 秒数"
  assert_not_contains "$stderr" "unbound variable"
}

test_run_with_heartbeat_prints_label_before_chinese_punctuation() {
  source_install_functions

  local stdout="$TMP_DIR/heartbeat-label.out"
  local stderr="$TMP_DIR/heartbeat-label.err"
  set +e
  run_install_snippet 'run_with_heartbeat --interval 1 "下载 Miniforge" sleep 2' "$stdout" "$stderr"
  local status="$?"
  set -e

  [ "$status" -eq 0 ] || fail "run_with_heartbeat should preserve labels before Chinese punctuation"
  assert_contains "$stdout" "仍在执行：下载 Miniforge。"
  assert_not_contains "$stderr" "unbound variable"
}

test_preflight_reports_macos_runtime_details() {
  source_install_functions

  local fake_bin="$TMP_DIR/preflight-bin"
  local stdout="$TMP_DIR/preflight.out"
  local stderr="$TMP_DIR/preflight.err"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -s) printf '%s\n' Darwin ;;
  -m) printf '%s\n' arm64 ;;
  *) /usr/bin/uname "$@" ;;
esac
EOF
  cat > "$fake_bin/sw_vers" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-productVersion" ]; then
  printf '%s\n' 13.6.7
fi
EOF
  cat > "$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  printf '%s\n' 'curl 8.1.2 test'
  exit 0
fi
if [ "${1:-}" = "--help" ]; then
  printf '%s\n' '--retry-all-errors'
  exit 0
fi
exit 0
EOF
  chmod +x "$fake_bin/uname" "$fake_bin/sw_vers" "$fake_bin/curl"

  PATH="$fake_bin:$PATH" preflight_macos >"$stdout" 2>"$stderr"

  assert_contains "$stdout" "检测到 macOS 13.6.7，架构 arm64"
  assert_contains "$stdout" "Bash 版本:"
  assert_contains "$stdout" "curl 版本: curl 8.1.2 test"
  assert_not_contains "$stderr" "unbound variable"
}

test_download_file_uses_stable_resume_curl_options() {
  source_install_functions

  local fake_bin="$TMP_DIR/bin"
  local args_file="$TMP_DIR/curl.args"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/curl" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "--help" ]; then
  printf '%s\n' '--retry-all-errors'
  exit 0
fi
printf '%s\n' "\$@" > "$args_file"
exit 0
EOF
  chmod +x "$fake_bin/curl"

  PATH="$fake_bin:$PATH" CURL_HTTP_VERSION=http1.1 download_file "https://example.test/Miniforge.sh" "$TMP_DIR/Miniforge.sh"

  assert_contains "$args_file" "--http1.1"
  assert_contains "$args_file" "--continue-at"
  assert_contains "$args_file" "--speed-limit"
  assert_contains "$args_file" "--speed-time"
  assert_contains "$args_file" "--retry-all-errors"
  assert_contains "$args_file" "https://example.test/Miniforge.sh"
}

test_miniforge_url_overrides_default_download_url() {
  source_install_functions

  local stdout="$TMP_DIR/miniforge-url.out"
  local stderr="$TMP_DIR/miniforge-url.err"
  local url_file="$TMP_DIR/miniforge-url.txt"
  local conda_home="$TMP_DIR/url-conda"
  local snippet
  snippet='
CONDA_HOME="'"$conda_home"'"
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
MINIFORGE_URL="https://mirror.example.test/custom-miniforge.sh"
detect_miniforge_installer() { printf "%s\n" "Miniforge3-MacOSX-arm64.sh"; }
download_file() {
  printf "%s\n" "$1" > "'"$url_file"'"
  printf "%s\n" "fake installer" > "$2"
}
run_with_heartbeat() {
  local label="${1:-}"
  shift
  case "$label" in
    "下载 Miniforge") "$@" ;;
    "安装 Miniforge 到 $CONDA_HOME") return 0 ;;
    *) "$@" ;;
  esac
}
ensure_conda
'

  run_install_snippet "$snippet" "$stdout" "$stderr"

  assert_contains "$url_file" "https://mirror.example.test/custom-miniforge.sh"
  assert_not_contains "$stderr" "unbound variable"
}

test_local_miniforge_installer_skips_download() {
  source_install_functions

  local stdout="$TMP_DIR/local-installer.out"
  local stderr="$TMP_DIR/local-installer.err"
  local conda_home="$TMP_DIR/local-conda"
  local local_installer="$TMP_DIR/local-Miniforge3-MacOSX-arm64.sh"
  local download_marker="$TMP_DIR/download-called"
  printf '%s\n' '#!/usr/bin/env bash' > "$local_installer"
  local snippet
  snippet='
CONDA_HOME="'"$conda_home"'"
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
MINIFORGE_INSTALLER="'"$local_installer"'"
detect_miniforge_installer() { printf "%s\n" "Miniforge3-MacOSX-arm64.sh"; }
download_file() {
  : > "'"$download_marker"'"
}
run_with_heartbeat() {
  local label="${1:-}"
  shift
  case "$label" in
    "安装 Miniforge 到 $CONDA_HOME")
      [ "${1:-}" = "bash" ] || return 1
      [ "${2:-}" = "$MINIFORGE_INSTALLER" ] || return 1
      return 0
      ;;
    *) "$@" ;;
  esac
}
ensure_conda
'

  run_install_snippet "$snippet" "$stdout" "$stderr"

  assert_contains "$stdout" "使用本地 Miniforge 安装包: $local_installer"
  assert_file_absent "$download_marker"
  assert_not_contains "$stderr" "unbound variable"
}

test_auto_mode_skips_miniforge_when_system_runtime_is_ready() {
  source_install_functions

  local fake_bin="$TMP_DIR/system-runtime-bin"
  local stdout="$TMP_DIR/system-runtime.out"
  local stderr="$TMP_DIR/system-runtime.err"
  local prefix="$TMP_DIR/system-prefix"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/node" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'v20.11.1'
EOF
  cat > "$fake_bin/npm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '10.2.4'
EOF
  cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'git version 2.44.0'
EOF
  chmod +x "$fake_bin/node" "$fake_bin/npm" "$fake_bin/git"

  local snippet
  snippet='
PATH="'"$fake_bin"':/usr/bin:/bin:/usr/sbin:/sbin"
DIRECT_NPM_PREFIX="'"$prefix"'"
INSTALL_MODE=auto
prepare_runtime
printf "backend=%s\n" "$INSTALL_BACKEND"
'

  run_install_snippet "$snippet" "$stdout" "$stderr"

  assert_contains "$stdout" "未检测到 conda，但检测到可用系统 Node.js/npm/git，将跳过 Miniforge"
  assert_contains "$stdout" "backend=system"
  [ -d "$prefix/bin" ] || fail "system npm prefix bin directory should be created"
  assert_not_contains "$stderr" "unbound variable"
}

test_install_claude_code_system_mode_uses_user_npm_prefix() {
  source_install_functions

  local fake_bin="$TMP_DIR/system-install-bin"
  local npm_args="$TMP_DIR/system-install-npm.args"
  local stdout="$TMP_DIR/system-install.out"
  local stderr="$TMP_DIR/system-install.err"
  local prefix="$TMP_DIR/system-install-prefix"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/npm" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "$npm_args"
exit 0
EOF
  cat > "$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'claude 1.0.0'
EOF
  chmod +x "$fake_bin/npm" "$fake_bin/claude"

  local snippet
  snippet='
PATH="'"$fake_bin"':/usr/bin:/bin:/usr/sbin:/sbin"
INSTALL_BACKEND=system
DIRECT_NPM_PREFIX="'"$prefix"'"
CLAUDE_CODE_VERSION=latest
install_claude_code
'

  run_install_snippet "$snippet" "$stdout" "$stderr"

  assert_contains "$npm_args" "--prefix"
  assert_contains "$npm_args" "$prefix"
  assert_contains "$npm_args" "@anthropic-ai/claude-code@latest"
  assert_not_contains "$stderr" "unbound variable"
}

test_write_env_file_records_system_install_mode() {
  source_install_functions

  local env_file="$PROJECT_DIR/.env"
  local prefix="$TMP_DIR/env-system-prefix"
  cp "$REPO_ROOT/.env.example" "$env_file"
  printf '%s\n' 'ANTHROPIC_AUTH_TOKEN=sk-test' >> "$env_file"

  INSTALL_BACKEND=system
  DIRECT_NPM_PREFIX="$prefix"
  write_env_file

  assert_contains "$env_file" "CLAUDE_DEEPSEEK_INSTALL_MODE=system"
  assert_contains "$env_file" "CLAUDE_DEEPSEEK_NPM_PREFIX=$prefix"
}

test_run_claude_system_mode_uses_npm_prefix_without_conda() {
  local launcher_dir="$TMP_DIR/run-claude-system"
  local project_dir="$TMP_DIR/project"
  local prefix="$TMP_DIR/run-claude-prefix"
  local marker="$TMP_DIR/run-claude-marker"
  local stdout="$TMP_DIR/run-claude.out"
  local stderr="$TMP_DIR/run-claude.err"
  mkdir -p "$launcher_dir" "$project_dir" "$prefix/bin"
  cp "$RUN_CLAUDE_SCRIPT" "$launcher_dir/run-claude.command"
  cat > "$launcher_dir/.env" <<EOF
ANTHROPIC_AUTH_TOKEN=sk-test
CLAUDE_DEEPSEEK_INSTALL_MODE=system
CLAUDE_DEEPSEEK_NPM_PREFIX=$prefix
EOF
  cat > "$prefix/bin/claude" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$PWD" > "$marker"
EOF
  chmod +x "$launcher_dir/run-claude.command" "$prefix/bin/claude"

  /bin/bash "$launcher_dir/run-claude.command" "$project_dir" >"$stdout" 2>"$stderr"

  assert_contains "$marker" "$project_dir"
  assert_not_contains "$stderr" "找不到 conda"
  assert_not_contains "$stderr" "unbound variable"
}

test_invalid_curl_http_version_warns_without_becoming_curl_arg() {
  source_install_functions

  local fake_bin="$TMP_DIR/invalid-http-bin"
  local args_file="$TMP_DIR/curl-invalid-http.args"
  local stdout="$TMP_DIR/curl-invalid-http.out"
  local stderr="$TMP_DIR/curl-invalid-http.err"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/curl" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "--help" ]; then
  exit 0
fi
printf '%s\n' "\$@" > "$args_file"
exit 0
EOF
  chmod +x "$fake_bin/curl"

  local snippet
  snippet='
PATH="'"$fake_bin"':$PATH"
CURL_HTTP_VERSION=bogus
download_file "https://example.test/Miniforge.sh" "'"$TMP_DIR"'/Miniforge-invalid.sh"
'

  run_install_snippet "$snippet" "$stdout" "$stderr"

  assert_contains "$stderr" "未知 CURL_HTTP_VERSION=bogus"
  assert_not_contains "$args_file" "未知 CURL_HTTP_VERSION=bogus"
  assert_contains "$args_file" "--continue-at"
}

test_detect_miniforge_installer_uses_macos_architecture() {
  source_install_functions

  local fake_bin="$TMP_DIR/uname-bin"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-m" ]; then
  printf '%s\n' "$FAKE_UNAME_MACHINE"
else
  /usr/bin/uname "$@"
fi
EOF
  chmod +x "$fake_bin/uname"

  local arm intel
  arm="$(PATH="$fake_bin:$PATH" FAKE_UNAME_MACHINE=arm64 detect_miniforge_installer)"
  intel="$(PATH="$fake_bin:$PATH" FAKE_UNAME_MACHINE=x86_64 detect_miniforge_installer)"

  [ "$arm" = "Miniforge3-MacOSX-arm64.sh" ] || fail "unexpected arm64 installer: $arm"
  [ "$intel" = "Miniforge3-MacOSX-x86_64.sh" ] || fail "unexpected x86_64 installer: $intel"
}

test_ensure_conda_explains_download_failures() {
  source_install_functions

  local stdout="$TMP_DIR/ensure-conda.out"
  local stderr="$TMP_DIR/ensure-conda.err"
  local conda_home="$TMP_DIR/missing-conda"
  local snippet
  snippet='
CONDA_HOME="'"$conda_home"'"
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
detect_miniforge_installer() { printf "%s\n" "Miniforge3-MacOSX-arm64.sh"; }
run_with_heartbeat() {
  case "${1:-}" in
    "下载 Miniforge") return 92 ;;
    *) return 0 ;;
  esac
}
ensure_conda
'

  set +e
  run_install_snippet "$snippet" "$stdout" "$stderr"
  local status="$?"
  set -e

  [ "$status" -ne 0 ] || fail "ensure_conda should fail when Miniforge download fails"
  assert_contains "$stderr" "Miniforge 下载失败。请检查网络或代理后重试。可尝试："
  assert_contains "$stderr" "CURL_HTTP_VERSION=http1.1 ./install.command"
}

test_run_with_heartbeat_requires_a_command
test_run_with_heartbeat_interval_requires_a_value
test_run_with_heartbeat_prints_label_before_chinese_punctuation
test_preflight_reports_macos_runtime_details
test_download_file_uses_stable_resume_curl_options
test_miniforge_url_overrides_default_download_url
test_local_miniforge_installer_skips_download
test_auto_mode_skips_miniforge_when_system_runtime_is_ready
test_install_claude_code_system_mode_uses_user_npm_prefix
test_write_env_file_records_system_install_mode
test_run_claude_system_mode_uses_npm_prefix_without_conda
test_invalid_curl_http_version_warns_without_becoming_curl_arg
test_detect_miniforge_installer_uses_macos_architecture
test_ensure_conda_explains_download_failures

printf 'ok - macos install script tests passed\n'
