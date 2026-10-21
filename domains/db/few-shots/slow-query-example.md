# Few-shot 예시: 슬로우 쿼리 분석

이 파일은 AI가 슬로우 쿼리 분석 질문에 어떻게 답해야 하는지 보여주는 예시입니다.
templates/slow-query.md와 함께 전송하면 답변 품질이 향상됩니다.

---

## 예시 Q&A

**Q:**
```
[슬로우 쿼리 분석 요청]

## 실행 환경
- DB: PostgreSQL 15.4
- 테이블 규모: orders(3억 건, 약 200GB)

## 슬로우 쿼리
SELECT *
FROM orders
WHERE status = 'PENDING'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

## 성능 문제
- 현재 실행 시간: 약 45초
- 목표: 1초 이내
- 실행 빈도: 초당 50회 (API 호출)

## 인덱스 정보
- 현재 인덱스: CREATE INDEX idx_orders_created_at ON orders(created_at);
```

**A:**
```
[목적]
최근 7일 내 PENDING 상태 주문 조회 쿼리 최적화

[원인 분석]
1. 단일 컬럼 인덱스 비효율
   현재 idx_orders_created_at은 created_at만 인덱싱하므로
   status = 'PENDING' 필터를 인덱스 스캔 후 추가로 적용 (Index Scan + Filter)
   → status 선택도가 낮을수록(PENDING 비율이 높을수록) 더 많은 행을 필터링해야 함

2. SELECT * 사용
   불필요한 컬럼까지 모두 fetch → I/O 증가

[개선 방법]

# 1. 복합 인덱스 생성 (status + created_at)
CREATE INDEX idx_orders_status_created_at
ON orders(status, created_at DESC)
WHERE status = 'PENDING';  -- 부분 인덱스: PENDING 행만 인덱싱하여 크기 최소화

# 2. 필요한 컬럼만 SELECT
SELECT id, user_id, amount, created_at
FROM orders
WHERE status = 'PENDING'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

# 3. 인덱스 적용 확인
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, amount, created_at
FROM orders
WHERE status = 'PENDING'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
-- Index Scan using idx_orders_status_created_at 확인

[성능 고려사항]
- 부분 인덱스(WHERE status = 'PENDING')는 PENDING 데이터 비율에 따라 효과 차이
  PENDING 비율이 낮을수록 인덱스 크기가 작아져 효과 큼
- 인덱스 생성 시 CONCURRENTLY 옵션으로 운영 중 잠금 없이 생성 가능
  CREATE INDEX CONCURRENTLY idx_orders_status_created_at ON orders(status, created_at DESC) WHERE status = 'PENDING';
- 통계 정보 최신화: VACUUM ANALYZE orders;

[출처]
- PostgreSQL 인덱스 전략: https://www.postgresql.org/docs/15/indexes-partial.html
- PostgreSQL EXPLAIN: https://www.postgresql.org/docs/15/sql-explain.html
- PostgreSQL 복합 인덱스: https://www.postgresql.org/docs/15/indexes-multicolumn.html
```
