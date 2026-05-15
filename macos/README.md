# Claude Code + DeepSeek macOS

给公司 Mac 员工使用的一键安装包：双击安装 Claude Code，并接入 DeepSeek API。

这个版本采用 Miniforge + conda 隔离环境，不要求同事提前安装 Homebrew、Node.js 或 npm，也不需要手动输入终端命令。

## 给同事的用法

1. 下载并解压这个文件夹。
2. 双击 `install.command`。
3. 如果 macOS 提示“无法打开”，右键 `install.command`，选择“打开”，再点“打开”。
4. 按提示输入 DeepSeek API Key。输入时不显示是正常的。
5. 安装完成后，双击桌面的 `Claude Code DeepSeek`。
6. 在弹出的窗口里选择要操作的项目文件夹。

## 脚本会做什么

- 检查当前 Mac 是 Apple Silicon 还是 Intel。
- 没有 conda 时，自动安装对应架构的 Miniforge 到 `~/miniforge3`。
- 创建 conda 环境 `claude-code-deepseek`。
- 在隔离环境里安装 Node.js、npm、git、curl、Claude Code。
- 创建 `.env` 保存 DeepSeek 配置。
- 创建命令行启动器 `~/.local/bin/claude-deepseek`。
- 创建桌面快捷方式 `Claude Code DeepSeek.command`。

## 每次使用

最简单方式：双击桌面 `Claude Code DeepSeek`，选择项目文件夹。

如果同事会用终端，也可以进入项目目录后运行：

```bash
claude-deepseek
```

或者指定项目目录：

```bash
claude-deepseek ~/projects/my-project
```

## 测试 DeepSeek 连接

双击 `verify-deepseek.command`。

看到返回内容里包含 `DeepSeek OK`，说明 API 连通。

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

先让 IT 配好系统代理。会用终端的同事也可以临时设置：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
./install.command
```

如果 npm 需要单独代理：

```bash
npm config set proxy http://代理地址:端口
npm config set https-proxy http://代理地址:端口
```

## 升级

重新双击 `install.command` 即可。脚本会复用已有环境并更新 Claude Code。

## 删除

会用终端的同事可以执行：

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
rm -f ~/Desktop/"Claude Code DeepSeek.command"
```

然后删除本文件夹即可。

## 安全说明

不要把真实 DeepSeek API Key 上传到 GitHub。真实 key 只应保存在本机 `.env`，本仓库已通过 `.gitignore` 忽略它。
