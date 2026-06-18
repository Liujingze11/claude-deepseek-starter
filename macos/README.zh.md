# Claude Code + DeepSeek macOS

[English](README.md) · 中文版

给公司 Mac 用户使用的一键安装包：双击安装 Claude Code，并接入 DeepSeek API。

安装器会自动选择安装方式：如果系统已有可用的 Node.js、npm 和 git，就跳过 Miniforge；如果有 Homebrew，会优先用 Homebrew 准备依赖；最后才使用 Miniforge + conda 隔离环境。不要求提前安装 Homebrew、Node.js 或 npm。

## 安装

1. 下载并解压这个文件夹。
2. 双击 `install.command`。
3. 如果 macOS 提示"无法打开"，右键 `install.command`，选择"打开"，再点"打开"。
4. 按提示输入 DeepSeek API Key。
5. 安装完成后，双击桌面的 `Claude Code DeepSeek`。
6. 在弹出的窗口里选择要操作的项目文件夹。

## 安装过程中会看到什么

安装器会显示步骤编号，并在耗时较长的步骤中输出提示。首次安装可能需要几分钟，因为可能需要下载 Miniforge、conda 软件包、npm 软件包和 Claude Code。

开始安装时，脚本会先检测 macOS 版本、CPU 架构、Bash 版本、curl 版本和系统 Node.js/npm/git。如果系统工具可用，会直接使用系统 Node.js，并把 Claude Code 安装到用户目录 `~/.claude-deepseek/npm-global`；如果系统缺少依赖但有 Homebrew，会用 Homebrew 安装 Node.js/git；否则自动选择 Apple Silicon 或 Intel 对应的 Miniforge 安装包。

Claude Code 安装步骤会使用 `--loglevel=info --progress=true` 运行 npm，并每 10 秒输出一次心跳提示。如果看到类似“仍在执行：安装 Claude Code”的提示，说明安装器还在运行。只要这些提示还在出现，请不要关闭窗口。

## Miniforge 下载慢或反复断开

如果系统已有可用的 Node.js、npm 和 git，安装器会自动跳过 Miniforge。如果你想强制跳过 Miniforge：

```bash
cd macos
INSTALL_MODE=system ./install.command
```

如果系统没有这些工具，安装器会使用 HTTP/1.1、断点续传和重试来下载 Miniforge。默认不设置 30 分钟这类总时长上限，只在长时间低速或断网时重试。如果 GitHub Release 下载仍然很慢，可以先配置代理再运行：

```bash
cd macos
export HTTPS_PROXY=http://127.0.0.1:7890
export HTTP_PROXY=http://127.0.0.1:7890
CURL_HTTP_VERSION=http1.1 ./install.command
```

也可以先用浏览器或下载器手动下载对应架构的 Miniforge 安装包，然后继续安装：

```bash
cd macos
MINIFORGE_INSTALLER=/path/to/Miniforge3-MacOSX-arm64.sh ./install.command
```

如果要做半离线安装，可以把安装包放在以下任一路径，脚本会自动优先使用本地文件：

```text
macos/vendor/Miniforge3-MacOSX-arm64.sh
vendor/Miniforge3-MacOSX-arm64.sh
```

如果你有自己的镜像地址：

```bash
cd macos
MINIFORGE_URL=https://mirror.example.com/Miniforge3-MacOSX-arm64.sh ./install.command
```

## 安装指定 Claude Code 版本

如需安装某个已知可用的 Claude Code 版本：

```bash
cd macos
CLAUDE_CODE_VERSION=<已知可用版本号> ./install.command
```

## 安装模式

默认 `INSTALL_MODE=auto`：

- 已有 conda 时，复用 conda 隔离环境。
- 已有 Node.js 18+、npm 和 git 时，跳过 Miniforge，使用系统 Node.js。
- 没有系统 Node.js，但已有 conda 时，复用 conda 隔离环境。
- 没有系统 Node.js 和 conda，但有 Homebrew 时，用 Homebrew 准备 Node.js/npm/git。
- 如果存在 `macos/vendor/` 或 `vendor/` 里的本地 Miniforge 安装包，优先使用本地包。
- 这些都没有时，最后才下载 Miniforge。

也可以手动指定：

```bash
INSTALL_MODE=system ./install.command  # 强制使用系统 Node.js/npm/git
INSTALL_MODE=brew ./install.command    # 强制使用 Homebrew 准备依赖
INSTALL_MODE=conda ./install.command   # 强制使用 Miniforge/conda 隔离环境
```

## 脚本会做什么

- 检查当前 Mac 是 Apple Silicon 还是 Intel。
- 检查 macOS、Bash 和 curl 基本信息。
- 自动选择系统 Node.js、Homebrew 或 Miniforge/conda 模式。
- 需要 conda 时，自动安装对应架构的 Miniforge 到 `~/miniforge3`，并创建环境 `claude-code-deepseek`。
- 安装 Claude Code。
- 创建 `.env` 保存 DeepSeek 配置。
- 创建命令行启动器 `~/.local/bin/claude-deepseek`。
- 创建桌面启动器 `Claude Code DeepSeek`。

## 每次使用

双击桌面 `Claude Code DeepSeek`，选择项目文件夹。

如果会用终端，也可以进入项目目录后运行：

```bash
claude-deepseek
```

或指定项目目录：

```bash
claude-deepseek ~/projects/my-project
```

## 测试 DeepSeek 连接

双击 `verify-deepseek.command`。看到返回内容里包含 `DeepSeek OK`，说明 API 连通。

## 升级

重新双击 `install.command` 即可。脚本会复用已有环境并更新 Claude Code。

## 删除

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
rm -rf ~/Desktop/"Claude Code DeepSeek.app"
rm -rf ~/.claude-deepseek
```

然后删除本文件夹即可。

---

更多问题见 [主 README](../README.md)
