# Few-shot 예시: RAG 파이프라인 설계

이 파일은 AI가 RAG 파이프라인 설계 질문에 어떻게 답해야 하는지 보여주는 예시입니다.
templates/rag-pipeline.md와 함께 전송하면 답변 품질이 향상됩니다.

---

## 예시 Q&A

**Q:**
```
[RAG 파이프라인 설계 요청]

## 목적
사내 기술 문서(PDF, Confluence) 기반 QA 챗봇 구축

## 데이터 소스
- 문서 유형: PDF(약 500개), Confluence 페이지(약 2,000개)
- 업데이트 주기: 주 1회 배치 동기화

## LLM 환경
- 모델: Claude claude-sonnet-4-6 (Anthropic API)
- 컨텍스트 길이: 200K 토큰

## 요구사항
- 응답 지연: 5초 이내
- 출처 표시 필요
- 한국어 지원
```

**A:**
```
[구조 설명]

전체 흐름:
문서 수집 → 청킹 → 임베딩 → 벡터 DB 저장
                                    ↓
사용자 질문 → 쿼리 임베딩 → 유사도 검색 → 컨텍스트 조합 → LLM 응답

[컴포넌트 설계]

1. 문서 수집 및 전처리
   - PDF: PyMuPDF(fitz) → 텍스트 추출 + 메타데이터(파일명, 페이지) 보존
   - Confluence: Confluence REST API v2 → 페이지 본문 + 제목 + URL 추출
   - 청킹: RecursiveCharacterTextSplitter (chunk_size=512, overlap=64)
     → 한국어는 문장 경계 고려, 코드 블록은 분리하지 않음

2. 임베딩
   - 모델: text-embedding-3-large (OpenAI) 또는 multilingual-e5-large (로컬)
   - 한국어 지원 및 성능 기준: multilingual-e5-large 권장
   - 배치 처리로 API 비용 최소화

3. 벡터 DB
   - 선택: pgvector (PostgreSQL 확장)
     → 기존 PostgreSQL 인프라 재활용, 메타데이터 필터링이 SQL로 가능
   - 인덱스: IVFFlat (검색 속도 우선) 또는 HNSW (정확도 우선, pgvector 0.5+)

4. 검색 전략
   - Hybrid Search: 벡터 유사도 + BM25 키워드 검색 결합 (RRF 앙상블)
   - 한국어 키워드 검색 정확도 향상에 효과적

5. LLM 호출 (Claude claude-sonnet-4-6)
   - 시스템 프롬프트에 "출처를 반드시 명시하라" 지시
   - 검색된 청크에 출처(문서명, URL, 페이지) 포함하여 컨텍스트 구성

[기술 비교표]

| 항목 | 선택 | 대안 | 이유 |
|---|---|---|---|
| 벡터 DB | pgvector | Chroma, Pinecone | 기존 PG 인프라 활용, SQL 필터링 |
| 임베딩 | multilingual-e5 | text-embedding-3 | 한국어 성능, 로컬 실행 가능 |
| 프레임워크 | LangChain | LlamaIndex | 문서 로더 생태계 풍부 |

[트레이드오프]
- pgvector vs Pinecone: pgvector는 운영 부담 있으나 비용 절감 / Pinecone은 관리형이나 비용 발생
- 청크 크기: 작을수록 검색 정밀도↑, 클수록 컨텍스트 풍부 → 512 토큰이 일반적 균형점

[출처]
- Anthropic Claude API: https://platform.claude.com/docs/en/api/overview
- pgvector: https://github.com/pgvector/pgvector
- LangChain RAG: https://docs.langchain.com/oss/python/deepagents/rag
- multilingual-e5: https://huggingface.co/intfloat/multilingual-e5-large
```
