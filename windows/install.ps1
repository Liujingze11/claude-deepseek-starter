param(
  [string]$InstallDir = $PSScriptRoot,
  [string]$LauncherName = "claude-deepseek",
  [string]$ClaudeCodeVersion = $(if ($env:CLAUDE_CODE_VERSION) { $env:CLAUDE_CODE_VERSION } else { "latest" }),
  [int]$NpmFetchTimeoutMs = $(if ($env:NPM_FETCH_TIMEOUT_MS) { [int]$env:NPM_FETCH_TIMEOUT_MS } else { 1200000 }),
  [int]$NpmFetchRetries = $(if ($env:NPM_FETCH_RETRIES) { [int]$env:NPM_FETCH_RETRIES } else { 5 }),
  [int]$NpmFetchRetryMinTimeoutMs = $(if ($env:NPM_FETCH_RETRY_MINTIMEOUT_MS) { [int]$env:NPM_FETCH_RETRY_MINTIMEOUT_MS } else { 20000 }),
  [int]$NpmFetchRetryMaxTimeoutMs = $(if ($env:NPM_FETCH_RETRY_MAXTIMEOUT_MS) { [int]$env:NPM_FETCH_RETRY_MAXTIMEOUT_MS } else { 120000 }),
  [int]$HeartbeatIntervalSeconds = $(if ($env:HEARTBEAT_INTERVAL_SECONDS) { [int]$env:HEARTBEAT_INTERVAL_SECONDS } else { 30 })
)

$ErrorActionPreference = "Stop"
$TotalSteps = 7
$CurrentStep = 0

function Write-Step {
  param([string]$Message)
  Write-Host "[setup] $Message" -ForegroundColor Cyan
}

function Write-Warn {
  param([string]$Message)
  Write-Host "[setup:warn] $Message" -ForegroundColor Yellow
}

function Write-SetupStep {
  param([string]$Message)
  $script:CurrentStep += 1
  Write-Step "[$script:CurrentStep/$script:TotalSteps] $Message"
}

function Format-Elapsed {
  param([TimeSpan]$Elapsed)
  return "{0:00}:{1:00}" -f [Math]::Floor($Elapsed.TotalMinutes), $Elapsed.Seconds
}

function Invoke-WithHeartbeat {
  param(
    [string]$Label,
    [string]$FilePath,
    [string[]]$ArgumentList
  )

  $resolvedCommand = Get-Command $FilePath -ErrorAction SilentlyContinue
  if ($resolvedCommand) {
    $FilePath = $resolvedCommand.Source
  }

  $start = Get-Date
  $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru

  while (-not $process.HasExited) {
    Start-Sleep -Seconds $HeartbeatIntervalSeconds
    if (-not $process.HasExited) {
      $elapsed = Format-Elapsed -Elapsed ((Get-Date) - $start)
      Write-Step "仍在执行：$Label。已用时：$elapsed。请不要关闭窗口。"
    }
  }

  if ($process.ExitCode -ne 0) {
    Fail "$Label 失败，退出码：$($process.ExitCode)"
  }
}

function Invoke-NpmConfig {
  param(
    [string]$Name,
    [string]$Value
  )

  & npm config set $Name $Value
  if ($LASTEXITCODE -ne 0) {
    Fail "npm config set $Name 失败"
  }
}

function Configure-NpmNetwork {
  Invoke-NpmConfig -Name "fetch-timeout" -Value "$NpmFetchTimeoutMs"
  Invoke-NpmConfig -Name "fetch-retries" -Value "$NpmFetchRetries"
  Invoke-NpmConfig -Name "fetch-retry-mintimeout" -Value "$NpmFetchRetryMinTimeoutMs"
  Invoke-NpmConfig -Name "fetch-retry-maxtimeout" -Value "$NpmFetchRetryMaxTimeoutMs"
}

function Fail {
  param([string]$Message)
  Write-Host "[setup:error] $Message" -ForegroundColor Red
  exit 1
}

function Test-Command {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machinePath;$userPath"
}

function Test-DictKey {
  param(
    [System.Collections.IDictionary]$Dictionary,
    [string]$Key
  )

  return $Dictionary.Contains($Key)
}

function Ensure-Windows {
  if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
    Fail "此脚本面向 Windows。"
  }
}

