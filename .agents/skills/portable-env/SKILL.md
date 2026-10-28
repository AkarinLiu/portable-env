---
name: portable-env
description: 在项目工作目录下的 .penv 文件夹内搭建 Bun、Node.js、Rust、PHP、Ruby、Python、Java、Zig、MariaDB、PostgreSQL 便携开发环境。通过项目根目录的 require.penv 声明需要哪些运行时与版本，激活脚本按声明逐项加载。仅使用 bash、cmd、PowerShell，不依赖 mise/asdf/nvm 等第三方版本管理器，不写入系统 PATH 与注册表。
---

# 便携开发环境 Skills

## 何时使用

- 在项目目录内搭建「解压即用、随项目迁移」的多语言开发环境
- 需要 Bun、Node.js、Rust、PHP、Ruby、Python、Java、Zig 中的若干运行时
- 需要项目内的 MariaDB / PostgreSQL 实例，数据目录跟随项目
- 明确禁止 mise、asdf、nvm、pyenv 等版本管理器，只允许原生脚本
- 要求声明式管理：用一份 `require.penv` 描述项目依赖，脚本按需加载

## 核心约束

1. 所有运行时解压到 `<项目根>/.penv/<运行时>/<版本目录>/`
2. 环境变量只在**当前终端会话**生效，关闭终端自动恢复
3. 全局包目录、缓存目录、数据库数据目录全部重定向进 `.penv`
4. 只使用 bash / cmd / PowerShell，无任何外部版本管理器
5. 激活内容完全由 **`require.penv`** 决定，未声明的运行时不进入 PATH

## 目录结构

```
<项目根>/
├── require.penv                 ← 运行时声明文件
└── .penv/
    ├── bun/
    │   └── 1.2.20/bun.exe
    ├── node/
    │   └── v22.14.0/node.exe
    ├── zig/
    │   └── zig-windows-x86_64-0.16.0/zig.exe
    ├── php/
    │   └── php-8.4/php.exe
    ├── ruby/
    │   └── ruby-3.3/bin/ruby.exe
    ├── python/
    │   └── python-3.12-embed/python.exe
    ├── java/
    │   └── jdk-21/bin/java.exe
    ├── rust/
    │   └── stable/
    │       ├── rustup/
    │       └── cargo/
    ├── mariadb/
    │   └── mariadb-11.4/bin/mariadbd.exe
    ├── postgresql/
    │   └── 17/pgsql/bin/initdb.exe
    └── scripts/
        ├── activate.ps1
        ├── activate.cmd
        └── activate.sh
```

> 版本目录名只需**包含** `require.penv` 中写的版本串即可，`v22.14.0`、`jdk-21`、`python-3.12-embed` 都能被对应前缀命中。

## require.penv 语法

```
# <runtime> <version>
bun        1.2.20
node       22.14.0
zig        0.16.0
php        8.4
ruby       3.3
python     3.12
java       21
rust       stable
mariadb    11.4
postgresql 17
```

- `#` 后为注释；空行忽略
- 版本匹配顺序：精确目录名 → 包含该版本串的目录 → 多个命中取名字排序最大者
- 某行未找到匹配目录时输出警告并**跳过**，不中断其余运行时的加载
- 注释掉某行即等于该项目不启用该运行时

## 运行时包获取

| 运行时 | 官方/推荐便携包 | 初始化 |
|---|---|---|
| Bun | `bun-windows-x64.zip` | 解压即用 |
| Node.js | `node-v22.x.x-win-x64.zip` | 解压即用 |
| Zig | `zig-windows-x86_64-<ver>.zip` | 解压即用 |
| PHP | `php-<ver>-Win32-vs16-x64.zip`（Thread Safe） | 复制 `php.ini-development` 为 `php.ini` |
| Ruby | RubyInstaller **7z** 包 | 设置 `GEM_HOME/GEM_PATH` 到自身 |
| Python | **Windows embeddable package** | 编辑 `python3xx._pth`，去掉 `#import site` 的 `#` |
| Java | JDK 的 `.zip` 包 | 设置 `JAVA_HOME` |
| Rust | rustup 便携模式：先设 `RUSTUP_HOME/CARGO_HOME` 再运行 `rustup-init.exe` | 工具链与缓存全部落 `.penv` |
| MariaDB | `mariadb-<ver>-winx64.zip` | 运行 `mariadb-install-db.exe` |
| PostgreSQL | EnterpriseDB binaries zip | 运行 `initdb` |

> Rust 说明：官方无解压即用 zip，rustup 是 Rust 官方工具（非 mise 类第三方），通过 `RUSTUP_HOME` + `CARGO_HOME` 完全限制在 `.penv` 内。Unix 可改用官方 tar.gz 手动解压。

