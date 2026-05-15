$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvPath = Join-Path $ScriptDir ".env"

function Fail {
  param([string]$Message)
  Write-Host $Message -ForegroundColor Red
  exit 1
}

if (-not (Test-Path $EnvPath)) {
  Fail "缺少 .env。请先双击 setup.bat 完成安装。"
}

foreach ($line in Get-Content -LiteralPath $EnvPath) {
  if ($line -match '^\s*#' -or $line -notmatch '=') {
    continue
  }
  $key, $value = $line -split '=', 2
  [Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
}

if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_BASE_URL)) {
  $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_MODEL)) {
  $env:ANTHROPIC_MODEL = "deepseek-v4-pro[1m]"
}
if ([string]::IsNullOrWhiteSpace($env:ANTHROPIC_AUTH_TOKEN) -or $env:ANTHROPIC_AUTH_TOKEN -eq "your_deepseek_api_key_here") {
  Fail "缺少 ANTHROPIC_AUTH_TOKEN。请编辑 $EnvPath 填入 DeepSeek API Key。"
}

$body = @{
  model = $env:ANTHROPIC_MODEL
  max_tokens = 64
  messages = @(
    @{
      role = "user"
      content = "请只回复：DeepSeek OK"
    }
  )
} | ConvertTo-Json -Depth 8

$headers = @{
  Authorization = "Bearer $($env:ANTHROPIC_AUTH_TOKEN)"
  "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri "$($env:ANTHROPIC_BASE_URL)/v1/messages" -Method Post -Headers $headers -Body $body
