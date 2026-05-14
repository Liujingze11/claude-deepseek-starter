# Claude Code + DeepSeek Ubuntu 一键安装

这个仓库用于在 Ubuntu/Linux 上自动安装 Claude Code，并把 Claude Code 接入 DeepSeek 的 Anthropic 兼容接口。

建议 GitHub 仓库名：

```text
claude-code-deepseek-ubuntu
```

主安装脚本名：

```text
install.sh
```

## 重要安全提醒

这个仓库可以设为 Public，但一定不要上传真实 API Key。

本项目只提交 `.env.example` 模板，不提交 `.env`。你的 DeepSeek API Key 会在安装时通过命令行隐藏输入，然后只保存到本机的 `.env` 文件里。

`.gitignore` 已经忽略了 `.env`：

```text
.env
```

如果你曾经把真实 API Key 发到聊天、工单、截图或 GitHub，建议立刻去 DeepSeek 控制台删除旧 key，并重新生成一个新 key。

## 新电脑第一次安装

先克隆仓库：

```bash
git clone git@github.com:你的用户名/claude-code-deepseek-ubuntu.git
cd claude-code-deepseek-ubuntu
```

如果你用的是 HTTPS：

```bash
git clone https://github.com/你的用户名/claude-code-deepseek-ubuntu.git
cd claude-code-deepseek-ubuntu
```

给脚本执行权限：

```bash
chmod +x install.sh run-claude.sh verify-deepseek.sh
```

运行安装：

```bash
./install.sh
```

安装过程中会提示：

```text
请输入 DeepSeek API Key（输入时不显示，不会上传到 GitHub；可直接回车稍后手动编辑 .env）：
```

把你的 DeepSeek API Key 粘贴进去，回车即可。输入时屏幕不会显示，这是正常的。

## 安装脚本会做什么

- 如果系统没有 conda，自动安装 Miniforge 到 `~/miniforge3`
- 创建 conda 环境 `claude-code-deepseek`
- 在环境里安装 Node.js 22、npm、git、curl 和 Claude Code
- 创建本机配置文件 `.env`
- 把 DeepSeek API Key 写入 `.env`
- 创建一个启动命令：`~/.local/bin/claude-deepseek`

## 测试 DeepSeek 是否接通

安装完成后，在仓库目录运行：

```bash
./verify-deepseek.sh
```

如果配置没问题，会返回 DeepSeek 的响应内容。

如果提示缺少 `ANTHROPIC_AUTH_TOKEN`，说明 `.env` 里还没有填 API Key。可以重新运行：

```bash
./install.sh
```

也可以手动编辑 `.env`：

```bash
nano .env
```

把这一行改成你的 key：

```bash
ANTHROPIC_AUTH_TOKEN=sk-你的key
```

## 每次怎么打开 Claude Code

以后你不需要每次进入这个安装仓库。

你要在哪个项目里使用 Claude Code，就先进入哪个项目目录：

```bash
cd ~/work/my-project
claude-deepseek
```

比如你要让 Claude Code 修改一个前端项目：

```bash
cd ~/projects/my-web-app
claude-deepseek
```

比如你要让 Claude Code 修改一个 Python 项目：

```bash
cd ~/projects/my-python-service
claude-deepseek
```

Claude Code 会以当前目录作为工作目录启动。

## 如果提示找不到 claude-deepseek

安装脚本会把启动命令放到：

```bash
~/.local/bin/claude-deepseek
```

如果终端提示：

```text
command not found: claude-deepseek
```

说明 `~/.local/bin` 还没有加入 PATH。运行：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

然后再试：

```bash
claude-deepseek
```

如果你用的是 zsh：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 也可以用脚本直接启动

如果你不想配置 PATH，也可以在任意项目目录里直接运行安装仓库里的脚本：

```bash
cd ~/projects/my-project
/你的安装路径/claude-code-deepseek-ubuntu/run-claude.sh
```

例如：

```bash
cd ~/projects/my-project
~/claude-code-deepseek-ubuntu/run-claude.sh
```

## 默认模型配置

默认主模型：

```bash
deepseek-v4-pro[1m]
```

默认轻量/子代理模型：

```bash
deepseek-v4-flash
```

需要改模型时，编辑安装仓库里的 `.env`：

```bash
nano .env
```

相关配置：

```bash
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
```

## 推到 GitHub Public 仓库

第一次创建仓库并推送：

```bash
git init
git add .
git commit -m "Add Claude Code DeepSeek Ubuntu installer"
git branch -M main
git remote add origin git@github.com:你的用户名/claude-code-deepseek-ubuntu.git
git push -u origin main
```

推送前建议检查一下有没有误提交 `.env`：

```bash
git status --ignored
```

正常情况下，`.env` 应该显示为 ignored，不应该出现在待提交文件里。

也可以检查仓库里有没有真实 key：

```bash
grep -R "sk-" -n . --exclude-dir=.git
```

如果输出里出现真实 key，不要 push，先删掉。

## 升级 Claude Code

以后想升级 Claude Code，回到安装仓库运行：

```bash
cd ~/claude-code-deepseek-ubuntu
./install.sh
```

脚本会复用已有 conda 环境，并更新 Claude Code。

## 换 DeepSeek API Key

编辑 `.env`：

```bash
cd ~/claude-code-deepseek-ubuntu
nano .env
```

修改这一行：

```bash
ANTHROPIC_AUTH_TOKEN=sk-新的key
```

保存后重新打开 Claude Code：

```bash
cd ~/projects/my-project
claude-deepseek
```

## 常见问题

### 公司网络无法访问 GitHub 或 npm

脚本需要访问：

- `github.com`：下载 Miniforge
- `registry.npmjs.org`：安装 Claude Code
- `api.deepseek.com`：调用 DeepSeek API

如果公司网络有限制，需要先配置代理：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
```

然后再运行：

```bash
./install.sh
```

### 没有 curl

脚本会尝试自动安装：

```bash
sudo apt-get update
sudo apt-get install -y curl
```

如果公司电脑没有 sudo 权限，需要让管理员先安装 `curl`，或者提前安装好 conda。

### 已经有 conda 了怎么办

没关系。脚本会优先使用已有 conda，然后创建单独环境：

```text
claude-code-deepseek
```

不会把 Claude Code 装进系统 Python 环境。

### 删除安装

删除 conda 环境：

```bash
conda env remove -n claude-code-deepseek
```

删除启动命令：

```bash
rm -f ~/.local/bin/claude-deepseek
```

删除本仓库目录即可。
