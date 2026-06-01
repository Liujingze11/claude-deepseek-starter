# README Optimization

## Overview

精简三个平台子 README，去掉和主 README 重复的内容，修正过时信息。子 README 只保留平台特有的操作步骤。主 README 加指向子 README 的链接。

## 原则

- 通用内容只出现在主 README，子 README 不重复
- 平台独有的安装命令、代理设置、删除命令保留在子 README
- 修正过时内容但不标注"新增"——当做本应如此
- FAQ 全部保留在主 README，不下沉

## 主 README 改动

1. 三个平台安装段落末尾各加一行链接指向子 README
2. 修复 macOS 安装段落中的描述（确保不出现 `.command` 过时引用）

## macOS README 改动

**删除：**
- "API Key 输入时不显示是正常的"（主 FAQ Q1）
- 模型配置代码块（主 README 配置章节）
- "安全说明"整节（主 README 末尾）
- proxy 设置代码块（主 FAQ Q8）
- "公司网络访问不了 GitHub 或 npm" 整节（主 FAQ Q8）

**修改：**
- "创建桌面快捷方式 `Claude Code DeepSeek.command`" → "创建桌面启动器 `Claude Code DeepSeek`"
- "双击桌面的 `Claude Code DeepSeek`" 保持不变（.app 对用户透明）

**保留：**
- 安装步骤（双击 install.command → 右键打开 → 输 Key → 完成）
- 脚本会做什么（修正后）
- 每次使用（双击桌面 + 终端命令）
- 测试连接
- 升级
- 删除（补充 .app 清理：`rm -rf ~/Desktop/"Claude Code DeepSeek.app"`）

**新增：**
- 末尾加一行 "更多问题见主 README" 链接

## Linux README 改动

**删除：**
- API Key 输入示例文本块（主 FAQ Q1）
- 模型配置代码块（主 README 配置章节）
- "安全说明"整节（主 README 末尾）
- "如果找不到 claude-deepseek" 整节（主 FAQ Q2）
- "修改 API Key" 整节（主 README 配置章节、主 FAQ Q11）
- "修改模型" 整节（主 README 配置章节、主 FAQ Q12）
- "常见问题"整节（proxy、缺少 curl 均在主 FAQ）

**修改：**
- "脚本做了什么" 加上 `.desktop` 桌面启动器说明

**保留：**
- 介绍段落 + 命令说明
- 安装步骤
- 每次使用
- 测试连接
- 脚本做了什么（修正后）
- 升级
- 删除

**新增：**
- 末尾加主 README 链接

## Windows README 改动

**删除：**
- "API Key 输入时不显示是正常的"（主 FAQ Q1）
- 模型配置代码块（主 README 配置章节）
- "注意"安全说明（主 README 末尾）
- proxy 设置代码块（主 FAQ Q8）
- "公司网络访问不了 GitHub 或 npm" 整节（主 FAQ Q8）

**修改：**
- 无需修改（Windows README 没有过时内容）

**保留：**
- 介绍段落
- 安装步骤
- 脚本会做什么
- 每次使用
- 测试连接

**新增：**
- 升级章节（`setup.bat` 重新运行）
- 删除章节
- 末尾加主 README 链接
