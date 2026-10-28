# Portable Env

[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE)
[![Skills](https://img.shields.io/badge/skills-1-5c4ee5)](./.agents/skills)

**[简体中文](./README.md)**

An Agent Skill that builds a project-local, extraction-based development environment. Every runtime unpacks into `.penv/` at the project root, `require.penv` declares which runtimes and versions are needed, and the activation scripts load only those declarations into the current terminal session — no mise, asdf, nvm or pyenv, and no writes to the system PATH or registry.

## Design constraints

| Constraint | Meaning |
|---|---|
| Everything lives under `.penv/` | Runtimes, global packages, caches and database data directories stay inside the project |
| Declarative | One runtime per line in `require.penv`; commenting a line out disables that runtime |
| Session-scoped | Activation only changes the current terminal and is undone when the terminal closes |
| Native scripts only | bash, cmd and PowerShell; no third-party version managers |
| Parallel versions | Keep several version directories per runtime and switch by editing the declared version string |

## Supported runtimes

Bun, Node.js, Rust, PHP, Ruby, Python, Java, Zig, MariaDB and PostgreSQL.

A version directory only needs to **contain** the declared version string, so `v22.14.0`, `jdk-21` and `python-3.12-embed` all match their prefixes; when several directories match, the last one by name wins. Portable package sources, one-time initialization (PHP `php.ini`, the Python embeddable `_pth` file, MariaDB/PostgreSQL database creation) and troubleshooting live in [`SKILL.md`](.agents/skills/portable-env/SKILL.md).

## Quick start

1. Write `require.penv` at the project root:

```
# <runtime> <version>
node       22.14.0
bun        1.2.20
postgresql 17
```

2. Unpack each portable package into `.penv/<runtime>/`, keeping the version string in the directory name:

```
<project root>/
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

3. Activate with whichever terminal you use; activation prints `+ <runtime> <version> -> <dir>` per entry and warns while skipping anything it cannot find:

```powershell
. .\.penv\scripts\activate.ps1    # run Deactivate-Penv to undo
source .penv/scripts/activate.sh   # run deactivate to undo
.penv\scripts\activate.cmd         # opens a child cmd session; closing it restores everything
```

4. Confirm the toolchain stays inside the project:

```powershell
node -v; bun -v
npm config get prefix    # should point inside .penv/node/...
gem env home             # should point inside .penv/ruby/...
rustup show home         # should point inside .penv/rust/...
```

## Repository layout

```
.
├── .agents/
│   ├── skills/
│   │   └── portable-env/
│   │       ├── SKILL.md             # skill body: workflow, scripts, package sources, FAQ
│   │       └── agents/openai.yaml   # Codex display metadata
│   └── plugins/marketplace.json     # Codex plugin marketplace catalog
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .codex-plugin/
│   └── plugin.json
├── scripts/
│   └── install.ps1                  # junctions the skill into other projects
├── templates/skill-template/        # template to copy when adding a skill
├── AGENTS.md                        # repository conventions for agents
├── README.md
└── LICENSE
```

## Loading the skill

| Client | Mechanism |
|---|---|
| Qoder | Opening the repository discovers `.agents/skills/` |
| Claude Code | Uses this repository as a plugin source; `skills` in `plugin.json` points to `./.agents/skills` |
| Codex | Reads `.agents/plugins/marketplace.json` and `.codex-plugin/plugin.json` |
| Other projects | `scripts/install.ps1` junctions the skill into that project's `.qoder/skills/` |

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -ProjectRoot D:\work\demo
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Uninstall -ProjectRoot D:\work\demo
```

`-Skill` accepts wildcards. After installing, restart the session or run `/skills reload`, confirm with `/skills list`, then invoke `/portable-env`. Junctions require the repository and target project to share a volume; cross-volume targets report a failure.

## Extending this repository

To add a skill, copy `templates/skill-template` to `.agents/skills/<name>`, keep the directory name equal to the frontmatter `name`, keep `description` on one line under 1024 characters and the body under 500 lines, fill in `agents/openai.yaml`, then register the skill in the three plugin manifests and the skill list. Full conventions are in [`AGENTS.md`](AGENTS.md).

## License

[MIT](./LICENSE)
