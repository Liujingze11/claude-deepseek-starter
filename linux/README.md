# Claude Code + DeepSeek Ubuntu

English · [中文版](README.zh.md)

One-click install of Claude Code with DeepSeek API on Ubuntu/Linux.

After installation, a `claude-deepseek` command is created. Run it in any project directory to start Claude Code with DeepSeek.

The launcher always activates the dedicated conda environment `claude-code-deepseek` first, then starts Claude Code in the project folder you chose. If a Claude Code auto-update leaves the npm package half-installed, the launcher repairs only this conda environment before continuing.

## Install

```bash
git clone https://github.com/Liujingze11/claude-deepseek-starter.git
cd claude-deepseek-starter/linux
chmod +x install.sh run-claude.sh verify-deepseek.sh
./install.sh
```

You will be prompted for your DeepSeek API Key. Paste and press Enter.

## During Installation

The installer shows numbered setup steps and heartbeat messages during long-running work. First-time installation may take several minutes while Miniforge, conda packages, npm packages, and Claude Code are downloaded.

During the Claude Code step, npm runs with `--loglevel=info --progress=true`, and the installer prints a heartbeat every 10 seconds. If you see messages like `仍在执行：安装 Claude Code`, the installer is still running. Keep the terminal open while those messages continue.

## Install a Specific Claude Code Version

To install a known working Claude Code version:

```bash
cd linux
CLAUDE_CODE_VERSION=<known-working-version> ./install.sh
```

## Daily Use

Enter your project directory and run:

```bash
cd ~/projects/my-project
claude-deepseek
```

Or pass a project folder explicitly:

```bash
claude-deepseek ~/projects/my-project
```

You can also launch via the desktop entry `Claude Code DeepSeek` (created automatically by the install script).

If the launcher prints `检测到 Claude Code 更新未完成，正在修复当前 conda 环境`, keep the terminal open. It is cleaning a broken Claude Code update inside `claude-code-deepseek`; it does not touch your project files, system Node.js, or other conda environments.

## Test Connection

```bash
./verify-deepseek.sh
```

## What the Script Does

- Installs Miniforge to `~/miniforge3` if conda is not present.
- Creates the conda environment `claude-code-deepseek`.
- Installs Node.js, npm, git, curl, and Claude Code.
- Creates `.env` to store DeepSeek configuration.
- Creates the CLI launcher `~/.local/bin/claude-deepseek`.
- Creates the desktop entry `~/.local/share/applications/claude-deepseek.desktop`.
- Checks Claude Code before launch and repairs interrupted npm/native-binary updates inside this conda environment.

## Upgrade

Go back to the install directory and re-run:

```bash
cd ~/claude-deepseek-starter/linux
./install.sh
```

## Uninstall

```bash
conda env remove -n claude-code-deepseek
rm -f ~/.local/bin/claude-deepseek
rm -f ~/.local/share/applications/claude-deepseek.desktop
```

Then delete the repo directory.

---

For more questions, see the [main README](../README.md)
