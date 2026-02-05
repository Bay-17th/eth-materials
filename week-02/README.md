# 2주차: 트랜잭션과 서명 (Transaction & Signature)

## 학습 목표

이번 주를 마치면 다음을 할 수 있습니다:

- 트랜잭션의 구조와 각 필드의 역할을 설명할 수 있습니다
- 디지털 서명의 원리와 중요성을 이해합니다
- Private Key 보안의 중요성을 사례로 설명할 수 있습니다
- Foundry로 테스트를 작성할 수 있습니다

## 예상 소요 시간

**4-5시간**

- 이론: 2시간
- 개발: 2-3시간

---

## 학습 내용

### 이론

| 자료 | 설명 |
|------|------|
| [슬라이드](theory/slides.md) | Marp 기반 프레젠테이션 (수업용) |
| [설명 문서](theory/explanation.md) | 한글 상세 설명 (복습용) |

**핵심 개념:**
- 트랜잭션 필드 (nonce, gasPrice, gasLimit, to, value, data, v/r/s)
- ECDSA 서명과 검증
- Private Key → Public Key → Address
- EIP-1559 (Type 2 트랜잭션)
- 🔐 보안: Ronin Bridge 해킹 사례

### 개발

| 자료 | 설명 |
|------|------|
| [Foundry 테스팅](dev/foundry-testing.md) | 테스트 작성 가이드 |

**이번 주 과제:** [eth-homework/week-02/dev](https://github.com/Bay-17th/eth-homework/tree/main/week-02/dev)
- SimpleStorage.sol TODO 완성하기
- 테스트 통과시키기

---

## 학습 순서

1. [슬라이드](theory/slides.md)로 핵심 개념 파악
2. [설명 문서](theory/explanation.md)로 깊이 이해
3. [Foundry 테스팅](dev/foundry-testing.md) 가이드 읽기
4. [eth-homework](https://github.com/Bay-17th/eth-homework)에서 SimpleStorage.sol 과제 완료

---

## 퀴즈

이번 주 퀴즈: [eth-homework/week-02/quiz](https://github.com/Bay-17th/eth-homework/tree/main/week-02/quiz)

---

## 다음 주차

[3주차: EVM과 스마트컨트랙트](../week-03/README.md)

---

*[목차로 돌아가기](../README.md)*
