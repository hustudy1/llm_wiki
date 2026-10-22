#Requires -Version 5.1
<#
.SYNOPSIS
  llm_wiki를 프로젝트에 적용하거나 새 버전으로 갱신한다 (Windows)

.DESCRIPTION
  powershell -ExecutionPolicy Bypass -File .\apply.ps1 <프로젝트 폴더> [-DryRun] [-Yes]

  1. <프로젝트>\llm_wiki\ 가 없으면 복사한다 (.git과 이 스크립트는 빼고).
     있으면 버전을 비교해, 다르면 공통 문서만 새것으로 바꾼다.
     HANDOVER.md 등 프로젝트에서 만든 파일은 그대로 둔다. 바꾸기 전 폴더는 ~\.llm_wiki_backup\ 에 백업한다.
  2. 연결 파일을 만들거나 보완한다 (이미 있으면 같은 줄이 없을 때만 추가).
     CLAUDE.md: @llm_wiki/00_AI_INSTRUCTIONS.md      (Claude Code가 세션 시작 때 자동으로 읽음)
     AGENTS.md: llm_wiki 문서를 읽으라는 지시         (Codex 등)
  commit은 하지 않는다.
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Target = '',
  [switch]$DryRun,
  [switch]$Yes
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Src        = $PSScriptRoot
$Core       = @('README.md', '00_AI_INSTRUCTIONS.md', '01_WRITING_GUIDELINES.md', '02_HANDOVER_TEMPLATE.md', '03_REFERENCES.md', 'domains')
$ClaudeLine = '@llm_wiki/00_AI_INSTRUCTIONS.md'
$AgentsMark = '<!-- llm_wiki -->'
$Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)

function Write-Info { param([string]$Text) Write-Host "  $Text" }
function Write-Ok   { param([string]$Text) Write-Host "  [OK] $Text" -ForegroundColor Green }
function Stop-Apply { param([string]$Text) Write-Host ''; Write-Host "[중단] $Text" -ForegroundColor Red; exit 1 }

function Get-GuideVersion {
  param([string]$Dir)
  $readme = Join-Path $Dir 'README.md'
  if (-not (Test-Path -LiteralPath $readme)) { return '' }
  $m = Select-String -LiteralPath $readme -Pattern '가이드 버전: `(v[0-9][0-9.]*)`' | Select-Object -First 1
  if ($m) { return $m.Matches[0].Groups[1].Value }
  return ''
}

# 파일 끝에 텍스트를 붙인다 (UTF-8, BOM 없음). 내용이 있으면 빈 줄 하나를 띄운다
function Add-Text {
  param([string]$Path, [string]$Text)
  $prefix = ''
  if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) { $prefix = "`n" }
  $existing = ''
  if (Test-Path -LiteralPath $Path) { $existing = [IO.File]::ReadAllText($Path) }
  [IO.File]::WriteAllText($Path, $existing + $prefix + $Text, $Utf8NoBom)
}

