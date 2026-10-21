# 분야별 프롬프트 (domains)

빅데이터, 인프라, DB, AI/ML 작업에 쓰는 분야별 지침과 요청 양식이다.
`ai-prompt-library` 저장소(2026-05-13 최종 수정, 2026-10-21 보관 처리)의 분야별 자료를 옮겨 왔다.

이 폴더는 세션마다 자동으로 읽지 않는다. 해당 분야 작업을 할 때만 필요한 파일을 읽는다.
그래서 이 폴더가 있어도 평소 대화의 토큰 사용량은 늘지 않는다.

## 분야

| 분야 | 다루는 기술 | 지침 파일 |
|------|-------------|-----------|
| `bigdata-platform/` | Hadoop, Hive, Spark, Trino, Kafka, Flink | `bigdata-platform/system-prompts/bigdata-platform-prompts.md` |
| `infra/` | Docker, Kubernetes, CI/CD, 모니터링 | `infra/system-prompts/infra-prompts.md` |
| `db/` | RDBMS, NoSQL, 쿼리 최적화 | `db/system-prompts/db-prompts.md` |
| `ai/` | LLM, RAG, 프롬프트 엔지니어링, MLOps | `ai/system-prompts/ai-prompts.md` |

## 분야마다 들어 있는 것

| 폴더 | 내용 | 쓰는 법 |
|------|------|---------|
| `system-prompts/` | 역할, 기술 스택, 답변 기준, 출력 형식 | 작업 전에 AI가 읽는다 |
| `templates/` | 설계·트러블슈팅 요청 양식 | 사용자가 채워서 첫 메시지로 보낸다 |
| `few-shots/` | 잘 된 질문과 답변 예시 | 답변 형식을 맞출 때 참고한다 |
| `context-docs/` | 운영 환경 정보(버전, 노드 수 등)를 적는 빈 양식 | 프로젝트에 복사한 뒤 채운다. 비어 있으면 AI는 무시한다 |

## 요청 예시

> `llm_wiki/domains/bigdata-platform/system-prompts/bigdata-platform-prompts.md 참고해서 Spark OOM 해결해줘`

여러 분야가 걸친 작업은 관련 지침 파일을 함께 지정한다.

> `llm_wiki/domains/bigdata-platform/system-prompts/bigdata-platform-prompts.md와 llm_wiki/domains/infra/system-prompts/infra-prompts.md 참고해서 Spark on K8s 배포 구조 설계해줘`

## 공통 출력 형식

분야별 지침에 같은 형식이 들어 있다. 출처 표기와 확인되지 않은 정보 처리는
`00_AI_INSTRUCTIONS.md`의 6대 원칙을 따른다.

- 일반 답변: 설명 → 예시 → 출처
- 아키텍처 답변: 구조 설명 → 기술 비교표 → 트레이드오프 → 출처
- 코드/쿼리 답변: 목적 → 코드(주석 포함) → 성능 고려사항 → 출처
- 트러블슈팅: 오류 원인 → 즉시 조치 → 근본 해결 → 재발 방지 → 출처

## 주의

- 프로젝트 루트 `CLAUDE.md`에 이 폴더 파일을 `@경로`로 넣지 않는다.
  `@`로 넣으면 세션 시작마다 자동으로 읽혀 토큰을 계속 쓴다.
- `context-docs/`에 실제 운영 환경을 채울 때는 서버 주소, 계정, 비밀번호 같은 비밀값을 적지 않는다.
- 예시(`few-shots/`)의 버전과 수치는 예시일 뿐이다. 실제 작업에서는 해당 버전의 공식 문서를 확인한다.
- 링크는 2026-10-21에 확인했다. 없어진 Spark 3.4.1 문서는 최신(`latest`) 문서로,
  Trino join-ordering 문서는 cost-based-optimizations 문서로 바꿨다.
