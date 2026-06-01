# Claude Code + DeepSeek Ubuntu

[English](README.md) · 中文版

Ubuntu/Linux 一键安装 Claude Code，并接入 DeepSeek API。

安装后会创建一个命令 `claude-deepseek`，在任何项目目录里运行它就能用 DeepSeek 启动 Claude Code。

## 安装

```bash
git clone https://github.com/Liujingze11/claude-deepseek-starter.git
cd claude-deepseek-starter/linux
chmod +x install.sh run-claude.sh verify-deepseek.sh
./install.sh
```

安装时会提示输入 DeepSeek API Key，粘贴后回车即可。

## 每次使用

进入项目目录后运行：

```bash
cd ~/projects/my-project
claude-deepseek
```

也可以通过桌面启动器 `Claude Code DeepSeek` 启动（安装脚本自动创建）。

## 测试连接

```bash
./verify-deepseek.sh
```

## 脚本做了什么

- 没有 conda 时，自动安装 Miniforge 到 `~/miniforge3`
- 创建 conda 环境 `claude-code-deepseek`
- 安装 Node.js、npm、git、curl、Claude Code
- 创建 `.env` 保存 DeepSeek 配置
- 创建启动命令 `~/.local/bin/claude-deepseek`
- 创建桌面启动器 `~/.local/share/applications/claude-deepseek.desktop`

## 升级

回到安装目录重新运行：

```bash
cd ~/claude-deepseek-starter/linux
./install.sh
```

## 删除

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
rm -f ~/.local/share/applications/claude-deepseek.desktop
```

然后删除本仓库目录即可。

---

更多问题见 [主 README](../README.md)
