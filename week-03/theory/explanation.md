# 3주차: EVM과 스마트컨트랙트 - 쉬운 설명

> 이 문서는 슬라이드의 내용을 **초보자도 이해할 수 있도록** 풀어서 설명합니다.

## 목차

1. [서론 - 자동 실행 기계 비유](#서론---자동-실행-기계-비유)
2. [EVM이란?](#evm이란)
3. [바이트코드와 컴파일](#바이트코드와-컴파일)
4. [Storage, Memory, Stack](#storage-memory-stack)
5. [가스 (Gas)](#가스-gas)
6. [보안: Reentrancy 공격](#보안-reentrancy-공격)
7. [보안: Storage 취약점](#보안-storage-취약점)
8. [핵심 요약](#핵심-요약)

---

## 서론 - 자동 실행 기계 비유

### 스마트 컨트랙트 = 자동 판매기 + 금고

**자동 판매기**를 떠올려보세요:
- 동전을 넣으면 음료가 나옴
- 사람이 개입하지 않아도 **규칙대로 동작**
- 규칙은 기계 안에 **미리 프로그래밍**되어 있음

**스마트 컨트랙트도 똑같습니다:**
- ETH를 보내면 정해진 동작 수행
- 사람이 개입하지 않아도 **코드대로 실행**
- 코드는 블록체인에 **영구적으로 저장**

### EVM = 이 기계를 돌리는 엔진

모든 자동 판매기에는 **작동 장치**가 필요하죠?
EVM(Ethereum Virtual Machine)이 바로 그 역할입니다.

> EVM = 스마트 컨트랙트를 실행하는 **가상 컴퓨터**

---

## EVM이란?

### 이더리움의 공용 컴퓨터

**EVM** = Ethereum Virtual Machine (이더리움 가상 머신)

전 세계 수천 개의 노드가 모두 **같은 EVM**을 돌립니다.

### 왜 "가상" 머신인가요?

실제 컴퓨터(Intel, AMD)가 아니라,
**소프트웨어로 만든 가상의 컴퓨터**이기 때문입니다.

장점:
- 어떤 컴퓨터에서든 **같은 결과**
- 운영체제(Windows, Mac, Linux)와 **무관**
- 악성 코드로부터 **격리**

### 결정론적 실행

> "같은 입력 = 같은 결과"

미국의 노드가 계산한 결과와
한국의 노드가 계산한 결과가 **100% 동일**합니다.

이것이 가능한 이유:
- 랜덤 함수 없음 (block.timestamp 등 사용)
- 네트워크 요청 불가 (외부 API 호출 불가)
- 파일 시스템 접근 불가

### 비유로 정리

| 현실 세계 | 이더리움 |
|-----------|----------|
| 계산기 | EVM |
| 계산식 | 스마트 컨트랙트 코드 |
| 숫자 입력 | 트랜잭션 데이터 |
| 계산 결과 | 상태 변화 |

> 전 세계가 **같은 계산기**를 사용하는 것과 같아요!

---

## 바이트코드와 컴파일

### Solidity는 EVM이 못 읽어요

우리가 작성하는 코드:
```solidity
function transfer(address to, uint amount) public {
    balance[msg.sender] -= amount;
    balance[to] += amount;
}
```

이 코드는 **사람이 읽기 쉽게** 작성된 것입니다.
EVM은 이걸 직접 이해하지 못합니다.

### 컴파일 = 번역

```
Solidity 코드 (사람용)
       ↓ 컴파일러 (solc)
바이트코드 (기계용)
```

바이트코드 예시:
```
0x608060405234801561001057600080fd5b5060...
```

이 숫자와 문자의 나열이 EVM이 이해하는 언어입니다.

### 배포 과정

1. Solidity 코드 작성
2. 컴파일러로 바이트코드 생성
3. 바이트코드를 담은 트랜잭션 전송
4. 블록에 포함되면 **컨트랙트 생성**
5. 이제 누구나 이 컨트랙트를 호출 가능

### Contract Address

컨트랙트도 EOA처럼 **주소**를 가집니다.

```
0x1234567890123456789012345678901234567890
```

이 주소로 트랜잭션을 보내면 컨트랙트 코드가 실행됩니다.

---

## Storage, Memory, Stack

### 세 가지 저장 공간

EVM에는 데이터를 저장하는 세 가지 공간이 있습니다.

| 구분 | 비유 | 특징 | 비용 |
|------|------|------|------|
| **Storage** | 금고 | 영구 저장, 블록체인에 기록 | 매우 비쌈 |
| **Memory** | 메모장 | 함수 실행 중만 유지 | 저렴 |
| **Stack** | 계산기 | 계산용, 256비트 워드 | 가장 저렴 |

### Storage: 영구 저장소 (금고)

```solidity
contract MyContract {
    uint public totalSupply = 1000;  // Storage에 저장됨
    mapping(address => uint) public balances;  // Storage에 저장됨
}
```

- 컨트랙트의 **상태 변수**들이 저장됨
- 트랜잭션이 끝나도 **값이 유지**됨
- 가장 비쌈 (20,000 gas for SSTORE)

### Memory: 임시 저장소 (메모장)

```solidity
function calculate() public pure returns (uint) {
    uint temp = 100;  // Memory에 저장됨
    return temp * 2;
}
```

- 함수 실행 중에만 존재
- 함수가 끝나면 **사라짐**
- Storage보다 훨씬 저렴

### Stack: 계산용 공간 (계산기)

- 연산의 중간 결과 저장
- 최대 1024개 항목
- 각 항목은 256비트 (32바이트)
- 가장 빠르고 저렴

### 언제 무엇을 쓰나요?

| 상황 | 사용할 공간 |
|------|-------------|
| 계정 잔액 저장 | Storage |
| 함수 내 임시 계산 | Memory |
| 덧셈, 뺄셈 연산 | Stack |

---

## 가스 (Gas)

### 가스 = 연료

자동차에 **휘발유**가 필요하듯,
트랜잭션에는 **가스**가 필요합니다.

### 왜 가스가 필요할까요?

**문제:** 누군가 무한 루프를 실행하면?
```solidity
while (true) {
    // 영원히 실행...
}
```

이 코드가 무료로 실행되면:
- 모든 노드가 **무한히** 계산해야 함
- 네트워크 전체가 **멈춤** (DoS 공격)

**해결:** 연산마다 가스 소모
- 가스가 떨어지면 실행 **중단**
- 악의적 코드도 유한한 비용
- 네트워크 보호!

### 가스 계산

```
총 비용 = Gas Used x Gas Price
```

예시:
- Gas Used: 21,000 (단순 전송)
- Gas Price: 50 Gwei
- 총 비용: 21,000 x 50 = 1,050,000 Gwei = 0.00105 ETH

### Gas Limit vs Gas Price

| 개념 | 설명 | 비유 |
|------|------|------|
| **Gas Limit** | 최대 사용할 가스량 | 주유 예산 |
| **Gas Price** | 가스 1단위 가격 | 리터당 가격 |
| **Gas Used** | 실제 사용된 가스 | 실제 주유량 |

> Gas Limit 설정이 너무 낮으면 트랜잭션이 **실패**합니다!
> (가스가 떨어져서 중간에 멈춤)

### 연산별 가스 비용

| 연산 | Gas | 설명 |
|------|-----|------|
| ADD | 3 | 덧셈 |
| MUL | 5 | 곱셈 |
| SLOAD | 2,100 | Storage 읽기 |
| SSTORE | 20,000 | Storage 쓰기 (새 값) |
| CALL | 2,600+ | 다른 컨트랙트 호출 |

> Storage 연산이 왜 비싼지 아시겠죠? **영구 저장**이니까요!

---

## 보안: Reentrancy 공격

### Reentrancy란?

**Reentrancy** = 재진입 = 다시 들어오기

함수가 **실행 중**인데, 같은 함수를 **다시 호출**하는 것입니다.

### 문제가 되는 이유

잘못된 코드:
```solidity
// 위험한 코드!
function withdraw() public {
    uint amount = balances[msg.sender];
    msg.sender.call{value: amount}("");  // 1. 먼저 돈을 보냄
    balances[msg.sender] = 0;            // 2. 그 다음 잔액을 0으로
}
```

공격 시나리오:
1. 공격자가 `withdraw()` 호출
2. 컨트랙트가 공격자에게 ETH 전송
3. 공격자의 `receive()` 함수가 **다시** `withdraw()` 호출
4. 잔액이 아직 0이 아니라서 **또 전송**
5. 2-4 반복... 컨트랙트 잔액 **전부 탈취**

### The DAO 해킹 (2016)

**역사상 가장 유명한 블록체인 해킹**

- 피해액: $60M (당시 이더리움 총 가치의 14%)
- 원인: Reentrancy 취약점
- 결과: 이더리움 **하드포크** (이더리움 클래식 탄생)

### 방어: Check-Effects-Interactions 패턴

**CEI 패턴** = 확인 -> 변경 -> 상호작용

```solidity
// 안전한 코드!
function withdraw() public {
    uint amount = balances[msg.sender];  // Check
    balances[msg.sender] = 0;            // Effects (먼저 잔액 변경)
    msg.sender.call{value: amount}("");  // Interactions (그 다음 전송)
}
```

순서가 중요합니다:
1. **Check:** 조건 확인
2. **Effects:** 상태 변경 (잔액 = 0)
3. **Interactions:** 외부 호출 (ETH 전송)

이렇게 하면 재진입해도 잔액이 이미 0이라서 탈취 불가!

---

## 보안: Storage 취약점

### Private != Secret (비밀이 아님!)

Solidity의 `private` 키워드:
```solidity
contract MyContract {
    uint private secretNumber = 42;  // private이니까 비밀?
}
```

**아닙니다!** `private`은:
- 다른 컨트랙트가 코드로 **접근 불가**
- 하지만 블록체인 데이터는 **누구나 읽을 수 있음**

### 왜 그럴까요?

블록체인은 **투명한 공개 장부**입니다.
모든 데이터가 모든 노드에 저장되어 있습니다.

```javascript
// 누구나 이렇게 읽을 수 있음
const slot0 = await ethers.provider.getStorageAt(contractAddress, 0);
console.log(slot0);  // secretNumber 값 출력!
```

### 저장하면 안 되는 것들

**절대 Storage에 저장하지 마세요:**
- 비밀번호
- Private Key
- 개인정보 (주민번호, 전화번호 등)
- 경쟁에서 유리해지는 비밀 정보

### 그러면 비밀 정보는 어떻게?

**Commit-Reveal 패턴:**

1. **Commit:** 비밀 값의 해시를 먼저 제출
   ```
   hash = keccak256(비밀값 + 소금)
   ```

2. **Reveal:** 나중에 실제 값을 공개
   ```
   실제 비밀값, 소금 제출 -> 해시 검증
   ```

예시: 가위바위보 게임
1. 둘 다 hash(선택 + 소금) 제출
2. 둘 다 제출 후, 실제 선택 공개
3. 해시가 맞으면 승자 결정

### 더 알아보기

- [OWASP SC08: Storage Vulnerabilities](https://owasp.org/www-project-smart-contract-top-10/)
- [용어 사전](../../resources/glossary.md) - 보안 관련 용어

---

## 핵심 요약

### 이번 주에 배운 것

1. **EVM**
   - 이더리움의 가상 컴퓨터
   - 모든 노드가 같은 결과 (결정론적)
   - 스마트 컨트랙트를 실행

2. **바이트코드**
   - Solidity -> 컴파일 -> 바이트코드
   - EVM이 이해하는 기계어

3. **Storage, Memory, Stack**
   - Storage: 영구, 비쌈 (금고)
   - Memory: 임시, 저렴 (메모장)
   - Stack: 계산용, 가장 빠름

4. **Gas**
   - 연산 비용 = DoS 공격 방지
   - Gas Used x Gas Price = 총 비용

5. **보안**
   - Reentrancy: CEI 패턴으로 방어
   - Private != Secret: 민감 정보 저장 금지

### 다음 단계

**4주차 예고: 네트워크와 블록**
- 블록은 어떻게 구성되나요?
- 합의 알고리즘이란?
- MPT(Merkle Patricia Trie)는 무엇인가요?

**복습 질문:**
1. Storage와 Memory의 차이는?
2. Reentrancy 공격은 어떻게 막나요?
3. 왜 Private 변수도 읽을 수 있나요?

---

*다음: [4주차 - 네트워크와 블록](../../week-04/theory/explanation.md)*
*용어가 어려우면: [용어 사전](../../resources/glossary.md)*
