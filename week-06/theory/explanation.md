# 6주차: Beacon Chain/Finality 상세 설명

Beacon Chain, Finality, Casper를 처음 배우는 분들을 위한 상세 설명입니다.

---

## 1. 비유로 시작하기

Beacon Chain과 Finality를 이해하는 가장 쉬운 방법은 **은행 정산**을 떠올리는 것입니다.

### 은행 정산으로 생각하기

1. **거래 발생:** 하루 동안 많은 거래가 일어납니다
2. **임시 처리:** 거래는 즉시 반영되지만 "보류" 상태
3. **일일 정산:** 하루가 끝나면 모든 거래를 "확정"
4. **취소 불가:** 정산 후에는 번복할 수 없음

> 이더리움도 비슷해요!
> 거래는 바로 처리되지만, "Finality" 이후에야 진짜 확정됩니다.

---

## 2. Beacon Chain = 중앙 통제탑

### Beacon Chain이란?

**Beacon Chain**은 이더리움의 **합의 계층(Consensus Layer)**입니다.

**비유:** 공항 관제탑
- 비행기(트랜잭션)의 이착륙을 조정
- 충돌(충돌하는 블록)을 방지
- 전체 일정(블록 생성)을 관리

### The Merge 이후 구조

이더리움은 이제 **두 개의 계층**으로 구성됩니다:

**1. 실행 계층 (Execution Layer)**
- 트랜잭션 처리
- 스마트 컨트랙트 실행
- 상태(State) 관리

**2. 합의 계층 (Consensus Layer) = Beacon Chain**
- 검증자 관리
- 블록 순서 결정
- 최종성(Finality) 보장

**비유:** 회사 구조
- 실행 계층 = 실무 부서 (실제 일 처리)
- 합의 계층 = 경영진 (의사결정)

### Engine API

두 계층은 **Engine API**로 통신합니다:
- 실행 계층: "이 블록 내용 처리해주세요"
- 합의 계층: "이 블록이 확정되었습니다"

---

## 3. Slot/Epoch = 시간표

### Slot이란?

**Slot**은 블록이 생성될 수 있는 **시간 간격**입니다.

- 각 슬롯 = **12초**
- 슬롯마다 **1명**의 블록 제안자 선택

**비유:** 기차 시간표
- 12초마다 기차(블록)가 출발할 수 있는 시간
- 기차가 안 오면(제안자 오프라인) 그 시간은 비어있음

### Epoch이란?

**Epoch**은 32개의 슬롯을 묶은 것입니다.

- 1 Epoch = 32 Slots = **384초 = 6.4분**

**비유:** 학교 시간표
- 1교시, 2교시, ... 32교시 = 1 Epoch
- 각 교시는 12초

### 왜 Epoch으로 묶나요?

1. **검증자 역할 재배정:** 에폭마다 새로 섞음
2. **Finality 체크포인트:** 에폭 시작점에서 확정
3. **보상/패널티 정산:** 에폭 단위로 계산

### Checkpoint란?

**Checkpoint**는 각 에폭의 **첫 번째 슬롯**에 있는 블록입니다.

**비유:** 버스 정류장
- 정기적으로 확인하는 지점
- "여기까지는 확실해"라고 표시하는 곳

---

## 4. Finality = 최종 확정

### Finality란?

**Finality(최종성)**는 트랜잭션이 **절대 변경되지 않음**을 보장하는 것입니다.

**비유:** 계약서 공증
- 공증 전: 계약 내용 변경 가능
- 공증 후: 법적 구속력 발생, 변경 불가

### 왜 Finality가 중요한가요?

**Finality 없이:**
- 블록이 추가되어도 재조직 가능성 있음
- "확인 6번 기다리세요" (비트코인)
- 100% 확정은 없음

**Finality 있으면:**
- 특정 시점 이후 **절대 변경 불가**
- 안심하고 거래 완료 처리 가능
- 1/3 이상 지분 슬래싱 없이는 번복 불가

### 2단계 확정 과정

**1단계: Justification (정당화)**
- Epoch의 checkpoint가 **2/3+ 검증자** 증명을 받음
- "이 블록이 유효해 보여요"

**2단계: Finalization (최종화)**
- Justified된 checkpoint의 **다음 epoch**도 justified되면
- 이전 checkpoint가 **finalized**됨

**타임라인:**
```
Epoch N: Checkpoint 생성
Epoch N+1: 2/3+ 증명 → Justified!
Epoch N+2: 다음도 Justified → Epoch N이 Finalized!
```

**소요 시간:** 약 **12.8분** (2 epochs)

### 왜 2단계인가요?

**빠른 finality의 위험:**
- 네트워크 지연으로 잘못된 블록 확정 가능
- 한번 확정되면 되돌릴 수 없음!

**2단계의 장점:**
- 첫 번째 확인: "이게 맞아 보여"
- 두 번째 확인: "확실해, 확정!"
- 중간에 문제 발견하면 복구 가능

---

## 5. Casper = 2/3 동의 규칙

### Casper FFG란?

**Casper FFG(Friendly Finality Gadget)**는 이더리움의 finality 메커니즘입니다.

**비유:** 배심원 평결
- 12명 중 **2/3 이상**(8명+)이 동의해야 평결
- 소수가 반대해도 결정 가능
- 명확한 기준으로 논쟁 없이 결정

### 핵심 규칙

1. **2/3+ 동의 필요:** 검증자 지분의 2/3 이상이 투표
2. **Slashing으로 안전성 보장:** 규칙 위반 시 지분 손실
3. **수학적 보장:** 충돌하는 두 블록 모두 finalize 불가

### Casper의 안전성 보장

