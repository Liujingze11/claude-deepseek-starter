# Claude Code + DeepSeek macOS

[English](README.md) · 中文版

给公司 Mac 用户使用的一键安装包：双击安装 Claude Code，并接入 DeepSeek API。

采用 Miniforge + conda 隔离环境，不要求提前安装 Homebrew、Node.js 或 npm。

## 安装

1. 下载并解压这个文件夹。
2. 双击 `install.command`。
3. 如果 macOS 提示"无法打开"，右键 `install.command`，选择"打开"，再点"打开"。
4. 按提示输入 DeepSeek API Key。
5. 安装完成后，双击桌面的 `Claude Code DeepSeek`。
6. 在弹出的窗口里选择要操作的项目文件夹。

## 脚本会做什么

- 检查当前 Mac 是 Apple Silicon 还是 Intel。
- 没有 conda 时，自动安装对应架构的 Miniforge 到 `~/miniforge3`。
- 创建 conda 环境 `claude-code-deepseek`。
- 在隔离环境里安装 Node.js、npm、git、curl、Claude Code。
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
```

然后删除本文件夹即可。

---

更多问题见 [主 README](../README.md)
