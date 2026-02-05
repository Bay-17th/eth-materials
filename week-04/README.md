# 4주차: 네트워크와 블록 (Network & Block)

## 학습 목표

이번 주를 마치면 다음을 할 수 있습니다:

- P2P 네트워크와 노드의 역할을 설명할 수 있습니다
- 블록 구조와 MPT(Merkle Patricia Trie)를 이해합니다
- Eclipse Attack과 51% Attack을 설명할 수 있습니다
- wagmi를 사용해 블록체인과 연동할 수 있습니다

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
- P2P 네트워크와 노드 유형
- 블록 헤더와 바디
- MPT (Merkle Patricia Trie) - 3단계 진화
- 🔐 보안: Eclipse Attack, 51% Attack

### 개발

| 자료 | 설명 |
|------|------|
| [wagmi 기초](dev/wagmi-basics.md) | React + wagmi 연동 가이드 |

**핵심 hooks:**
- `useAccount` - 지갑 연결 상태
- `useReadContract` - 컨트랙트 읽기
- `useWriteContract` - 컨트랙트 쓰기

---

## 학습 순서

1. [슬라이드](theory/slides.md)로 핵심 개념 파악
2. [설명 문서](theory/explanation.md)로 깊이 이해
3. [wagmi 기초](dev/wagmi-basics.md) 가이드 따라하기
4. 프론트엔드 템플릿으로 실습

---

## 퀴즈

이번 주 퀴즈: [eth-homework/week-04/quiz](https://github.com/Bay-17th/eth-homework/tree/main/week-04/quiz)

---

## 다음 주차

[5주차: PoS와 합의](../week-05/README.md)

---

*[목차로 돌아가기](../README.md)*
