[English](README.md) · 中文

# Claude Code + DeepSeek Windows

Windows 员工双击安装 Claude Code，并接入 DeepSeek API。

采用 Git for Windows 路线，普通同事不需要手动打开终端执行安装命令。

官方说明：https://docs.anthropic.com/zh-CN/docs/claude-code/setup

## 安装

1. 下载并解压这个文件夹。
2. 双击 `setup.bat`。
3. 按提示输入 DeepSeek API Key。
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