## PowerShell 激活脚本（`activate.ps1`）

```powershell
$PenvRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = Split-Path -Parent $PenvRoot
$RequireFile = Join-Path $ProjectRoot 'require.penv'
if (-not (Test-Path $RequireFile)) {
    $RequireFile = Join-Path $PenvRoot 'require.penv'
}
if (-not (Test-Path $RequireFile)) {
    Write-Error "penv: require.penv not found in $ProjectRoot or $PenvRoot"
    return
}

$global:__Penv_OldEnv = @{
    PATH = $env:PATH; JAVA_HOME = $env:JAVA_HOME
    RUSTUP_HOME = $env:RUSTUP_HOME; CARGO_HOME = $env:CARGO_HOME
    GEM_HOME = $env:GEM_HOME; GEM_PATH = $env:GEM_PATH
    NPM_CONFIG_PREFIX = $env:npm_config_prefix
    NPM_CONFIG_CACHE = $env:npm_config_cache
}

$env:PATH = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem"

function __penv_find_version_dir($runtime, $version) {
    $base = Join-Path $PenvRoot $runtime
    if (-not (Test-Path $base)) { return $null }
    $exact = Join-Path $base $version
    if (Test-Path $exact) { return $exact }
    $dirs = @(Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -like "*$version*" })
    if ($dirs.Count -ge 1) {
        return ($dirs | Sort-Object Name -Descending | Select-Object -First 1).FullName
    }
    return $null
}

function __penv_activate_runtime($runtime, $version) {
    $dir = __penv_find_version_dir $runtime $version
    if (-not $dir) {
        Write-Warning "penv: '$runtime $version' not found under $PenvRoot\$runtime"
        return
    }
    switch ($runtime) {
        'bun'        { $env:PATH = "$dir;$env:PATH" }
        'node'       { $env:PATH = "$dir;$env:PATH"
                       $env:npm_config_prefix = "$dir\npm-global"
                       $env:npm_config_cache  = "$dir\npm-cache" }
        'zig'        { $env:PATH = "$dir;$env:PATH" }
        'php'        { $env:PATH = "$dir;$env:PATH" }
        'ruby'       { $env:GEM_HOME = "$dir\lib\ruby\gems"
                       $env:GEM_PATH = "$dir\lib\ruby\gems"
                       $env:PATH = "$dir\bin;$env:PATH" }
        'python'     { $env:PATH = "$dir;$env:PATH" }
        'java'       { $env:JAVA_HOME = $dir
                       $env:PATH = "$dir\bin;$env:PATH" }
        'rust'       { $env:RUSTUP_HOME = "$dir\rustup"
                       $env:CARGO_HOME  = "$dir\cargo"
                       $env:PATH = "$dir\cargo\bin;$env:PATH" }
        'mariadb'    { $env:PATH = "$dir\bin;$env:PATH" }
        'postgresql' { $env:PATH = "$dir\pgsql\bin;$env:PATH" }
        default      { Write-Warning "penv: unknown runtime '$runtime'"; return }
    }
    Write-Host "  + $runtime $version -> $dir" -ForegroundColor Cyan
}

Get-Content $RequireFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    if ($line.StartsWith('#')) { return }
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { return }
    __penv_activate_runtime $parts[0] $parts[1]
}

function global:Deactivate-Penv {
    if (-not $global:__Penv_OldEnv) { return }
    foreach ($k in $global:__Penv_OldEnv.Keys) {
        switch ($k) {
            'NPM_CONFIG_PREFIX' { $env:npm_config_prefix = $global:__Penv_OldEnv[$k] }
            'NPM_CONFIG_CACHE'  { $env:npm_config_cache  = $global:__Penv_OldEnv[$k] }
            default { Set-Item -Path "env:$k" -Value $global:__Penv_OldEnv[$k] -ErrorAction SilentlyContinue }
        }
    }
    Remove-Variable __Penv_OldEnv -Scope Global -ErrorAction SilentlyContinue
    Write-Host "penv deactivated." -ForegroundColor Yellow
}

Write-Host "penv activated from $RequireFile" -ForegroundColor Green
```

用法：`. .\.penv\scripts\activate.ps1`，退出执行 `Deactivate-Penv`。

## Bash 激活脚本（`activate.sh`）