function Ensure-Winget {
  if (-not (Test-Command "winget")) {
    Fail "未检测到 winget。请先从 Microsoft Store 安装“应用安装程序”，或手动安装 Git for Windows 和 Node.js 18+ 后重新运行。"
  }
}

function Get-NodeMajor {
  if (-not (Test-Command "node")) {
    return 0
  }

  $version = (& node --version 2>$null).Trim()
  if ($version -match '^v?(\d+)') {
    return [int]$Matches[1]
  }
  return 0
}

function Ensure-Node {
  $major = Get-NodeMajor
  if ($major -ge 18 -and (Test-Command "npm")) {
    Write-Step "检测到 Node.js: $(& node --version)"
    return
  }

  Ensure-Winget
  Write-Step "安装 Node.js LTS"
  Invoke-WithHeartbeat -Label "安装 Node.js LTS" -FilePath "winget" -ArgumentList @(
    "install",
    "--id", "OpenJS.NodeJS.LTS",
    "--exact",
    "--accept-source-agreements",
    "--accept-package-agreements"
  )
  Refresh-Path

  $major = Get-NodeMajor
  if ($major -lt 18 -or -not (Test-Command "npm")) {
    Fail "Node.js 安装后仍不可用。请重启电脑后再运行 setup.bat。"
  }
}

function Find-GitBash {
  $candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LocalAppData\Programs\Git\bin\bash.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  $bash = Get-Command "bash.exe" -ErrorAction SilentlyContinue
  if ($bash) {
    return $bash.Source
  }

  return $null
}

function Ensure-GitBash {
  $bashPath = Find-GitBash
  if ($bashPath) {
    Write-Step "检测到 Git Bash: $bashPath"
    return $bashPath
  }

  Ensure-Winget
  Write-Step "安装 Git for Windows"
  Invoke-WithHeartbeat -Label "安装 Git for Windows" -FilePath "winget" -ArgumentList @(
    "install",
    "--id", "Git.Git",
    "--exact",
    "--accept-source-agreements",
    "--accept-package-agreements"
  )
  Refresh-Path

  $bashPath = Find-GitBash
  if (-not $bashPath) {
    Fail "Git for Windows 安装后仍找不到 bash.exe。请重启电脑后再运行 setup.bat。"
  }

  return $bashPath
}

function Install-ClaudeCode {
  Write-Step "安装/更新 Claude Code，版本：$ClaudeCodeVersion"
  Invoke-WithHeartbeat -Label "安装 Claude Code $ClaudeCodeVersion" -FilePath "npm" -ArgumentList @(
    "install",
    "-g",
    "@anthropic-ai/claude-code@$ClaudeCodeVersion"
  )
  Ensure-NpmGlobalPath

  if (-not (Test-Command "claude")) {
    Refresh-Path
  }

  if (-not (Test-Command "claude")) {
    Write-Warn "暂时找不到 claude 命令，可能需要打开新终端或重启电脑后生效。"
    return
  }

  & claude --version
}

function Ensure-NpmGlobalPath {
  if (-not (Test-Command "npm")) {
    return
  }

  $npmPrefix = (& npm config get prefix 2>$null).Trim()
  if ([string]::IsNullOrWhiteSpace($npmPrefix) -or $npmPrefix -eq "undefined") {
    return
  }

  Add-UserPath $npmPrefix
}

function Read-EnvFile {
  param([string]$Path)

  $values = [ordered]@{}
  if (-not (Test-Path $Path)) {
    return $values
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*#' -or $line -notmatch '=') {
      continue
    }
    $key, $value = $line -split '=', 2
    $values[$key.Trim()] = $value.Trim()
  }
  return $values
}

