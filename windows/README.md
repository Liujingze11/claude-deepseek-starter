# Claude Code + DeepSeek Windows

Windows 员工双击安装 Claude Code，并接入 DeepSeek API。

官方 Claude Code 当前支持 Windows 10+，但需要 WSL 或 Git for Windows，并要求 Node.js 18+。这个版本采用 Git for Windows 路线，普通同事不需要手动打开终端执行安装命令。

官方说明：https://docs.anthropic.com/zh-CN/docs/claude-code/setup

## 给同事的用法

1. 下载并解压这个文件夹。
2. 双击 `setup.bat`。
3. 按提示输入 DeepSeek API Key。输入时不显示是正常的。
4. 安装完成后，双击桌面的 `Claude Code DeepSeek`。
5. 在弹出的窗口里选择要操作的项目文件夹。

## 脚本会做什么

- 检查并安装 Git for Windows。
- 检查并安装 Node.js LTS。
- 通过 npm 安装/更新 Claude Code。
- 创建 `.env` 保存 DeepSeek 配置。
- 创建 `claude-deepseek` 命令。
- 创建桌面快捷方式 `Claude Code DeepSeek`。

## 每次使用

最简单方式：双击桌面 `Claude Code DeepSeek`，选择项目文件夹。

如果同事已经会用终端，也可以进入项目目录后运行：

```powershell
claude-deepseek
```

或者指定项目目录：

```powershell
claude-deepseek C:\Users\me\projects\my-project
```

## 测试 DeepSeek 连接

右键 `verify-deepseek.ps1`，选择“使用 PowerShell 运行”。

也可以在当前文件夹运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-deepseek.ps1
```

## 修改 API Key 或模型

编辑本文件夹下的 `.env`。

```text
ANTHROPIC_AUTH_TOKEN=sk-你的新key
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
CLAUDE_CODE_EFFORT_LEVEL=max
```

## 公司网络访问不了 GitHub 或 npm

先让 IT 配好 Windows 代理，或在 PowerShell 里临时设置：

```powershell
$env:HTTPS_PROXY="http://代理地址:端口"
$env:HTTP_PROXY="http://代理地址:端口"
.\install.ps1
```

如果 npm 需要单独代理：

```powershell
npm config set proxy http://代理地址:端口
npm config set https-proxy http://代理地址:端口
```

## 注意

不要把真实 DeepSeek API Key 上传到 GitHub。真实 key 只应保存在本机 `.env`，本仓库已通过 `.gitignore` 忽略它。
