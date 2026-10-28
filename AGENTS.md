# 仓库指南

## 职责

本仓库只存放 Agent Skills 源文件，不放运行时产物。技能源目录是 `.agents/skills/<name>/`，Claude Code、Codex、Qoder 都从这里读取；三处插件清单只做打包描述，不复制技能内容：

- `.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json`
- `.codex-plugin/plugin.json`
- `.agents/plugins/marketplace.json`

新增或重命名技能后，同步更新上述清单里指向技能的字段和 README 的技能列表。

`README.md` 为中文默认版本，`README.en.md` 为英文版本，两者内容与链接必须同步修改，保留顶部互链。

## 技能约定

- 一个技能一个目录，目录名必须等于 SKILL.md frontmatter 的 `name`：小写字母、数字、连字符
- `description` 单行、≤1024 字符，写清「做什么」和「何时使用」
- `SKILL.md` 正文 <500 行，长资料拆到 `references/`
- 需要 Codex 展示信息时写 `agents/openai.yaml`
- 技能目录内不添加 README、CHANGELOG 等文档

## 环境脚本

`scripts/install.ps1` 用目录联接把技能挂到目标项目的 `.qoder/skills/`。该脚本必须保留 UTF-8 BOM，否则 Windows PowerShell 5.1 会按 ANSI 解析中文并报语法错误。

`scripts/install.sh` 是 macOS / Linux 版本，用符号链接实现，参数与 `install.ps1` 对应；改动任一个时保持两者行为一致。提交该脚本需保留可执行位：`git add --chmod=+x scripts/install.sh`。

## 验证

- 改技能后执行 `install.ps1` 到临时项目，确认 `SKILL.md` 可读，卸载后源目录仍完整
- 改清单后确认 `skills` 字段仍指向 `./.agents/skills`
- 安装脚本对已存在的同名真实目录必须报错退出，不得删除

## 提交

使用中文提交信息，一条提交聚焦一件事；不要提交 `.qoder/skills/` 下的联接。
