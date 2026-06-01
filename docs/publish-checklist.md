# 发布前检查清单

## 必做

- 确认没有真实 API Key 提交。
- 确认三个平台目录都包含 `.env.example`。
- 确认 macOS/Linux 脚本有可执行权限。
- 确认 `icons/` 目录包含完整的平台图标（`.ico`, `.icns`, `.png`, `.svg`）。
- 确认中英文 README 内容同步（`README.md` + `README.zh.md`，各平台同理）。
- 确认所有相对链接有效（README 之间的语言链接、主 README 到子 README 的链接）。

## 本地检查命令

```bash
git status --short
rg "sk-" .
find . -type f \( -name "*.sh" -o -name "*.command" \) -print
ls icons/launcher.svg icons/installer.svg icons/launcher.ico icons/installer.ico icons/launcher.icns icons/installer.icns icons/launcher.png icons/installer.png
```

## 推送

```bash
git push origin main
```
