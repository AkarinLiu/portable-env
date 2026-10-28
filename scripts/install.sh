#!/usr/bin/env bash
# 把 .agents/skills 下的技能链接到目标项目的 .qoder/skills（macOS / Linux）
set -u

usage() {
    cat <<'EOF'
用法: install.sh [选项]

选项:
  --skill <模式>         只处理匹配的技能，支持通配符，如 'portable-*'（默认 *）
  --project-root <目录>  目标项目根目录（默认当前目录）
  --uninstall            移除已建立的链接，不动技能源目录
  -h, --help             显示本帮助
EOF
}

skill_pattern='*'
project_root='.'
uninstall=0

while [ $# -gt 0 ]; do
    case $1 in
        --skill)
            [ $# -ge 2 ] || { echo "--skill 缺少参数" >&2; exit 2; }
            skill_pattern=$2; shift 2 ;;
        --project-root)
            [ $# -ge 2 ] || { echo "--project-root 缺少参数" >&2; exit 2; }
            project_root=$2; shift 2 ;;
        --uninstall) uninstall=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
done

script_dir=$(cd "$(dirname "$0")" && pwd -P) || exit 1
repo_root=$(dirname "$script_dir")
source_dir="$repo_root/.agents/skills"

[ -d "$source_dir" ] || { echo "skills 源目录不存在: $source_dir" >&2; exit 1; }
[ -d "$project_root" ] || { echo "项目目录不存在: $project_root" >&2; exit 1; }

project_root=$(cd "$project_root" && pwd -P)
dest_dir="$project_root/.qoder/skills"

matched=0
failed=0

for skill_path in "$source_dir"/*; do
    [ -d "$skill_path" ] || continue
    name=$(basename "$skill_path")
    [[ $name == $skill_pattern ]] || continue
    matched=$((matched + 1))

    link="$dest_dir/$name"
    is_link=0
    [ -L "$link" ] && is_link=1

    if [ "$uninstall" -eq 1 ]; then
        if [ "$is_link" -eq 1 ]; then
            rm "$link" || failed=$((failed + 1))
            echo "删除  $link"
        else
            echo "跳过  $name（未安装或不是链接）"
        fi
        continue
    fi

    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir" || { echo "无法创建目录: $dest_dir" >&2; exit 1; }
    fi

    if [ -e "$link" ] || [ -L "$link" ]; then
        if [ "$is_link" -eq 1 ]; then
            rm "$link" || { failed=$((failed + 1)); continue; }
        else
            echo "跳过 $name：$link 已存在且不是链接，请手动处理后再试" >&2
            failed=$((failed + 1))
            continue
        fi
    fi

    if ln -s "$skill_path" "$link" && [ -L "$link" ]; then
        echo "链接  $name -> $skill_path"
    else
        rm -rf "$link" 2>/dev/null
        echo "链接失败 $name：当前平台不支持符号链接，Windows 请改用 scripts/install.ps1" >&2
        failed=$((failed + 1))
    fi
done

if [ "$matched" -eq 0 ]; then
    echo "skills/ 下没有匹配 '$skill_pattern' 的技能" >&2
    exit 1
fi

echo "目标目录: $dest_dir"
[ "$failed" -eq 0 ] || exit 1