```bash
PENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(dirname "$PENV_ROOT")"

REQUIRE_FILE="$PROJECT_ROOT/require.penv"
[ -f "$REQUIRE_FILE" ] || REQUIRE_FILE="$PENV_ROOT/require.penv"
if [ ! -f "$REQUIRE_FILE" ]; then
    echo "penv: require.penv not found in $PROJECT_ROOT or $PENV_ROOT" >&2
    return 1 2>/dev/null || exit 1
fi

__PENV_OLD_PATH="$PATH"
__PENV_OLD_JAVA_HOME="$JAVA_HOME"
__PENV_OLD_RUSTUP_HOME="$RUSTUP_HOME"
__PENV_OLD_CARGO_HOME="$CARGO_HOME"
__PENV_OLD_GEM_HOME="$GEM_HOME"
__PENV_OLD_GEM_PATH="$GEM_PATH"
__PENV_OLD_NPM_PREFIX="${npm_config_prefix:-}"
__PENV_OLD_NPM_CACHE="${npm_config_cache:-}"

export PATH="/usr/local/bin:/usr/bin:/bin"

__penv_find_version_dir() {
    local runtime="$1" version="$2"
    local base="$PENV_ROOT/$runtime"
    [ -d "$base" ] || return 1
    if [ -d "$base/$version" ]; then
        printf '%s\n' "$base/$version"; return 0
    fi
    local match
    match=$(find "$base" -maxdepth 1 -mindepth 1 -type d -name "*${version}*" 2>/dev/null | sort -r | head -1)
    [ -n "$match" ] && { printf '%s\n' "$match"; return 0; }
    return 1
}

__penv_activate_runtime() {
    local runtime="$1" version="$2" dir
    if ! dir=$(__penv_find_version_dir "$runtime" "$version"); then
        echo "penv: '$runtime $version' not found under $PENV_ROOT/$runtime" >&2
        return
    fi
    case "$runtime" in
        bun)        export PATH="$dir:$PATH" ;;
        node)       if [ -d "$dir/bin" ]; then export PATH="$dir/bin:$PATH"; else export PATH="$dir:$PATH"; fi
                    export npm_config_prefix="$dir/npm-global"
                    export npm_config_cache="$dir/npm-cache" ;;
        zig)        export PATH="$dir:$PATH" ;;
        php)        if [ -d "$dir/bin" ]; then export PATH="$dir/bin:$PATH"; else export PATH="$dir:$PATH"; fi ;;
        ruby)       export GEM_HOME="$dir/lib/ruby/gems"
                    export GEM_PATH="$dir/lib/ruby/gems"
                    export PATH="$dir/bin:$PATH" ;;
        python)     export PATH="$dir:$PATH" ;;
        java)       export JAVA_HOME="$dir"
                    export PATH="$dir/bin:$PATH" ;;
        rust)       export RUSTUP_HOME="$dir/rustup"
                    export CARGO_HOME="$dir/cargo"
                    export PATH="$dir/cargo/bin:$PATH" ;;
        mariadb)    export PATH="$dir/bin:$PATH" ;;
        postgresql) export PATH="$dir/pgsql/bin:$PATH" ;;
        *)          echo "penv: unknown runtime '$runtime'" >&2; return ;;
    esac
    echo "  + $runtime $version -> $dir"
}

while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    [ -z "${line// /}" ] && continue
    read -r runtime version <<< "$line"
    [ -z "$runtime" ] && continue
    [ -z "$version" ] && continue
    __penv_activate_runtime "$runtime" "$version"
done < "$REQUIRE_FILE"

deactivate() {
    export PATH="$__PENV_OLD_PATH"
    export JAVA_HOME="$__PENV_OLD_JAVA_HOME"
    export RUSTUP_HOME="$__PENV_OLD_RUSTUP_HOME"
    export CARGO_HOME="$__PENV_OLD_CARGO_HOME"
    export GEM_HOME="$__PENV_OLD_GEM_HOME"
    export GEM_PATH="$__PENV_OLD_GEM_PATH"
    export npm_config_prefix="$__PENV_OLD_NPM_PREFIX"
    export npm_config_cache="$__PENV_OLD_NPM_CACHE"
    unset __PENV_OLD_PATH __PENV_OLD_JAVA_HOME __PENV_OLD_RUSTUP_HOME \
          __PENV_OLD_CARGO_HOME __PENV_OLD_GEM_HOME __PENV_OLD_GEM_PATH \
          __PENV_OLD_NPM_PREFIX __PENV_OLD_NPM_CACHE
    echo "penv deactivated."
}

echo "penv activated from $REQUIRE_FILE"
```

用法：`source .penv/scripts/activate.sh`，退出执行 `deactivate`。

## CMD 激活脚本（`activate.cmd`）

CMD 无函数级还原，仍用**子 cmd 会话**隔离；环境只在该子窗口内有效，关闭即消失。

