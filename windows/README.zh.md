# Claude Code + DeepSeek Windows

[English](README.md) · 中文版

Windows 用户双击安装 Claude Code，并接入 DeepSeek API。

采用 Git for Windows 路线，普通用户不需要手动打开终端执行安装命令。

官方说明：https://docs.anthropic.com/zh-CN/docs/claude-code/setup

## 安装

1. 下载并解压这个文件夹。
2. 双击 `setup.bat`。
3. 按提示输入 DeepSeek API Key。
4. 安装完成后，双击桌面的 `Claude Code DeepSeek`。
5. 在弹出的窗口里选择要操作的项目文件夹。

## 安装过程中会看到什么

安装器会显示步骤编号，并在耗时较长的步骤中输出提示。首次安装可能需要几分钟，因为可能需要安装 Git for Windows、Node.js、npm 软件包和 Claude Code。

Claude Code 安装步骤会使用 `--loglevel=info --progress=true` 运行 npm，并每 10 秒输出一次心跳提示。如果看到类似“仍在执行：安装 Claude Code”的提示，说明安装器还在运行。只要这些提示还在出现，请不要关闭窗口。

## 安装指定 Claude Code 版本

如需安装某个已知可用的 Claude Code 版本，请手动运行 PowerShell：

```powershell
cd windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ClaudeCodeVersion <已知可用版本号>
```

## 脚本会做什么

- 检查并安装 Git for Windows。
- 检查并安装 Node.js LTS。
- 通过 npm 安装/更新 Claude Code。
- 创建 `.env` 保存 DeepSeek 配置。
- 创建 `claude-deepseek` 命令。
- 创建桌面快捷方式 `Claude Code DeepSeek`。

## 每次使用

双击桌面 `Claude Code DeepSeek`，选择项目文件夹。

如果会用终端，也可以进入项目目录后运行：

```powershell
claude-deepseek
```

或指定项目目录：

```powershell
claude-deepseek C:\Users\me\projects\my-project
```

## 测试 DeepSeek 连接

右键 `verify-deepseek.ps1`，选择"使用 PowerShell 运行"。

也可以在 PowerShell 里运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-deepseek.ps1
```

## 升级

重新双击 `setup.bat` 即可。

## 删除

- 删除 `%USERPROFILE%\bin\claude-deepseek.cmd`
- 删除桌面 `Claude Code DeepSeek`
- 删除本项目文件夹

---

更多问题见 [主 README](../README.md)
