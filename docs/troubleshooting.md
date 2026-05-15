# 常见问题

## 找不到 `claude-deepseek`

macOS/Linux 需要确认 `~/.local/bin` 在 PATH 中：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

bash 用户改用：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Windows 安装脚本会把 `%USERPROFILE%\bin` 加入用户 PATH。如果当前窗口找不到命令，重新打开 PowerShell 或重启电脑。

## API Key 输入后没有显示

这是正常的。脚本使用隐藏输入，避免 key 被旁边的人看到。输入完成后按回车即可。

## `verify` 失败

优先检查：

- `.env` 是否存在。
- `ANTHROPIC_AUTH_TOKEN` 是否是 DeepSeek API Key。
- `ANTHROPIC_BASE_URL` 是否为 `https://api.deepseek.com/anthropic`。
- 公司网络是否需要代理。

## 公司网络访问不了 GitHub 或 npm

macOS/Linux：

```bash
export HTTPS_PROXY=http://代理地址:端口
export HTTP_PROXY=http://代理地址:端口
```

Windows PowerShell：

```powershell
$env:HTTPS_PROXY="http://代理地址:端口"
$env:HTTP_PROXY="http://代理地址:端口"
```

npm 单独代理：

```bash
npm config set proxy http://代理地址:端口
npm config set https-proxy http://代理地址:端口
```

## Windows 上安装后仍找不到 Node 或 Claude

先关闭当前 PowerShell 或安装窗口，重新打开后再试。仍不行就重启电脑，因为 winget 安装 Git/Node 后 PATH 有时需要新会话才能完全生效。

## macOS 提示无法打开 `.command`

右键脚本，选择“打开”，再点一次“打开”。这是 macOS Gatekeeper 对非签名脚本的正常提示。

## Linux 缺少 curl

Ubuntu/Debian 可先运行：

```bash
sudo apt-get update
sudo apt-get install -y curl
```

如果没有 sudo 权限，需要管理员先安装。
