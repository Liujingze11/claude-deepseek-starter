# Claude Code + DeepSeek Ubuntu

English · [中文版](README.zh.md)

One-click install of Claude Code with DeepSeek API on Ubuntu/Linux.

After installation, a `claude-deepseek` command is created. Run it in any project directory to start Claude Code with DeepSeek.

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

If you see messages like `仍在执行：安装 Claude Code`, the installer is still running. Keep the terminal open while those messages continue.

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

You can also launch via the desktop entry `Claude Code DeepSeek` (created automatically by the install script).

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
