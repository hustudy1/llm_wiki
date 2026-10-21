# CI/CD 파이프라인 설계 요청 템플릿

아래 항목을 채워서 대화 첫 메시지로 전송합니다.

---

```
[CI/CD 파이프라인 설계 요청]

## 목적
-

## 기술 스택
- CI/CD 도구: (예: GitLab CI / GitHub Actions / Jenkins)
- 배포 도구: (예: ArgoCD / Helm / kubectl)
- 컨테이너 레지스트리: (예: Harbor / ECR / DockerHub)

## 파이프라인 단계 (필요한 항목 체크)
- [ ] 코드 린트 / 정적 분석
- [ ] 단위 테스트
- [ ] 통합 테스트
- [ ] Docker 이미지 빌드
- [ ] 이미지 보안 스캔
- [ ] 스테이징 배포
- [ ] 프로덕션 배포 (수동 승인 / 자동)
- [ ] 배포 후 스모크 테스트

## 요구사항
- 배포 환경: (예: dev / staging / prod)
- 배포 전략: (Rolling / Blue-Green / Canary)
- 롤백 방식:
- 알림: (Slack / 이메일 / 없음)

## 추가 요구사항
-
```
