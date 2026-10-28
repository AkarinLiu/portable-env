# Portable Env

[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE)
[![Skills](https://img.shields.io/badge/skills-1-5c4ee5)](./.agents/skills)

**[English](README.en.md)**

一个 Agent Skill：在项目目录内搭建「解压即用、随项目迁移」的多语言开发环境。所有运行时解压到项目根的 `.penv/`，由 `require.penv` 声明需要哪些运行时与版本，激活脚本只把声明过的内容加载进当前终端会话——不使用 mise / asdf / nvm / pyenv，不写系统 PATH 与注册表。

## 核心思路

| 约束 | 含义 |
|---|---|
| 全部落在 `.penv/` | 运行时、全局包、缓存、数据库数据目录都在项目内 |
| 声明式 | `require.penv` 一行一个运行时，注释掉即等于不启用 |
| 会话级生效 | 激活只改当前终端，关闭终端自动恢复 |
| 原生脚本 | 只用 bash / cmd / PowerShell，不依赖第三方版本管理器 |
| 多版本并存 | 同一运行时下可放多个版本目录，改声明里的版本串即可切换 |

## 支持的运行时

Bun、Node.js、Rust、PHP、Ruby、Python、Java、Zig、MariaDB、PostgreSQL。

版本目录名只需**包含**声明里的版本串，例如 `v22.14.0`、`jdk-21`、`python-3.12-embed` 都能被对应前缀命中；多个命中时取名字排序最大者。各运行时的便携包来源、首次初始化步骤（PHP 的 `php.ini`、Python embeddable 的 `_pth`、MariaDB/PostgreSQL 的建库）与常见问题，见 [`SKILL.md`](.agents/skills/portable-env/SKILL.md)。

## 快速上手

1. 在项目根写 `require.penv`：

```
# <runtime> <version>
node       22.14.0
bun        1.2.20
postgresql 17
```

2. 把对应版本的便携包解压到 `.penv/<runtime>/`，目录名带上版本串即可：

```
<项目根>/
├── require.penv
└── .penv/
    ├── node/v22.14.0/
    ├── bun/1.2.20/
    ├── postgresql/17/pgsql/
    └── scripts/
        ├── activate.ps1
        ├── activate.sh
        └── activate.cmd
```

3. 激活（按终端任选其一，激活时会逐行打印 `+ <runtime> <version> -> <dir>`，未找到的给警告并跳过）：

```powershell
. .\.penv\scripts\activate.ps1    # 退出执行 Deactivate-Penv
source .penv/scripts/activate.sh   # 退出执行 deactivate
.penv\scripts\activate.cmd         # 打开子 cmd 会话，关窗即恢复
```

4. 验证环境只落在项目内：

```powershell
node -v; bun -v
npm config get prefix    # 应在 .penv/node/... 内
gem env home             # 应在 .penv/ruby/... 内
rustup show home         # 应在 .penv/rust/... 内
```

## 仓库结构

```
.
├── .agents/
│   ├── skills/
│   │   └── portable-env/
│   │       ├── SKILL.md             # 技能正文：流程、脚本、包来源、FAQ
│   │       └── agents/openai.yaml   # Codex 展示元数据
│   └── plugins/marketplace.json     # Codex 插件市场清单
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .codex-plugin/
│   └── plugin.json
├── scripts/
│   ├── install.ps1                  # Windows：目录联接安装到其他项目
│   └── install.sh                   # macOS / Linux：符号链接安装到其他项目
├── templates/skill-template/        # 新建技能时复制的模板
├── AGENTS.md                        # 仓库约定（给 agent 读）
├── README.en.md
└── LICENSE
```

## 作为 Skill 加载

| 消费方 | 方式 |
|---|---|
| Qoder | 打开本仓库即自动发现 `.agents/skills/` |
| Claude Code | 以本仓库为插件来源，`plugin.json` 的 `skills` 指向 `./.agents/skills` |
| Codex | 通过 `.agents/plugins/marketplace.json` 与 `.codex-plugin/plugin.json` |
| 其他项目 | 用 `scripts/install.ps1` 把技能联接到该项目 `.qoder/skills/` |

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -ProjectRoot D:\work\demo
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Uninstall -ProjectRoot D:\work\demo
```

```bash
# macOS / Linux
bash scripts/install.sh --project-root ~/work/demo
bash scripts/install.sh --skill 'portable-*' --project-root ~/work/demo
bash scripts/install.sh --uninstall --project-root ~/work/demo
```

`-Skill` / `--skill` 支持通配符。安装后重启会话或 `/skills reload`，用 `/skills list` 确认，再以 `/portable-env` 调用。Windows 用目录联接，要求仓库与目标项目同卷；macOS/Linux 用符号链接，无卷限制。

## 扩展这个仓库

新增技能：复制 `templates/skill-template` 为 `.agents/skills/<name>`，目录名与 frontmatter 的 `name` 一致，`description` 单行 ≤1024 字符，正文 <500 行；补齐 `agents/openai.yaml`，并登记进三处插件清单与本页技能列表。详细约定见 [`AGENTS.md`](AGENTS.md)。

## 许可证

[MIT](./LICENSE)