**핵심 질문:** 두 개의 충돌하는 블록이 동시에 finalize될 수 있나요?

**답:** 불가능합니다!

**이유:**
- 블록 A와 블록 B가 충돌
- 둘 다 finalize되려면 각각 2/3+ 투표 필요
- 그러면 최소 1/3+ 검증자가 **둘 다에 투표**해야 함
- 둘 다 투표 = **Double voting** = **슬래싱!**
- 1/3+ 지분이 소각됨

**결론:** 1/3 이상의 지분을 잃지 않고는 finality를 깰 수 없음

---

## 6. Fork Choice = 어느 체인을 따를까

### 포크(Fork)란?

**포크**는 블록체인이 두 갈래로 나뉘는 것입니다.

```
        ┌── 블록 A
블록 X ─┤
        └── 블록 B
```

**왜 발생하나요?**
- 두 검증자가 거의 동시에 블록 제안
- 네트워크 지연으로 다른 블록을 먼저 받음
- 일시적으로 "어느 게 정답?"인 상황

### LMD-GHOST란?

**LMD-GHOST**는 이더리움의 **Fork Choice Rule**입니다.

이름 풀이:
- **L**atest **M**essage **D**riven: 가장 최근 메시지 기반
- **G**reediest **H**eaviest **O**bserved **S**ub**t**ree: 가장 무거운 서브트리

### 어떻게 동작하나요?

1. 각 검증자의 **가장 최근 증명**만 사용
2. 분기점에서 **더 많은 증명을 받은 쪽** 선택
3. 반복해서 "가장 무거운" 체인 결정

**비유:** 인기 투표
- 여러 후보(체인) 중에서
- 가장 많은 표(증명)를 받은 후보(체인) 선택

### Fork Choice + Finality

두 메커니즘은 **서로 다른 역할**을 합니다:

| 메커니즘 | 역할 | 특징 |
|----------|------|------|
| **LMD-GHOST** | 실시간 체인 선택 | 빠름, 일시적 |
| **Casper FFG** | 최종 확정 | 느림, 영구적 |

**비유:** 영화 예매
- Fork Choice = 좌석 선택 (바꿀 수 있음)
- Finality = 결제 완료 (취소 어려움)

---

## 7. 6주 과정 총정리

### 배운 내용 흐름

**Week 1: State/Account**
- 상태 머신 개념
- EOA vs CA
- World State

**Week 2: Transaction/Signature**
- 트랜잭션 구조
- 서명 원리
- 가스 시스템

**Week 3: EVM/Gas**
- EVM 동작 원리
- 옵코드와 스택
- 가스 계산

**Week 4: Block/Network**
- 블록 구조
- 체인 연결
- MPT, P2P

**Week 5: PoS/Consensus**
- 합의 메커니즘
- 검증자
- RANDAO, Slashing

**Week 6: Beacon Chain/Finality**
- Beacon Chain
- Slot/Epoch
- Finality, Casper

### 이더리움 데이터 흐름

```
1. 사용자가 트랜잭션 생성
2. 개인키로 서명
3. 네트워크에 전파
4. 검증자가 블록에 포함
5. EVM이 트랜잭션 실행
6. State 변경
7. 다른 검증자들이 증명
8. Finality 달성!
```

---

## 8. 다음 단계 안내

### 이론 과정 완료!

6주간의 이론 과정을 완료했습니다.

**배운 것:**
- 이더리움의 전체 구조
- 트랜잭션부터 Finality까지
- 보안 개념과 위험

### 다음은?

**개발 실습:**
- Solidity로 스마트 컨트랙트 작성
- Foundry로 테스트하기
- 나만의 DApp 만들기

**추천 다음 단계:**
1. Solidity 기초 문법
2. OpenZeppelin 컨트랙트 학습
3. 간단한 토큰 만들기 (ERC-20)
4. NFT 만들기 (ERC-721)

### 계속 공부하려면

- [Ethereum.org 개발자 문서](https://ethereum.org/developers)
- [Solidity 공식 문서](https://docs.soliditylang.org)
- [Foundry Book](https://book.getfoundry.sh)

---

## 이 주의 다른 자료

- [slides.md](./slides.md) - 발표용 슬라이드
- [용어 사전](../../resources/glossary.md) - 핵심 용어 정리

---

## 용어 정리

| 용어 | 설명 |
|------|------|
| Beacon Chain | 이더리움의 합의 계층 |
| Consensus Layer | 합의를 담당하는 계층 |
| Execution Layer | 트랜잭션 실행을 담당하는 계층 |
| Slot | 12초 단위의 시간 간격 |
| Epoch | 32개 슬롯의 묶음 (6.4분) |
| Checkpoint | 에폭 시작점의 블록 |
| Finality | 트랜잭션의 최종 확정 |
| Justification | Finality 1단계 (2/3+ 증명) |
| Finalization | Finality 2단계 (최종 확정) |
| Casper FFG | Friendly Finality Gadget |
| Fork | 블록체인이 두 갈래로 나뉘는 것 |
| Fork Choice | 어느 체인을 따를지 결정하는 규칙 |
| LMD-GHOST | 이더리움의 Fork Choice Rule |
| Engine API | 두 계층 간 통신 인터페이스 |

> 더 많은 용어는 [용어 사전](../../resources/glossary.md)을 참고하세요!

---

## 축하합니다!

6주간의 이더리움 이론 과정을 완료했습니다.

이제 이더리움이 어떻게 동작하는지 **전체 그림**을 알게 되었습니다.

다음 단계는 **직접 만들어보는 것**입니다!

질문이 있으면 Bay Slack #ethereum-questions에 올려주세요.