if (-not $Target) { Stop-Apply '프로젝트 폴더를 주세요. 예: .\apply.ps1 C:\work\my-project' }
if (-not (Test-Path -LiteralPath $Target -PathType Container)) { Stop-Apply "폴더가 없습니다: $Target" }
$Target = (Resolve-Path -LiteralPath $Target).Path.TrimEnd('\', '/')
$srcFull = (Resolve-Path -LiteralPath $Src).Path.TrimEnd('\', '/')
if ($Target -eq $srcFull) { Stop-Apply 'llm_wiki 원본 폴더 자체에는 적용할 수 없습니다.' }
if ($Target.StartsWith($srcFull + [IO.Path]::DirectorySeparatorChar)) { Stop-Apply 'llm_wiki 원본 폴더 안에는 적용할 수 없습니다.' }

$newVer = Get-GuideVersion $Src
$dest   = Join-Path $Target 'llm_wiki'
$oldVer = Get-GuideVersion $dest
$mode   = if (Test-Path -LiteralPath $dest -PathType Container) { 'update' } else { 'new' }

Write-Host "llm_wiki 적용 ($newVer)"
if ($DryRun) { Write-Info 'dry-run: 아무것도 바꾸지 않습니다.' }
Write-Info "프로젝트: $Target"
if ($mode -eq 'update') { Write-Info ("현재: " + $(if ($oldVer) { $oldVer } else { '버전 없음' }) + " → 새 버전: $newVer") }
else { Write-Info '현재: llm_wiki 없음 → 새로 복사' }

if (-not $Yes -and -not $DryRun) {
  $a = Read-Host '계속할까요? [y/N]'
  if ($a -notmatch '^(y|Y|yes|YES)$') { Stop-Apply '취소했습니다.' }
}

# ---------- 1. 문서 복사 / 갱신 ----------
Write-Host ''; Write-Host '==> 문서'
if ($mode -eq 'new') {
  if ($DryRun) { Write-Info "[dry-run] $dest 에 공통 문서 복사" }
  else {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach ($f in $Core) { Copy-Item -LiteralPath (Join-Path $Src $f) -Destination $dest -Recurse -Force }
    Write-Ok "llm_wiki\ 복사 (공통 문서 $($Core.Count)개 항목)"
  }
}
elseif ($oldVer -and ($oldVer -eq $newVer)) {
  Write-Ok "이미 $newVer 입니다. 문서는 그대로 둡니다."
}
else {
  $bk = [IO.Path]::Combine($HOME, '.llm_wiki_backup', ((Split-Path $Target -Leaf) + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
  if ($DryRun) { Write-Info "[dry-run] 백업 $bk"; Write-Info "[dry-run] 공통 문서를 $newVer 로 갱신" }
  else {
    New-Item -ItemType Directory -Force -Path $bk | Out-Null
    Copy-Item -Path (Join-Path $dest '*') -Destination $bk -Recurse -Force
    Write-Info "백업: $bk"
    foreach ($f in $Core) { Copy-Item -LiteralPath (Join-Path $Src $f) -Destination $dest -Recurse -Force }
    Write-Ok "공통 문서를 $newVer 로 갱신 (HANDOVER.md 등 프로젝트 파일은 그대로)"
  }
}

# ---------- 2. 연결 파일 ----------
Write-Host ''; Write-Host '==> 연결 파일'
$claudeMd = Join-Path $Target 'CLAUDE.md'
if ((Test-Path -LiteralPath $claudeMd) -and (Select-String -LiteralPath $claudeMd -Pattern $ClaudeLine -SimpleMatch -Quiet)) {
  Write-Ok 'CLAUDE.md: 이미 연결됨'
}
elseif ($DryRun) { Write-Info "[dry-run] CLAUDE.md 에 '$ClaudeLine' 추가" }
else { Add-Text $claudeMd ($ClaudeLine + "`n"); Write-Ok "CLAUDE.md: '$ClaudeLine' 추가" }

$agentsMd = Join-Path $Target 'AGENTS.md'
if ((Test-Path -LiteralPath $agentsMd) -and (Select-String -LiteralPath $agentsMd -Pattern $AgentsMark -SimpleMatch -Quiet)) {
  Write-Ok 'AGENTS.md: 이미 연결됨'
}
elseif ($DryRun) { Write-Info '[dry-run] AGENTS.md 에 llm_wiki 읽기 지시 추가' }
else {
  $block = @"
$AgentsMark
## llm_wiki

작업을 시작하기 전에 아래 문서를 읽고 따른다. 충돌하면 ``llm_wiki/00_AI_INSTRUCTIONS.md``가 우선한다.

- ``llm_wiki/README.md``
- ``llm_wiki/00_AI_INSTRUCTIONS.md``
- ``llm_wiki/01_WRITING_GUIDELINES.md``
- ``llm_wiki/HANDOVER.md`` (없으면 구현·수정 작업일 때 ``llm_wiki/02_HANDOVER_TEMPLATE.md``로 만든다)

"@
  Add-Text $agentsMd ($block -replace "`r`n", "`n")
  Write-Ok 'AGENTS.md: llm_wiki 읽기 지시 추가'
}

Write-Host ''; Write-Host '==> 결과'
if ($DryRun) { Write-Ok 'dry-run 완료 (실제로 바꾼 것은 없습니다)' }
else {
  Write-Ok '적용 완료. commit은 하지 않았습니다.'
  Write-Info "확인: cd `"$Target`"; git status"
  Write-Info "다음: Claude Code나 Codex에서 'llm_wiki 참고해서 앞으로 프로젝트 진행해줘' 라고 시작하면 됩니다."
}