```bat
@echo off
setlocal enabledelayedexpansion

for %%I in ("%~dp0..") do set "PENV_ROOT=%%~fI"
for %%I in ("%PENV_ROOT%\..") do set "PROJECT_ROOT=%%~fI"

set "REQUIRE_FILE=%PROJECT_ROOT%\require.penv"
if not exist "%REQUIRE_FILE%" set "REQUIRE_FILE=%PENV_ROOT%\require.penv"
if not exist "%REQUIRE_FILE%" (
    echo penv: require.penv not found 1>&2
    exit /b 1
)

set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

for /f "usebackq tokens=1,* delims= " %%A in ("%REQUIRE_FILE%") do (
    set "RT=%%A"
    set "VER=%%B"
    if not "!RT:~0,1!"=="#" (
        if not "!RT!"=="" (
            if not "!VER!"=="" (
                call :__penv_activate "!RT!" "!VER!"
            )
        )
    )
)

echo penv activated from %REQUIRE_FILE%
cmd /k
exit /b 0

:__penv_activate
set "RT=%~1"
set "VER=%~2"
set "DIR="
if exist "%PENV_ROOT%\%RT%\%VER%" set "DIR=%PENV_ROOT%\%RT%\%VER%"
if not defined DIR (
    for /d %%D in ("%PENV_ROOT%\%RT%\*%VER%*") do set "DIR=%%~fD"
)
if not defined DIR (
    echo penv: '%RT% %VER%' not found 1>&2
    exit /b 0
)
if /i "%RT%"=="node" (
    set "PATH=%DIR%;%PATH%"
    set "npm_config_prefix=%DIR%\npm-global"
    set "npm_config_cache=%DIR%\npm-cache"
) else if /i "%RT%"=="java" (
    set "JAVA_HOME=%DIR%"
    set "PATH=%DIR%\bin;%PATH%"
) else if /i "%RT%"=="ruby" (
    set "GEM_HOME=%DIR%\lib\ruby\gems"
    set "GEM_PATH=%DIR%\lib\ruby\gems"
    set "PATH=%DIR%\bin;%PATH%"
) else if /i "%RT%"=="rust" (
    set "RUSTUP_HOME=%DIR%\rustup"
    set "CARGO_HOME=%DIR%\cargo"
    set "PATH=%DIR%\cargo\bin;%PATH%"
) else if /i "%RT%"=="mariadb" (
    set "PATH=%DIR%\bin;%PATH%"
) else if /i "%RT%"=="postgresql" (
    set "PATH=%DIR%\pgsql\bin;%PATH%"
) else (
    set "PATH=%DIR%;%PATH%"
)
echo   + %RT% %VER% -^> %DIR%
exit /b 0
```

运行 `activate.cmd` 会打开新 cmd 窗口，按 `require.penv` 装配好环境；关闭窗口即彻底恢复。

## 使用流程

1. 在项目根创建 `require.penv`，写入所需运行时与版本
2. 把对应版本目录放到 `.penv/<runtime>/` 下（目录名包含版本串即可）
3. 激活：
   - PowerShell：`. .\.penv\scripts\activate.ps1`
   - Bash：`source .penv/scripts/activate.sh`
   - CMD：`.penv\scripts\activate.cmd`
4. 激活输出会逐行打印 `+ <runtime> <version> -> <dir>`，未找到的会给出 `penv: ... not found` 警告
5. 验证：
   ```powershell
   node -v; bun -v; zig version; php -v; ruby -v
   python -V; java -version; rustc -V
   npm config get prefix        # 应在 .penv/node/... 内
   gem env home                 # 应在 .penv/ruby/... 内
   rustup show home             # 应在 .penv/rust/... 内
   ```
6. 退出：PowerShell / Bash 执行 `Deactivate-Penv` / `deactivate`，CMD 直接关窗口

## 一次性初始化（仅首次）

```powershell
# MariaDB
& "$PenvRoot\mariadb\mariadb-11.4\bin\mariadb-install-db.exe"
# PostgreSQL
& "$PenvRoot\postgresql\17\pgsql\bin\initdb.exe" -D "$PenvRoot\postgresql\17\data" -U postgres -W -E UTF8 -A scram-sha-256
```

Python embeddable 解压后编辑 `python3xx._pth`，去掉 `#import site` 的 `#`。

## 常见问题

- **激活后找不到命令**：确认 `require.penv` 里写的版本串能被 `.penv/<runtime>/` 下某个目录名包含；激活输出应有对应 `+` 行
- **想临时多版本并存**：直接在同一 `<runtime>/` 下放多个版本目录，改 `require.penv` 中的版本串即可切换
- **PowerShell 禁止运行脚本**：`Set-ExecutionPolicy -Scope Process Bypass`
- **CMD 中 `!VAR!` 不生效**：确认脚本开头有 `setlocal enabledelayedexpansion`
- **Rust 更新工具链**：`rustup` 已指向 `.penv/rust/stable/rustup`，更新不会外溢