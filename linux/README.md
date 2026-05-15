# Claude Code + DeepSeek Ubuntu

Ubuntu/Linux 一键安装 Claude Code，并接入 DeepSeek API。

安装后会创建一个命令：

```bash
claude-deepseek
```

以后在任何项目目录里运行它，就能用 DeepSeek 启动 Claude Code。

## 安装

```bash
git clone https://github.com/Liujingze11/claude-deepseek-starter.git
cd claude-deepseek-starter/linux
chmod +x install.sh run-claude.sh verify-deepseek.sh
./install.sh
```

安装时会提示输入 DeepSeek API Key：

```text
请输入 DeepSeek API Key（输入时不显示，不会上传到 GitHub；可直接回车稍后手动编辑 .env）：
```

粘贴 key 后回车即可。输入时屏幕不显示是正常的。

## 每次使用

进入你要操作的项目目录：

```bash
cd ~/projects/my-project
claude-deepseek
```

Claude Code 会在当前目录启动。

## 测试连接

安装后可以测试 DeepSeek 是否接通：

```bash
./verify-deepseek.sh
```

## 脚本做了什么

- 没有 conda 时，自动安装 Miniforge 到 `~/miniforge3`
- 创建 conda 环境 `claude-code-deepseek`
- 安装 Node.js、npm、git、curl、Claude Code
- 创建本机 `.env` 保存 DeepSeek 配置
- 创建启动命令 `~/.local/bin/claude-deepseek`

## 安全说明

可以把这个仓库设为 Public，但不要上传真实 API Key。

真实 key 只会保存在本机 `.env`：

```bash
.env
```

`.env` 已经写入 `.gitignore`，不会被正常提交。

推送前可以检查：

```bash
git status --ignored
grep -R "sk-" -n . --exclude-dir=.git
```

如果看到真实 key，不要 push。

## 如果找不到 claude-deepseek

如果提示：

```text
command not found: claude-deepseek
```

把 `~/.local/bin` 加入 PATH：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

zsh 用户：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 修改 API Key

```bash
cd ~/claude-deepseek-starter/linux
nano .env
```

修改：

```bash
ANTHROPIC_AUTH_TOKEN=sk-你的新key
```

## 修改模型

编辑 `.env`：

```bash
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
```

## 升级

回到安装目录重新运行：

```bash
cd ~/claude-deepseek-starter/linux
./install.sh
```

## 常见问题

### 公司网络访问不了 GitHub 或 npm

先配置代理：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
./install.sh
```

### 没有 curl

脚本会尝试自动安装：

```bash
sudo apt-get update
sudo apt-get install -y curl
```

如果没有 sudo 权限，需要管理员先安装 `curl`。

### 删除

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
```

然后删除本仓库目录即可。
