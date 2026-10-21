# Few-shot 예시: 빅데이터 트러블슈팅

이 파일은 AI가 트러블슈팅 질문에 어떻게 답해야 하는지 보여주는 예시입니다.
templates/troubleshooting.md와 함께 전송하면 답변 품질이 향상됩니다.

---

## 예시 Q&A

**Q:**
```
[트러블슈팅 요청]

## 오류 상황
- 오류 메시지: java.lang.OutOfMemoryError: GC overhead limit exceeded
- 발생 컴포넌트: Spark (executor)
- 발생 시점: 대용량 조인 쿼리 실행 시
- 발생 빈도: 항상

## 환경
- Spark 버전: 3.4.1
- 클러스터: 노드 10개, 노드당 메모리 64GB
- 실행 방식: 배치

## 현상
- 정상: 소규모 데이터 조인 시 정상 동작
- 현재: 1억 건 이상 조인 시 executor OOM 발생

## 시도한 것
- executor 메모리를 4g → 8g로 증가시켰으나 동일 오류 발생
```

**A:**
```
[오류 원인]
GC overhead limit exceeded는 JVM이 GC에 전체 시간의 98% 이상을 소비하면서도
힙 메모리의 2% 미만을 회수하는 경우 발생합니다.
Spark에서는 대용량 조인 시 executor 힙에 데이터가 과적재될 때 주로 발생합니다.

원인 1: 데이터 스큐(Data Skew) - 특정 키에 데이터가 집중되어 일부 executor에 과부하
원인 2: executor 메모리 설정 부족 또는 메모리 분할 비율 불균형
원인 3: 브로드캐스트 조인 미적용 - 소규모 테이블임에도 Sort Merge Join 사용

출처: https://spark.apache.org/docs/latest/tuning.html#memory-management-overview

[즉시 조치]
# 1. 데이터 스큐 확인 (Spark UI > Stages > Task 분포 확인)
# executor 메모리 오버헤드 증가
--conf spark.executor.memoryOverhead=2g

# 2. 브로드캐스트 조인 임계값 확대 (소규모 테이블이 있는 경우)
--conf spark.sql.autoBroadcastJoinThreshold=209715200  # 200MB

[근본 해결]
# 변경 전
spark.executor.memory=8g
spark.executor.memoryOverhead=1g  # 기본값

# 변경 후 (메모리 분할 재조정)
spark.executor.memory=10g
spark.executor.memoryOverhead=2g
spark.memory.fraction=0.8           # 실행+저장 메모리 비율 상향
spark.memory.storageFraction=0.3

# 데이터 스큐 해소 (salting 기법)
-- 조인 키에 랜덤 값 추가하여 파티션 분산

[재발 방지]
- Spark UI에서 Task 실행 시간 분포 모니터링 (최대/중간값 차이가 3배 이상이면 스큐 의심)
- spark.sql.adaptive.enabled=true 설정으로 AQE(Adaptive Query Execution) 활성화
  → 런타임 스큐 자동 감지 및 파티션 재조정 (Spark 3.0+)

[출처]
- Spark 튜닝 가이드: https://spark.apache.org/docs/latest/tuning.html
- AQE 공식 문서: https://spark.apache.org/docs/latest/sql-performance-tuning.html#adaptive-query-execution
```
