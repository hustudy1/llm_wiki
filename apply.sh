#!/usr/bin/env bash
#
# llm_wiki를 프로젝트에 적용하거나 새 버전으로 갱신한다 (macOS / Linux)
#
#   bash apply.sh <프로젝트 폴더> [--dry-run] [-y]      Windows는 apply.ps1
#
# 하는 일
#   1. <프로젝트>/llm_wiki/ 가 없으면 복사한다 (.git과 이 스크립트는 빼고).
#      있으면 버전을 비교해, 다르면 공통 문서만 새것으로 바꾼다.
#      HANDOVER.md 등 프로젝트에서 만든 파일은 그대로 둔다. 바꾸기 전 폴더는 ~/.llm_wiki_backup/ 에 백업한다.
#   2. 연결 파일을 만들거나 보완한다 (이미 있으면 같은 줄이 없을 때만 추가).
#      CLAUDE.md: @llm_wiki/00_AI_INSTRUCTIONS.md      (Claude Code가 세션 시작 때 자동으로 읽음)
#      AGENTS.md: llm_wiki 문서를 읽으라는 지시         (Codex 등)
#   commit은 하지 않는다. 끝나면 git status로 확인한다.

set -u

SRC="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
ASSUME_YES=0
TARGET=""
# 공통 문서: 갱신 때 새것으로 바꾸는 대상. 이 밖의 파일(HANDOVER.md 등)은 건드리지 않는다
CORE="README.md 00_AI_INSTRUCTIONS.md 01_WRITING_GUIDELINES.md 02_HANDOVER_TEMPLATE.md 03_REFERENCES.md domains"
CLAUDE_LINE="@llm_wiki/00_AI_INSTRUCTIONS.md"
AGENTS_MARK="<!-- llm_wiki -->"

info() { printf '  %s\n' "$*"; }
ok()   { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [주의] %s\n' "$*"; }
die()  { printf '\n[중단] %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

usage() {
  sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -y|--yes)  ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) usage; die "알 수 없는 옵션: $1" ;;
    *)  [ -z "$TARGET" ] || die "프로젝트 폴더는 하나만 줍니다."; TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || { usage; die "프로젝트 폴더를 주세요. 예: bash apply.sh ~/work/my-project"; }
[ -d "$TARGET" ] || die "폴더가 없습니다: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" = "$SRC" ] && die "llm_wiki 원본 폴더 자체에는 적용할 수 없습니다."
case "$TARGET/" in "$SRC/"*) die "llm_wiki 원본 폴더 안에는 적용할 수 없습니다." ;; esac

version_of() { sed -n 's/.*가이드 버전: `\(v[0-9][0-9.]*\)`.*/\1/p' "$1/README.md" 2>/dev/null | head -1; }
NEW_VER="$(version_of "$SRC")"
DEST="$TARGET/llm_wiki"
OLD_VER="$(version_of "$DEST")"

printf 'llm_wiki 적용 (%s)\n' "${NEW_VER:-버전 확인 실패}"
[ "$DRY_RUN" -eq 1 ] && info "dry-run: 아무것도 바꾸지 않습니다."
info "프로젝트: $TARGET"
if [ -d "$DEST" ]; then MODE=update; info "현재: ${OLD_VER:-버전 없음} → 새 버전: $NEW_VER"; else MODE=new; info "현재: llm_wiki 없음 → 새로 복사"; fi

if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  printf '\n계속할까요? [y/N] '
  read -r a || a=""
  case "$a" in y|Y|yes|YES) : ;; *) die "취소했습니다." ;; esac
fi

# ---------- 1. 문서 복사 / 갱신 ----------
printf '\n==> 문서\n'
if [ "$MODE" = new ]; then
  run mkdir -p "$DEST"
  for f in $CORE; do run cp -R "$SRC/$f" "$DEST/"; done
  ok "llm_wiki/ 복사 (공통 문서 $(echo $CORE | wc -w | tr -d ' ')개 항목)"
elif [ -n "$OLD_VER" ] && [ "$OLD_VER" = "$NEW_VER" ]; then
  ok "이미 $NEW_VER 입니다. 문서는 그대로 둡니다."
else
  BK="$HOME/.llm_wiki_backup/$(basename "$TARGET")-$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$BK"
  run cp -R "$DEST/." "$BK/"
  info "백업: $BK"
  for f in $CORE; do
    if [ -d "$SRC/$f" ]; then
      run mkdir -p "$DEST/$f"
      run cp -R "$SRC/$f/." "$DEST/$f/"
    else
      run cp "$SRC/$f" "$DEST/$f"
    fi
  done
  ok "공통 문서를 $NEW_VER 로 갱신 (HANDOVER.md 등 프로젝트 파일은 그대로)"
  info "프로젝트에서 공통 문서를 직접 고쳐 썼다면 백업과 비교하세요: diff -r \"$BK\" \"$DEST\""
fi

# ---------- 2. 연결 파일 ----------
printf '\n==> 연결 파일\n'
CLAUDE_MD="$TARGET/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -qF "$CLAUDE_LINE" "$CLAUDE_MD"; then
  ok "CLAUDE.md: 이미 연결됨"
else
  if [ "$DRY_RUN" -eq 1 ]; then info "[dry-run] CLAUDE.md 에 '$CLAUDE_LINE' 추가"
  else
    { [ -s "$CLAUDE_MD" ] && printf '\n'; printf '%s\n' "$CLAUDE_LINE"; } >> "$CLAUDE_MD"
    ok "CLAUDE.md: '$CLAUDE_LINE' 추가"
  fi
fi

AGENTS_MD="$TARGET/AGENTS.md"
if [ -f "$AGENTS_MD" ] && grep -qF "$AGENTS_MARK" "$AGENTS_MD"; then
  ok "AGENTS.md: 이미 연결됨"
else
  if [ "$DRY_RUN" -eq 1 ]; then info "[dry-run] AGENTS.md 에 llm_wiki 읽기 지시 추가"
  else
    {
      [ -s "$AGENTS_MD" ] && printf '\n'
      cat <<EOF
$AGENTS_MARK
## llm_wiki

작업을 시작하기 전에 아래 문서를 읽고 따른다. 충돌하면 \`llm_wiki/00_AI_INSTRUCTIONS.md\`가 우선한다.

- \`llm_wiki/README.md\`
- \`llm_wiki/00_AI_INSTRUCTIONS.md\`
- \`llm_wiki/01_WRITING_GUIDELINES.md\`
- \`llm_wiki/HANDOVER.md\` (없으면 구현·수정 작업일 때 \`llm_wiki/02_HANDOVER_TEMPLATE.md\`로 만든다)
EOF
    } >> "$AGENTS_MD"
    ok "AGENTS.md: llm_wiki 읽기 지시 추가"
  fi
fi

printf '\n==> 결과\n'
if [ "$DRY_RUN" -eq 1 ]; then ok "dry-run 완료 (실제로 바꾼 것은 없습니다)"
else
  ok "적용 완료. commit은 하지 않았습니다."
  info "확인: cd \"$TARGET\" && git status"
  info "다음: Claude Code나 Codex에서 'llm_wiki 참고해서 앞으로 프로젝트 진행해줘' 라고 시작하면 됩니다."
fi
