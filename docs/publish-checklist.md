# 发布前检查清单

## 必做

- 确认仓库名是 `claude-deepseek-starter`。
- 确认远程地址是 `https://github.com/Liujingze11/claude-deepseek-starter.git`。
- 确认没有真实 API Key。
- 确认三个平台目录都包含 `.env.example`。
- 确认 macOS/Linux 脚本有可执行权限。

## 本地检查命令

```bash
git status --short
rg "sk-" .
find macos linux -type f \( -name "*.sh" -o -name "*.command" \) -print
```

## 推荐提交信息

```text
Initial cross-platform Claude Code DeepSeek starter
```

## 推送

```bash
git init
git branch -M main
git remote add origin https://github.com/Liujingze11/claude-deepseek-starter.git
git add .
git commit -m "Initial cross-platform Claude Code DeepSeek starter"
git push -u origin main
```