function Write-EnvFile {
  param(
    [string]$Path,
    [System.Collections.IDictionary]$Values
  )

  $orderedKeys = @(
    "ANTHROPIC_BASE_URL",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
    "CLAUDE_CODE_SUBAGENT_MODEL",
    "CLAUDE_CODE_EFFORT_LEVEL",
    "CLAUDE_CODE_GIT_BASH_PATH"
  )

  $lines = New-Object System.Collections.Generic.List[string]
  foreach ($key in $orderedKeys) {
    if (Test-DictKey -Dictionary $Values -Key $key) {
      $lines.Add("$key=$($Values[$key])")
    }
  }

  foreach ($key in $Values.Keys) {
    if ($orderedKeys -notcontains $key) {
      $lines.Add("$key=$($Values[$key])")
    }
  }

  Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

function ConvertFrom-SecureStringPlainText {
  param([securestring]$SecureValue)

  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Ensure-Env {
  param([string]$GitBashPath)

  $envPath = Join-Path $InstallDir ".env"
  $values = Read-EnvFile $envPath

  $defaults = @{
    ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
    ANTHROPIC_AUTH_TOKEN = "your_deepseek_api_key_here"
    ANTHROPIC_MODEL = "deepseek-v4-pro[1m]"
    ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro[1m]"
    ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]"
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
    CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
    CLAUDE_CODE_EFFORT_LEVEL = "max"
    CLAUDE_CODE_GIT_BASH_PATH = $GitBashPath
  }

  foreach ($key in $defaults.Keys) {
    if (-not (Test-DictKey -Dictionary $values -Key $key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
      $values[$key] = $defaults[$key]
    }
  }

  if ($values["ANTHROPIC_AUTH_TOKEN"] -eq "your_deepseek_api_key_here" -or $values["ANTHROPIC_AUTH_TOKEN"] -notmatch '^sk-') {
    Write-Host ""
    Write-Host "请输入 DeepSeek API Key（输入时不显示；可直接回车稍后手动编辑 .env）：" -NoNewline
    $secureKey = Read-Host -AsSecureString
    $apiKey = ConvertFrom-SecureStringPlainText $secureKey
    if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
      $values["ANTHROPIC_AUTH_TOKEN"] = $apiKey.Trim()
      Write-Step "DeepSeek API Key 已写入 .env"
    } else {
      Write-Warn "已跳过 API Key 写入；稍后编辑 $envPath"
    }
  } else {
    Write-Step ".env 已配置 DeepSeek API Key"
  }

  Write-EnvFile -Path $envPath -Values $values
}

function Add-UserPath {
  param([string]$Directory)

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($userPath) {
    $parts = $userPath -split ';' | Where-Object { $_ }
  }

  if ($parts -contains $Directory) {
    return
  }

  $newPath = (@($parts) + $Directory) -join ';'
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  Refresh-Path
  Write-Step "已加入用户 PATH: $Directory"
}

function Install-Launcher {
  $userBin = Join-Path $env:USERPROFILE "bin"
  New-Item -ItemType Directory -Force -Path $userBin | Out-Null

  $target = Join-Path $userBin "$LauncherName.cmd"
  $runner = Join-Path $InstallDir "run-claude.ps1"

  $cmd = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$runner" %*
"@
  Set-Content -LiteralPath $target -Value $cmd -Encoding ASCII
  Add-UserPath $userBin
  Write-Step "已创建启动命令: $target"

  $desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Claude Code DeepSeek.lnk"
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($desktopShortcut)
  $shortcut.TargetPath = "powershell.exe"
  $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$runner`""
  $shortcut.WorkingDirectory = $env:USERPROFILE
  $shortcut.WindowStyle = 1
  $icoPath = Join-Path $InstallDir "icons\launcher.ico"
  if (Test-Path $icoPath) {
    $shortcut.IconLocation = $icoPath
  }
  $shortcut.Save()
  Write-Step "已创建桌面快捷方式: $desktopShortcut"
}

Write-SetupStep "检查 Windows 环境"
Ensure-Windows
$InstallDir = (Resolve-Path -LiteralPath $InstallDir).Path
Set-Location $InstallDir

Write-SetupStep "检查或安装 Git for Windows"
$gitBashPath = Ensure-GitBash

Write-SetupStep "检查或安装 Node.js LTS"
Ensure-Node

Write-SetupStep "配置 npm 网络超时和重试"
Configure-NpmNetwork

Write-SetupStep "安装 Claude Code 版本: $ClaudeCodeVersion"
Install-ClaudeCode

Write-SetupStep "写入 DeepSeek 配置"
Ensure-Env -GitBashPath $gitBashPath

Write-SetupStep "创建命令和桌面快捷方式"
Install-Launcher

Write-Host ""
Write-Step "完成。以后可以双击桌面“Claude Code DeepSeek”，或在项目目录运行：claude-deepseek"
