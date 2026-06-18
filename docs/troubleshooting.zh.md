# 故障排查

## 安装看起来卡住了

如果安装器还在输出“仍在执行”的提示，说明它仍在运行。首次安装可能需要几分钟，因为依赖会从 GitHub、conda-forge、npm、winget 或其他软件源下载。

只要窗口还在显示进度或心跳提示，请不要关闭窗口。

## Miniforge 下载失败

macOS 上如果已经安装了 Node.js 18+、npm 和 git，可以跳过 Miniforge：

```bash
cd macos
INSTALL_MODE=system ./install.command
```

如果已经安装 Homebrew，也可以让脚本先用 Homebrew 准备依赖，避免直接下载 Miniforge：

```bash
cd macos
INSTALL_MODE=brew ./install.command
```

先检查当前网络是否能访问 GitHub。如果需要代理，请先配置代理：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
```

然后重新运行安装器。

macOS 安装器默认会用 HTTP/1.1、断点续传和重试下载 Miniforge，并且默认不设置 30 分钟总时长上限。若仍然反复断开，可以显式运行：

```bash
cd macos
CURL_HTTP_VERSION=http1.1 ./install.command
```

也可以先手动下载对应架构的 Miniforge 安装包，再让安装器继续：

```bash
cd macos
MINIFORGE_INSTALLER=/path/to/Miniforge3-MacOSX-arm64.sh ./install.command
```

半离线分发时，也可以把安装包放到 `macos/vendor/` 或仓库根目录 `vendor/`，脚本会自动优先使用本地文件。

如果有可用镜像地址：

```bash
cd macos
MINIFORGE_URL=https://mirror.example.com/Miniforge3-MacOSX-arm64.sh ./install.command
```

## conda 环境创建失败

这通常表示 conda-forge 无法访问，或者网络中断。等网络稳定后重新运行安装器。已有环境会尽量复用。

## npm 安装超时

安装器会自动给 npm 配置更长的超时和重试：

```bash
npm config set fetch-timeout 1200000
npm config set fetch-retries 5
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
```

如果 npm 仍然失败，请配置 npm 代理：

```bash
npm config set proxy http://代理地址:端口
npm config set https-proxy http://代理地址:端口
```

然后重新运行安装器。

Claude Code 安装步骤会使用 `--loglevel=info --progress=true` 运行 npm，并每 10 秒输出一次心跳提示。如果 npm 没有显示百分比，只要心跳还在输出，就说明安装仍在运行。

## 安装已知可用的 Claude Code 版本

macOS：

```bash
cd macos
CLAUDE_CODE_VERSION=<已知可用版本号> ./install.command
```

Linux：

```bash
cd linux
CLAUDE_CODE_VERSION=<已知可用版本号> ./install.sh
```

Windows：

```powershell
cd windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ClaudeCodeVersion <已知可用版本号>
```

## Windows winget 问题

`winget` 来自 Microsoft Store 的“应用安装程序”。如果系统找不到 `winget`，请先从 Microsoft Store 更新或安装“应用安装程序”。如果公司禁用了 Microsoft Store，请让管理员手动安装 Git for Windows 和 Node.js LTS，然后重新运行 `windows/setup.bat`。

## `claude: command not found`，之前明明能用

Claude Code 的 npm 全局包更新中断后，可能留下临时目录并导致 `claude` 命令消失。Linux 上的 `claude-deepseek` 会在启动前检查这个问题，并自动修复专用 conda 环境。

如果自动修复仍然失败，可以手动清理这个 conda 环境里的坏包后重装：

```bash
conda activate claude-code-deepseek
rm -rf "$(npm root -g)"/@anthropic-ai/claude-code
rm -rf "$(npm root -g)"/@anthropic-ai/.claude-code-*
npm install -g --include=optional --ignore-scripts=false --foreground-scripts @anthropic-ai/claude-code
```

这个修复只会动当前 conda 环境里的 npm 全局包目录，不会删除你的项目文件、系统 Node.js 包或其他 conda 环境。

## `claude native binary not installed`

这表示 Claude Code 的 JavaScript 包壳存在，但对应平台的 native binary 没装好。常见原因是 npm optional dependency 被跳过、postinstall 没执行，或者更新中途被中断。

Linux 上可以直接重新运行 `claude-deepseek`。启动器会检查 native binary 是否还是几百字节的占位文件，如果坏了，会在 `claude-code-deepseek` 环境里自动重装 Claude Code。

手动修复命令：

```bash
conda activate claude-code-deepseek
rm -rf "$(npm root -g)"/@anthropic-ai/claude-code
rm -rf "$(npm root -g)"/@anthropic-ai/.claude-code-*
npm install -g --include=optional --ignore-scripts=false --foreground-scripts @anthropic-ai/claude-code
```
