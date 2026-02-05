# 3주차: EVM과 스마트컨트랙트 (EVM & Smart Contract)

## 학습 목표

이번 주를 마치면 다음을 할 수 있습니다:

- EVM의 동작 원리를 설명할 수 있습니다
- 가스 계산의 원리를 이해합니다
- 재진입 공격을 식별하고 방어할 수 있습니다
- CEI 패턴과 ReentrancyGuard를 적용할 수 있습니다

## 예상 소요 시간

**5-6시간**

- 이론: 2시간
- 개발: 3-4시간 (보안 실습 포함)

---

## 학습 내용

### 이론

| 자료 | 설명 |
|------|------|
| [슬라이드](theory/slides.md) | Marp 기반 프레젠테이션 (수업용) |
| [설명 문서](theory/explanation.md) | 한글 상세 설명 (복습용) |

**핵심 개념:**
- EVM 아키텍처 (Stack, Memory, Storage)
- 바이트코드와 Opcode
- 가스 계산과 최적화
- 🔐 보안: 재진입 공격 (The DAO 해킹)
- CEI 패턴 (Checks-Effects-Interactions)

### 개발

| 자료 | 설명 |
|------|------|
| [보안 패턴](dev/security-patterns.md) | 재진입 방어 가이드 |

**이번 주 과제:** [eth-homework/week-03/dev](https://github.com/Bay-17th/eth-homework/tree/main/week-03/dev)
- Vault.sol 취약점 분석
- VaultSecure.sol CEI 패턴 적용
- 13개 테스트 통과시키기

---

## 학습 순서

1. [슬라이드](theory/slides.md)로 핵심 개념 파악
2. [설명 문서](theory/explanation.md)로 깊이 이해
3. [보안 패턴](dev/security-patterns.md) 가이드 읽기
4. [eth-homework](https://github.com/Bay-17th/eth-homework)에서 Vault 보안 과제 완료

---

## 퀴즈

이번 주 퀴즈: [eth-homework/week-03/quiz](https://github.com/Bay-17th/eth-homework/tree/main/week-03/quiz)

---

## 다음 주차

[4주차: 네트워크와 블록](../week-04/README.md)

---

*[목차로 돌아가기](../README.md)*
