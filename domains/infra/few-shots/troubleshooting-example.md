# Few-shot 예시: 인프라 트러블슈팅

이 파일은 AI가 인프라 트러블슈팅 질문에 어떻게 답해야 하는지 보여주는 예시입니다.
templates/troubleshooting.md와 함께 전송하면 답변 품질이 향상됩니다.

---

## 예시 Q&A

**Q:**
```
[트러블슈팅 요청]

## 오류 상황
- 오류 메시지: OOMKilled (exit code 137)
- 발생 컴포넌트: Pod (Spark Driver)
- 발생 시점: 대용량 배치 잡 실행 30분 후
- 발생 빈도: 항상

## 환경
- Kubernetes 1.28
- 노드 스펙: 32 CPU / 128GB 메모리
- resources.limits.memory: 8Gi

## 관련 이벤트
- kubectl describe pod 결과: Last State: Terminated, Reason: OOMKilled
```

**A:**
```
[오류 원인]
OOMKilled(exit code 137)는 컨테이너가 resources.limits.memory를 초과하여
Linux OOM Killer에 의해 강제 종료된 것입니다.
Spark Driver는 JVM 힙 외에도 off-heap 메모리와 JVM 오버헤드를 사용하므로
limits.memory를 JVM 힙과 동일하게 설정하면 초과됩니다.

출처: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

[즉시 조치]
# 현재 메모리 사용량 확인
kubectl top pod <pod-name> -n <namespace>

# limits.memory를 JVM 힙 대비 1.5~2배로 임시 상향
resources:
  requests:
    memory: "8Gi"
  limits:
    memory: "12Gi"   # 기존 8Gi → 12Gi

[근본 해결]
# 변경 전
resources:
  limits:
    memory: "8Gi"
env:
  - name: SPARK_DRIVER_MEMORY
    value: "8g"   # JVM 힙과 limits가 동일 → OOM 필연적

# 변경 후 (JVM 힙 + 오버헤드 분리 설정)
resources:
  requests:
    memory: "8Gi"
  limits:
    memory: "11Gi"  # JVM 힙(8g) + 오버헤드(~2g) + 여유(1g)
env:
  - name: SPARK_DRIVER_MEMORY
    value: "8g"
  - name: SPARK_DRIVER_MEMORY_OVERHEAD
    value: "2048"   # MB 단위

[재발 방지]
- kubectl top pod 또는 Grafana로 실제 메모리 사용량 모니터링
- LimitRange로 네임스페이스 기본 limits 설정
- ResourceQuota로 네임스페이스 전체 메모리 상한 관리
- Vertical Pod Autoscaler(VPA) 도입 검토 (자동 리소스 추천)

[출처]
- K8s 리소스 관리: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- K8s OOMKilled 원인: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
```
