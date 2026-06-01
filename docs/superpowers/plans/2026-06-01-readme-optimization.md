# README Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Streamline platform READMEs by removing duplicated content, fix outdated references, add missing sections, and add cross-links.

**Architecture:** Each platform README becomes a focused quick-reference: install, use, test, upgrade, uninstall — with a link back to the main README for full FAQ. Main README gains links to each platform README. No new files created.

**Tech Stack:** Markdown editing

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| Modify | `README.md` | Add sub-README links, fix macOS `.command` reference |
| Modify | `macos/README.md` | Streamline, fix .command → .app, add main README link |
| Modify | `linux/README.md` | Streamline, add .desktop mention, add main README link |
| Modify | `windows/README.md` | Streamline, add upgrade + uninstall sections, add main README link |

---

### Task 1: Update main README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add sub-README links to platform sections**

In the macOS installation section (around line 57), append a link after the code block:

```markdown
详见 [macOS/README.md](macos/README.md)
```

In the Windows installation section (around line 72), append:

```markdown
详见 [windows/README.md](windows/README.md)
```

In the Linux installation section (around line 90), append:

```markdown
详见 [linux/README.md](linux/README.md)
```

- [ ] **Step 2: Fix macOS `.command` reference**

In the macOS installation section, the text says:
> `5. 安装完成后，双击桌面 \`Claude Code DeepSeek\`，选择你的项目文件夹。`

This line does NOT mention `.command` extension — macOS hides extensions — so it's already correct. No change needed.

In step 3, "右键 \`install.command\`，选择"打开"" — this is correct, `install.command` is the installer script and still uses `.command`. Only the desktop launcher changed to `.app`.

Verify: the text "双击桌面 \`Claude Code DeepSeek\`" is neutral about the file format and correct.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add sub-README links to main README

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: Rewrite macOS README

**Files:**
- Modify: `macos/README.md`

- [ ] **Step 1: Replace entire file content**

Write `macos/README.md`:

```markdown
# Claude Code + DeepSeek macOS

给公司 Mac 员工使用的一键安装包：双击安装 Claude Code，并接入 DeepSeek API。

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
```

- [ ] **Step 2: Commit**

```bash
git add macos/README.md
git commit -m "docs(macos): streamline README, remove main README duplicates

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: Rewrite Linux README

**Files:**
- Modify: `linux/README.md`

- [ ] **Step 1: Replace entire file content**

Write `linux/README.md`:

```markdown
# Claude Code + DeepSeek Ubuntu

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
```

- [ ] **Step 2: Commit**

```bash
git add linux/README.md
git commit -m "docs(linux): streamline README, remove main README duplicates

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: Rewrite Windows README

**Files:**
- Modify: `windows/README.md`

- [ ] **Step 1: Replace entire file content**

Write `windows/README.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add windows/README.md
git commit -m "docs(windows): streamline README, add upgrade and uninstall sections

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: Final verification

- [ ] **Step 1: Verify all links are valid**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
# Check all relative links point to existing files
ls -la README.md macos/README.md linux/README.md windows/README.md
```

- [ ] **Step 2: Check no sensitive content**

```bash
cd /home/ljz/vibe_coding/claude-deepseek-starter
grep -rn "sk-" README.md macos/README.md linux/README.md windows/README.md || echo "No API keys found (good)"
```

- [ ] **Step 3: Check git status**

```bash
git status
```

Expected: `nothing to commit, working tree clean`
