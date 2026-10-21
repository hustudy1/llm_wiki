# Few-shot 예시: 쿼리 최적화

이 파일은 AI가 쿼리 최적화 질문에 어떻게 답해야 하는지 보여주는 예시입니다.
templates/query-optimization.md와 함께 전송하면 답변 품질이 향상됩니다.

---

## 예시 Q&A

**Q:**
```
[쿼리 최적화 요청]

## 실행 환경
- 엔진: Trino 430
- 테이블 규모: orders(5억 건), users(1천만 건)

## 현재 쿼리
SELECT u.name, COUNT(o.id) AS order_count, SUM(o.amount) AS total_amount
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.created_at >= '2024-01-01'
GROUP BY u.name
ORDER BY total_amount DESC
LIMIT 100;

## 성능 문제
- 현재 실행 시간: 약 4분
- 목표: 30초 이내
- orders 테이블은 created_at 기준 월별 파티션 적용됨
```

**A:**
```
[목적]
대용량 주문 테이블과 사용자 테이블의 조인 후 집계 쿼리 최적화

[개선 쿼리]
-- 1. 파티션 pruning 명시적 적용 + 브로드캐스트 조인 유도
SELECT u.name,
       COUNT(o.id)    AS order_count,
       SUM(o.amount)  AS total_amount
FROM orders o
-- Trino: 파티션 컬럼 조건을 WHERE절에 명시해야 pruning 적용
JOIN /*+ BROADCAST(u) */ users u ON o.user_id = u.id
WHERE o.created_at >= DATE '2024-01-01'  -- 리터럴 대신 DATE 타입 명시
  AND o.created_at <  DATE '2025-01-01'  -- 상한 조건 추가로 pruning 범위 확정
GROUP BY u.name
ORDER BY total_amount DESC
LIMIT 100;

[성능 고려사항]
1. BROADCAST 힌트
   - users(1천만 건)는 Trino 기본 브로드캐스트 임계값(1GB)을 초과할 수 있음
   - 실제 크기 확인 후 적용: SHOW STATS FOR users;
   - 초과 시 session 속성으로 임계값 상향 가능
     SET SESSION join_distribution_type = 'BROADCAST';

2. 파티션 pruning 확인
   EXPLAIN SELECT ... 실행 후 TableScan 노드에서
   "partitions: X out of Y" 확인 → 범위가 의도한 대로 좁혀졌는지 검증

3. 집계 선행 (필요 시)
   -- users 조인 전 orders에서 먼저 집계하면 조인 데이터 크기 감소
   WITH order_agg AS (
     SELECT user_id, COUNT(id) AS order_count, SUM(amount) AS total_amount
     FROM orders
     WHERE created_at >= DATE '2024-01-01'
     GROUP BY user_id
   )
   SELECT u.name, oa.order_count, oa.total_amount
   FROM order_agg oa
   JOIN users u ON oa.user_id = u.id
   ORDER BY oa.total_amount DESC
   LIMIT 100;

[출처]
- Trino 조인 전략: https://trino.io/docs/current/optimizer/cost-based-optimizations.html
- Trino 파티션 pruning: https://trino.io/docs/current/connector/hive.html#partition-pruning
- Trino SQL 힌트: https://trino.io/docs/current/sql/select.html#join-hints
```
