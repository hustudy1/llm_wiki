# llm_wiki 가이드

가이드 버전: `v0.4.0` (최종 갱신: 2026-07-07)

이 폴더는 **모든 프로젝트에서 AI(LLM)를 사용할 때 가장 기초가 되는 지시사항 묶음**이며,
`llm_wiki`라는 이름의 git 저장소로 관리한다. 새 프로젝트를 시작할 때 이 폴더를
프로젝트 루트에 `llm_wiki/` 이름 그대로 복사해서, 어떤 AI 모델·도구를 쓰든
동일한 규칙으로 작업하게 만드는 것이 목적이다.

## 폴더 구성

| 파일 | 용도 |
|------|------|
| `00_AI_INSTRUCTIONS.md` | AI에게 매 세션 주입하는 **핵심 지시사항** (6대 원칙 + 행동 규칙) |
| `01_WRITING_GUIDELINES.md` | llm_wiki 문서를 **생성·갱신하는 AI가 유의해야 할 사항** (공식 문서 근거 포함) |
| `02_HANDOVER_TEMPLATE.md` | 인수인계 문서 템플릿. 복사해서 `llm_wiki/HANDOVER.md`로 사용 |
| `03_REFERENCES.md` | 이 가이드의 근거가 된 공식 문서 출처 목록 |

## 새 프로젝트에 적용하는 방법

1. 이 저장소를 프로젝트 루트에 `llm_wiki/` 이름으로 복사한다.
   git clone으로 받았다면 복사본 안의 `.git` 폴더를 삭제한다
   (삭제하지 않으면 프로젝트 저장소가 이 폴더의 파일을 추적하지 못한다).
2. `02_HANDOVER_TEMPLATE.md`를 복사해 `llm_wiki/HANDOVER.md`를 만들고, 프로젝트 개요를 채운다.
   (직접 하지 않아도 AI가 첫 작업 시작 시 자동으로 만든다.)
3. AI 도구가 세션 시작 시 자동으로 읽도록 연결한다.
   - **Claude Code**: 프로젝트 루트 `CLAUDE.md`에 아래 한 줄을 추가한다 (`@` import 문법).
     ```
     @llm_wiki/00_AI_INSTRUCTIONS.md
     ```
   - **다른 에이전트 (Codex, Cursor, Jules 등)**: 프로젝트 루트에 `AGENTS.md`를 만들어 같은 내용을 넣거나,
     `00_AI_INSTRUCTIONS.md`의 내용을 각 도구의 시스템 프롬프트/규칙 파일에 넣는다.
   - Claude Code는 `AGENTS.md`를 직접 읽지 않으므로, 두 생태계를 같이 쓸 경우
     `CLAUDE.md`에서 `@AGENTS.md`로 import 하거나 심볼릭 링크(`ln -s AGENTS.md CLAUDE.md`)를 쓴다.
4. 프로젝트 운영 규칙에 따라 `llm_wiki/` 전체를 git에 커밋한다. 커밋은 사용자가 요청했거나
   팀 규칙에 명시된 경우에만 만든다.

## AI에게 요청하는 방법

사용자가 "이 프로젝트는 `llm_wiki/`를 참고해서 작업해줘"라고 말하면, AI는 아래 순서로 진행한다.

1. `README.md`, `00_AI_INSTRUCTIONS.md`, `01_WRITING_GUIDELINES.md`를 읽는다.
2. `llm_wiki/HANDOVER.md`가 있으면 읽는다.
3. `HANDOVER.md`가 없으면 `02_HANDOVER_TEMPLATE.md`를 복사해 `llm_wiki/HANDOVER.md`를 만든다.
4. 코드와 설정 파일에서 확인 가능한 항목은 채우고, 모르는 항목은 `[UNKNOWN]`으로 남긴다.
5. 비밀값은 적지 않는다. 환경 변수명과 보관 위치만 기록한다.
6. 작업이 끝나면 기록 기준에 해당하는 변화만 `HANDOVER.md`에 갱신한다.

## 버전과 동기화

- 프로젝트에 복사한 `llm_wiki/README.md`의 가이드 버전을 유지한다.
- 이 원본 가이드를 갱신하면 버전을 올리고, 적용 대상 프로젝트의 `llm_wiki/`와 차이를 비교해 반영한다.
- 프로젝트별로 바꾼 규칙은 `llm_wiki/HANDOVER.md` 또는 프로젝트 전용 문서에 이유와 함께 기록한다.
- 서로 다른 프로젝트의 `llm_wiki/`가 달라질 수 있다. 공통으로 유용한 변경만 이 원본 가이드에 되돌려 반영한다.

## 운영 원칙

- 지시 파일은 **짧고 구체적**으로 유지한다. 파일이 길어질수록 AI의 준수율이 떨어진다
  (Claude Code 공식 문서 권장: 파일당 200줄 이하).
- 규칙이 서로 모순되면 AI가 임의로 하나를 고른다. 주기적으로 검토해서 낡은 규칙을 지운다.
- 이 문서들은 "맥락"이지 "강제 장치"가 아니다. 반드시 막아야 하는 행동은 도구의
  권한 설정(permissions)이나 hook 같은 기술적 수단으로 막는다.
