# Claude Code + DeepSeek Starter

一个面向普通用户的跨平台部署包：快速安装 Claude Code，并把 Claude Code 请求转发到 DeepSeek API。

支持：

- macOS：双击安装，自动安装 Miniforge 隔离环境。
- Windows：双击安装，自动准备 Git for Windows、Node.js LTS 和桌面快捷方式。
- Linux/Ubuntu：命令行一键安装，适合服务器、开发机和 WSL。

官方 Claude Code 安装要求可参考 [Anthropic Claude Code setup](https://docs.anthropic.com/zh-CN/docs/claude-code/setup)。本项目选择 npm 安装路线，并用脚本处理跨平台依赖和环境变量。

## 你需要准备什么

- 一台 macOS、Windows 10/11 或 Linux/Ubuntu 电脑。
- 一个 DeepSeek API Key。
- 能访问 GitHub、npm 和 DeepSeek API 的网络。
- Windows 用户建议使用管理员正常登录的系统账号，方便 `winget` 安装 Git 和 Node.js。

## 快速开始

先克隆或下载本仓库：

```bash
git clone https://github.com/Liujingze11/claude-deepseek-starter.git
cd claude-deepseek-starter
```

然后按你的系统选择对应目录：

| 系统 | 推荐入口 | 适合人群 |
| --- | --- | --- |
| macOS | `macos/install.command` | 不想手动装 Homebrew、Node、npm 的用户 |
| Windows | `windows/setup.bat` | 希望双击安装、桌面启动的用户 |
| Linux/Ubuntu | `linux/install.sh` | 熟悉终端、服务器、WSL 用户 |

安装过程中会要求输入 DeepSeek API Key。输入时屏幕不显示是正常的，key 只会写入本机 `.env` 文件。

## 不同系统版本怎么选

| 场景 | 推荐版本 | 说明 |
| --- | --- | --- |
| macOS Apple Silicon，M1/M2/M3/M4 | `macos/install.command` | 脚本会自动安装 arm64 Miniforge。 |
| macOS Intel | `macos/install.command` | 脚本会自动安装 x86_64 Miniforge。 |
| Windows 10/11 普通用户 | `windows/setup.bat` | 走 Git for Windows 路线，不要求用户手动打开 WSL。 |
| Windows 已经熟悉 WSL | `linux/install.sh` | 在 WSL Ubuntu 里按 Linux 方式安装。 |
| Ubuntu/Debian 桌面或服务器 | `linux/install.sh` | 脚本会尝试安装 Miniforge、Node.js、Claude Code。 |
| 其他 Linux 发行版 | 参考 `linux/install.sh` | 需要系统自带 `bash`、`curl`，包管理差异可能要手动处理。 |

## macOS 安装

1. 打开 `macos` 文件夹。
2. 双击 `install.command`。
3. 如果提示“无法打开”，右键 `install.command`，选择“打开”。
4. 按提示输入 DeepSeek API Key。
5. 安装完成后，双击桌面 `Claude Code DeepSeek`，选择你的项目文件夹。

命令行用户也可以这样启动：

```bash
cd /path/to/your/project
claude-deepseek
```

详见 [macos/README.md](macos/README.md)

## Windows 安装

1. 打开 `windows` 文件夹。
2. 双击 `setup.bat`。
3. 按提示输入 DeepSeek API Key。
4. 安装完成后，双击桌面 `Claude Code DeepSeek`，选择你的项目文件夹。

PowerShell 用户也可以这样启动：

```powershell
claude-deepseek C:\Users\me\projects\my-project
```

详见 [windows/README.md](windows/README.md)

## Linux/Ubuntu 安装

```bash
cd linux
chmod +x install.sh run-claude.sh verify-deepseek.sh
./install.sh
```

以后进入任意项目目录运行：

```bash
cd ~/projects/my-project
claude-deepseek
```

详见 [linux/README.md](linux/README.md)

## 验证 DeepSeek 连接

macOS：

```bash
cd macos
./verify-deepseek.command
```

Windows：

```powershell
cd windows
powershell -ExecutionPolicy Bypass -File .\verify-deepseek.ps1
```

Linux/Ubuntu：

```bash
cd linux
./verify-deepseek.sh
```

看到返回内容里包含 `DeepSeek OK`，说明 API 已连通。

## 配置文件

每个平台目录下都有自己的 `.env.example`。首次安装时脚本会复制为 `.env`，并写入你的 DeepSeek API Key。

常用配置：

```text
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=sk-你的DeepSeekKey
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
CLAUDE_CODE_EFFORT_LEVEL=max
```

需要换 key 或换模型时，编辑对应平台目录下的 `.env` 即可。

## 仓库结构

```text
.
├── README.md
├── docs/
│   ├── publish-checklist.md
│   └── troubleshooting.md
├── linux/
│   ├── install.sh
│   ├── run-claude.sh
│   └── verify-deepseek.sh
├── macos/
│   ├── install.command
│   ├── run-claude.command
│   └── verify-deepseek.command
└── windows/
    ├── setup.bat
    ├── install.ps1
    ├── run-claude.ps1
    └── verify-deepseek.ps1
```


## Claude Code 版本兼容说明

Claude Code 由 Anthropic 频繁更新，部分新版会引入变更导致 DeepSeek 的 Anthropic 兼容接口暂时不可用。遇到这种情况时，**降级到上一个可用的 Claude Code 版本**即可恢复使用。

macOS / Linux：

```bash
conda activate claude-code-deepseek
npm install -g @anthropic-ai/claude-code@已知可用版本号
```

Windows（PowerShell）：

```powershell
npm install -g @anthropic-ai/claude-code@已知可用版本号
```

降级后功能恢复正常。待 DeepSeek 完成兼容适配、确认新版可用后，再运行对应平台安装脚本升级回最新版即可。本仓库 README 会尽量跟进当前推荐的可用版本号。


## 常见问题

### 1. 输入 API Key 时为什么看不到字符？

正常。脚本使用隐藏输入，避免 key 出现在屏幕上。粘贴后直接按回车即可。

### 2. 安装完成后提示 `claude-deepseek: command not found`

macOS/Linux 通常是 `~/.local/bin` 还没有进入 PATH。

zsh 用户运行：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

bash 用户运行：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Windows 用户关闭当前 PowerShell 或安装窗口，重新打开后再试。如果仍然不行，重启电脑。

### 3. macOS 提示“无法打开 install.command”

这是 macOS 对非 App Store 脚本的安全提示。右键 `install.command`，选择“打开”，再点一次“打开”。

如果仍然打不开，可以在终端里运行：

```bash
cd macos
chmod +x install.command run-claude.command verify-deepseek.command
./install.command
```

### 4. Windows 双击 `setup.bat` 一闪而过

用 PowerShell 手动运行，能看到完整报错：

```powershell
cd windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

常见原因是系统没有 `winget`，或者 Git/Node 安装后 PATH 还没刷新。先重启电脑再运行一次。

### 5. Windows 提示找不到 `winget`

`winget` 来自 Microsoft Store 的“应用安装程序”。可以先从 Microsoft Store 更新或安装“应用安装程序”。

如果公司电脑禁用了 Microsoft Store，可以让 IT 先安装：

- Git for Windows
- Node.js LTS，要求 Node.js 18 或更高版本

装好后重新双击 `setup.bat`。

### 6. Windows 应该选 Git for Windows 还是 WSL？

普通用户选 `windows/setup.bat`，它走 Git for Windows 路线，双击即可。

开发者如果已经日常使用 WSL，可以进入 WSL Ubuntu 后使用 Linux 版本：

```bash
cd linux
./install.sh
```

不要在 Windows PowerShell 里直接运行 Linux 脚本。

### 7. Linux 提示缺少 `curl`

Ubuntu/Debian 先安装 curl：

```bash
sudo apt-get update
sudo apt-get install -y curl
```

没有 sudo 权限时，需要管理员先安装。

### 8. conda 环境创建失败怎么办？

优先检查网络是否能访问 GitHub 和 conda-forge。公司网络可能需要代理：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
```

然后重新运行安装脚本。macOS/Linux 的环境名默认是 `claude-code-deepseek`，重复安装会复用已有环境。

### 9. npm 安装 Claude Code 失败

通常是 npm 网络问题。可以先配置 npm 代理：

```bash
npm config set proxy http://代理地址:端口
npm config set https-proxy http://代理地址:端口
```

然后重新运行安装脚本。

### 10. `verify` 脚本没有返回 `DeepSeek OK`

按顺序检查：

1. 对应平台目录下是否已经生成 `.env`。
2. `.env` 里的 `ANTHROPIC_AUTH_TOKEN` 是否已经替换成真实 DeepSeek API Key。
3. `ANTHROPIC_BASE_URL` 是否是 `https://api.deepseek.com/anthropic`。
4. 当前网络是否能访问 DeepSeek API。
5. API Key 是否有额度或权限。

### 11. 如何更换 DeepSeek API Key？

编辑对应平台目录下的 `.env`：

```text
ANTHROPIC_AUTH_TOKEN=sk-你的新key
```

保存后重新运行 `claude-deepseek` 即可。

### 12. 如何更换模型版本？

编辑对应平台目录下的 `.env`：

```text
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
```

如果 DeepSeek 后续调整模型名称，只需要改这里，不需要改脚本。

### 13. 如何升级 Claude Code？

重新运行对应平台安装脚本即可：

- macOS：双击 `macos/install.command`
- Windows：双击 `windows/setup.bat`
- Linux：进入 `linux` 后运行 `./install.sh`

脚本会复用已有配置，并执行 Claude Code 的更新安装。

### 14. 如何卸载？

macOS/Linux：

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
```

macOS 还可以删除桌面的 `Claude Code DeepSeek.command`。

Windows：

- 删除 `%USERPROFILE%\bin\claude-deepseek.cmd`
- 删除桌面 `Claude Code DeepSeek`
- 删除本项目文件夹

如果你只是不想继续使用 DeepSeek，删除对应目录下的 `.env` 即可。
