# 5주차: PoS와 합의 (Proof of Stake & Consensus)

## 학습 목표

이번 주를 마치면 다음을 할 수 있습니다:

- PoW에서 PoS로 전환한 이유를 설명할 수 있습니다
- 검증자의 역할과 슬래싱 조건을 이해합니다
- LMD-GHOST와 Casper FFG를 설명할 수 있습니다
- RainbowKit으로 지갑 연결 UI를 구현할 수 있습니다

## 예상 소요 시간

**5-6시간**

- 이론: 2-3시간
- 개발: 3시간

---

## 학습 내용

### 이론

| 자료 | 설명 |
|------|------|
| [슬라이드](theory/slides.md) | Marp 기반 프레젠테이션 (수업용) |
| [설명 문서](theory/explanation.md) | 한글 상세 설명 (복습용) |

**핵심 개념:**
- PoS vs PoW
- 검증자 라이프사이클 (deposited → active → exited)
- 슬래싱 조건 (이중 투표, 서라운드 투표)
- LMD-GHOST + Casper FFG
- RANDAO (랜덤 선출)

### 개발

| 자료 | 설명 |
|------|------|
| [RainbowKit 가이드](dev/rainbowkit-guide.md) | 지갑 연결 UI 구현 |

**핵심 컴포넌트:**
- `WagmiProvider > QueryClientProvider > RainbowKitProvider` 계층
- `ConnectButton` 커스터마이징
- 트랜잭션 상태 처리

---

## 학습 순서

1. [슬라이드](theory/slides.md)로 핵심 개념 파악
2. [설명 문서](theory/explanation.md)로 깊이 이해
3. [RainbowKit 가이드](dev/rainbowkit-guide.md) 따라하기
4. 지갑 연결 UI 직접 구현해보기

---

## 퀴즈

이번 주 퀴즈: [eth-homework/week-05/quiz](https://github.com/Bay-17th/eth-homework/tree/main/week-05/quiz)

---

## 다음 주차

[6주차: Beacon Chain과 Finality](../week-06/README.md)

---

*[목차로 돌아가기](../README.md)*
