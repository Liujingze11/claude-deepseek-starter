param(
  [string]$ProjectPath
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvPath = Join-Path $ScriptDir ".env"

function Fail {
  param([string]$Message)
  Write-Host $Message -ForegroundColor Red
  exit 1
}

function Load-EnvFile {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    Fail "缺少 .env。请先双击 setup.bat 完成安装。"
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*#' -or $line -notmatch '=') {
      continue
    }
    $key, $value = $line -split '=', 2
    [Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
  }
}

function Select-ProjectFolder {
  Add-Type -AssemblyName System.Windows.Forms
  $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
  $dialog.Description = "选择要用 Claude Code 打开的项目文件夹"
  $dialog.ShowNewFolderButton = $true

  if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    return $dialog.SelectedPath
  }

  return $null
}

Load-EnvFile $EnvPath

if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_BASE_URL)) {
  $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_MODEL)) {
  $env:ANTHROPIC_MODEL = "deepseek-v4-pro[1m]"
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_DEFAULT_OPUS_MODEL)) {
  $env:ANTHROPIC_DEFAULT_OPUS_MODEL = $env:ANTHROPIC_MODEL
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_DEFAULT_SONNET_MODEL)) {
  $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $env:ANTHROPIC_MODEL
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_DEFAULT_HAIKU_MODEL)) {
  $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
}
if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_SUBAGENT_MODEL)) {
  $env:CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
}
if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CODE_EFFORT_LEVEL)) {
  $env:CLAUDE_CODE_EFFORT_LEVEL = "max"
}

if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_AUTH_TOKEN) -or $env:ANTHROPIC_AUTH_TOKEN -eq "your_deepseek_api_key_here") {
  Fail "缺少 ANTHROPIC_AUTH_TOKEN。请编辑 $EnvPath 填入 DeepSeek API Key。"
}

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
  $ProjectPath = Select-ProjectFolder
}

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
  Fail "未选择项目文件夹。"
}

if (-not (Test-Path -LiteralPath $ProjectPath)) {
  Fail "项目文件夹不存在: $ProjectPath"
}

Set-Location -LiteralPath $ProjectPath

if (-not (Get-Command "claude" -ErrorAction SilentlyContinue)) {
  Fail "找不到 claude 命令。请先双击 setup.bat 安装，或重启电脑后再试。"
}

& claude
