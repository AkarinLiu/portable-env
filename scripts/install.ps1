#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Skill = '*',
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $RepoRoot '.agents\skills'
$DestDir   = Join-Path (Resolve-Path -LiteralPath $ProjectRoot).Path '.qoder\skills'

if (-not (Test-Path -LiteralPath $SourceDir)) { throw "skills 源目录不存在: $SourceDir" }

$skills = @(Get-ChildItem -LiteralPath $SourceDir -Directory | Where-Object { $_.Name -like $Skill })
if ($skills.Count -eq 0) { throw "skills/ 下没有匹配 '$Skill' 的技能" }

if (-not $Uninstall) {
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
}

$failed = 0
foreach ($s in $skills) {
    $link = Join-Path $DestDir $s.Name
    $exists = Test-Path -LiteralPath $link
    $isLink = $exists -and [bool]((Get-Item -LiteralPath $link -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)

    if ($Uninstall) {
        if (-not $isLink) { Write-Host "跳过  $($s.Name)（未安装或不是联接）"; continue }
        [IO.Directory]::Delete($link)
        Write-Host "删除  $link"
        continue
    }

    if ($exists) {
        if (-not $isLink) {
            Write-Warning "跳过 $($s.Name)：$link 已存在且不是联接，请手动处理后再试"
            $failed++
            continue
        }
        [IO.Directory]::Delete($link)
    }

    try {
        New-Item -ItemType Junction -Path $link -Target $s.FullName | Out-Null
        Write-Host "链接  $($s.Name) -> $($s.FullName)"
    } catch {
        Write-Warning "链接失败 $($s.Name)：$($_.Exception.Message)"
        $failed++
    }
}

Write-Host "目标目录: $DestDir"
if ($failed -gt 0) { exit 1 }
