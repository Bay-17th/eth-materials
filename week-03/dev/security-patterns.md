# 스마트 컨트랙트 보안 패턴

> 이 문서는 Week 3 개발 과제의 보안 패턴 가이드입니다.
> 재진입 공격과 방어 패턴을 상세히 다룹니다.

---

## 목차

1. [왜 보안이 중요한가?](#1-왜-보안이-중요한가)
2. [재진입 공격 (Reentrancy Attack)](#2-재진입-공격-reentrancy-attack)
3. [Checks-Effects-Interactions (CEI) 패턴](#3-checks-effects-interactions-cei-패턴)
4. [OpenZeppelin ReentrancyGuard](#4-openzeppelin-reentrancyguard)
5. [다른 보안 고려사항](#5-다른-보안-고려사항)
6. [보안 체크리스트](#6-보안-체크리스트)

---

## 1. 왜 보안이 중요한가?

### 스마트 컨트랙트의 특수성

스마트 컨트랙트는 일반 소프트웨어와 다른 중요한 특성들을 가집니다:

| 특성 | 설명 | 위험 |
|------|------|------|
| **불변성** | 배포 후 코드 수정 불가 | 버그 수정 불가능 |
| **투명성** | 모든 코드가 공개됨 | 공격자가 취약점 분석 가능 |
| **자금 관리** | 직접 자산을 보관/이동 | 해킹 시 즉시 자금 손실 |
| **자동 실행** | 조건 충족 시 자동 실행 | 악의적 호출 차단 어려움 |

### 실제 해킹 사례

| 사건 | 연도 | 피해 금액 | 취약점 |
|------|------|----------|--------|
| The DAO | 2016 | $60M | 재진입 공격 |
| Parity Wallet | 2017 | $150M | 접근 제어 미흡 |
| Ronin Bridge | 2022 | $625M | 프라이빗 키 유출 |
| Wormhole | 2022 | $320M | 서명 검증 우회 |

**교훈**: 한 번의 취약점이 수천억 원의 손실로 이어질 수 있습니다.

---

## 2. 재진입 공격 (Reentrancy Attack)

### 공격 원리

재진입 공격은 **외부 호출(external call)** 중에 호출된 컨트랙트가 **다시 원래 함수를 호출**하는 공격입니다.

```
┌─────────────────────────────────────────────────────────────────┐
│                      재진입 공격 흐름                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Attacker                    Vault (취약)                       │
│      │                           │                              │
│      │  1. withdraw(1 ETH)       │                              │
│      │ ────────────────────────► │                              │
│      │                           │                              │
│      │                           │ 2. balances 확인 (통과)        │
│      │                           │                              │
│      │  3. 1 ETH 전송            │                              │
│      │ ◄──────────────────────── │                              │
│      │                           │                              │
│      │  4. receive() 트리거       │                              │
│      │  ┌──────────────────┐     │                              │
│      │  │ 다시 withdraw!    │     │                              │
│      │  └──────────────────┘     │                              │
│      │                           │                              │
│      │  5. withdraw(1 ETH)       │  (balances 아직 미갱신!)       │
│      │ ────────────────────────► │                              │
│      │                           │                              │
│      │                           │ 6. balances 확인 (또 통과!)    │
│      │                           │                              │
│      │  7. 1 ETH 또 전송          │                              │
│      │ ◄──────────────────────── │                              │
│      │                           │                              │
│      │        ... 반복 ...        │                              │
│      │                           │                              │
│      │                           │ N. 결국 balances 업데이트     │
│      │                           │    (이미 Vault는 빈털터리)     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 취약한 코드 (BAD)

```solidity
// ❌ 취약한 코드 - 절대 이렇게 작성하지 마세요!
function withdraw(uint256 amount) public {
    // 1. Checks - OK
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // 2. Interactions - 위험! 상태 업데이트 전 외부 호출
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    // 3. Effects - 너무 늦음! 이미 재진입 가능
    balances[msg.sender] -= amount;
}
```

**문제점**:
1. `call{value: amount}("")`이 공격자의 `receive()` 또는 `fallback()`을 트리거
2. 공격자의 `receive()`에서 다시 `withdraw()` 호출
3. `balances[msg.sender]`가 아직 업데이트되지 않았으므로 검증 통과
4. 무한 반복 → Vault 자금 전량 탈취

### The DAO 해킹 (2016)

**사건 개요**:
- 2016년 6월, 이더리움 최대 크라우드펀딩 프로젝트 "The DAO" 해킹
- 약 360만 ETH (당시 $60M, 현재 가치 수조원) 탈취
- 이더리움 커뮤니티 분열: 하드포크 결정
- ETH(하드포크)와 ETC(원래 체인)로 분리

**취약점**:
The DAO의 `splitDAO` 함수가 ETH를 전송한 후 잔액을 업데이트했습니다.
공격자는 재진입을 통해 ETH를 반복 인출했습니다.

**교훈**:
> "외부 호출 전에 반드시 상태를 업데이트하라" - CEI 패턴의 탄생

---

## 3. Checks-Effects-Interactions (CEI) 패턴

### 패턴 설명

CEI는 함수 내 코드 순서를 정의하는 안전한 패턴입니다:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CEI 패턴 구조                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  1. CHECKS (검증)                                        │   │
│   │     - require() 문으로 조건 확인                           │   │
│   │     - 입력값 유효성 검증                                   │   │
│   │     - 권한 확인                                           │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  2. EFFECTS (상태 변경)                                    │   │
│   │     - storage 변수 업데이트                                │   │
│   │     - balances 변경                                       │   │
│   │     - mapping 업데이트                                    │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  3. INTERACTIONS (외부 호출)                               │   │
│   │     - ETH 전송 (call, transfer, send)                     │   │
│   │     - 외부 컨트랙트 호출                                   │   │
│   │     - 이벤트 발생 (optional)                               │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 안전한 코드 (GOOD)

```solidity
// ✅ 안전한 코드 - CEI 패턴 적용
function withdraw(uint256 amount) public {
    // ========================================
    // 1. CHECKS (검증)
    // ========================================
    // 잔액이 충분한지 확인
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // ========================================
    // 2. EFFECTS (상태 변경)
    // ========================================
    // 잔액을 먼저 차감! (핵심!)
    // 이제 재진입해도 잔액이 이미 0이므로 require에서 실패
    balances[msg.sender] -= amount;

    // ========================================
    // 3. INTERACTIONS (외부 호출)
    // ========================================
    // ETH 전송은 마지막에
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    // 이벤트 발생
    emit Withdrawn(msg.sender, amount);
}
```

### 왜 CEI가 안전한가?

```
재진입 시도 시나리오 (CEI 적용):

1. Attacker가 withdraw(1 ETH) 호출
2. Checks: balances[Attacker] >= 1 ETH → 통과
3. Effects: balances[Attacker] = 0  ← 이미 0으로 변경!
4. Interactions: Attacker에게 1 ETH 전송
5. Attacker의 receive() 트리거, 다시 withdraw(1 ETH) 호출
6. Checks: balances[Attacker] >= 1 ETH
   → 실패! balances[Attacker]는 이미 0
   → require문에서 revert!

결과: 공격 실패, 1 ETH만 정상 인출
```

### 실생활 비유: ATM 출금

**취약한 ATM (BAD)**:
1. 잔액 확인
2. 현금 지급
3. 잔액 차감

→ 현금이 나오는 동안 ATM 버튼을 연타하면 잔액 차감 전에 추가 인출!

**안전한 ATM (GOOD)**:
1. 잔액 확인
2. **잔액 먼저 차감**
3. 현금 지급

→ 잔액이 먼저 줄어들어 추가 인출 불가능

---

## 4. OpenZeppelin ReentrancyGuard

### 소개

OpenZeppelin은 검증된 스마트 컨트랙트 라이브러리입니다.
`ReentrancyGuard`는 재진입을 원천 차단하는 modifier를 제공합니다.

### 사용법

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VaultSecure is ReentrancyGuard {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // nonReentrant modifier가 재진입을 방지
    function withdraw(uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 순서와 상관없이 안전 (하지만 CEI도 같이 적용 권장)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
    }
}
```

### 내부 동작 원리

`ReentrancyGuard`는 **mutex(뮤텍스)** 패턴을 사용합니다:

```solidity
// OpenZeppelin ReentrancyGuard 간략화된 구현
abstract contract ReentrancyGuard {
    // 상태: 1 = 미진입, 2 = 진입됨
    uint256 private _status;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // 이미 진입 상태면 revert
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // 진입 상태로 변경
        _status = _ENTERED;

        // 실제 함수 실행
        _;

        // 함수 종료 후 미진입 상태로 복귀
        _status = _NOT_ENTERED;
    }
}
```

### 작동 방식

```
┌─────────────────────────────────────────────────────────────────┐
│               nonReentrant modifier 동작                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   첫 번째 withdraw() 호출:                                       │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ 1. _status 확인: _NOT_ENTERED (1) → OK                   │  │
│   │ 2. _status = _ENTERED (2) 로 변경                        │  │
│   │ 3. withdraw() 로직 실행                                   │  │
│   │ 4. call() → 공격자 receive() 트리거                       │  │
│   └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│   재진입 시도 withdraw() 호출:                                    │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ 1. _status 확인: _ENTERED (2) → FAIL!                    │  │
│   │    "ReentrancyGuard: reentrant call" revert              │  │
│   └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│   첫 번째 호출 완료:                                              │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ 5. _status = _NOT_ENTERED (1) 로 복귀                    │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### CEI vs ReentrancyGuard 비교

| 측면 | CEI 패턴 | ReentrancyGuard |
|------|---------|-----------------|
| **가스 비용** | 추가 없음 | ~2,500 gas (storage read/write) |
| **명시성** | 암묵적 (코드 순서) | 명시적 (modifier) |
| **실수 가능성** | 높음 (순서 잘못 배치) | 낮음 (modifier가 강제) |
| **외부 의존성** | 없음 | OpenZeppelin 필요 |
| **학습 가치** | 높음 (원리 이해) | 중간 (사용법만) |

### 권장 사항

**학습 시**: CEI 패턴 먼저 마스터
**프로덕션**: CEI + ReentrancyGuard 둘 다 적용 (벨트와 멜빵)

```solidity
// 최고의 보안: 둘 다 사용
function withdraw(uint256 amount) public nonReentrant {
    // Checks
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // Effects (CEI 순서도 유지)
    balances[msg.sender] -= amount;

    // Interactions
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    emit Withdrawn(msg.sender, amount);
}
```

---

## 5. 다른 보안 고려사항

### 5.1 접근 제어 (Access Control)

특정 함수는 특정 사용자만 호출해야 합니다:

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    // onlyOwner: 오너만 호출 가능
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
```

**패턴**:
- `Ownable`: 단일 오너
- `AccessControl`: 역할 기반 (ADMIN, MINTER, PAUSER 등)

### 5.2 오버플로우/언더플로우

Solidity 0.8.0 이전에는 숫자 오버플로우가 자동 방지되지 않았습니다:

```solidity
// Solidity < 0.8.0 (취약)
uint8 x = 255;
x = x + 1;  // x = 0 (오버플로우!)

uint8 y = 0;
y = y - 1;  // y = 255 (언더플로우!)
```

**Solidity 0.8.0+ (안전)**:
```solidity
uint8 x = 255;
x = x + 1;  // 자동으로 revert!
```

> 우리는 0.8.26을 사용하므로 자동 보호됩니다.

### 5.3 tx.origin vs msg.sender

```solidity
// ❌ 취약: tx.origin 사용
function withdraw() public {
    require(tx.origin == owner, "Not owner");
    // ...
}

// ✅ 안전: msg.sender 사용
function withdraw() public {
    require(msg.sender == owner, "Not owner");
    // ...
}
```

**차이점**:
- `tx.origin`: 트랜잭션을 시작한 EOA (항상 외부 계정)
- `msg.sender`: 현재 함수를 호출한 주소 (컨트랙트일 수 있음)

**피싱 공격 시나리오**:
```
Alice(오너) → MaliciousContract → YourContract
              └── tx.origin = Alice (오너!)
              └── msg.sender = MaliciousContract (공격자!)
```

### 5.4 프론트러닝 (Front-running)

트랜잭션이 mempool에서 대기 중일 때 공격자가 더 높은 가스를 써서 먼저 실행:

```
1. Alice가 DEX에서 큰 매수 주문 전송
2. 공격자가 mempool에서 이를 감지
3. 공격자가 더 높은 가스로 먼저 매수
4. Alice의 주문이 더 높은 가격에 체결
5. 공격자가 즉시 매도하여 이익
```

**방어**:
- Commit-reveal 패턴
- Submarine sends
- MEV 보호 서비스 (Flashbots 등)

---

## 6. 보안 체크리스트

스마트 컨트랙트 배포 전 반드시 확인하세요:

### 재진입 방지

- [ ] 외부 호출 전에 모든 상태 변경 완료? (CEI 패턴)
- [ ] ETH 전송 함수에 `nonReentrant` modifier 적용?
- [ ] `call{value: ...}("")` 사용 시 재진입 고려?

### 접근 제어

- [ ] 민감한 함수에 적절한 modifier (`onlyOwner`, role 기반)?
- [ ] `initialize()` 함수 재호출 방지? (upgradeable 패턴)
- [ ] 제어판 함수의 이벤트 로깅?

### 입력 유효성

- [ ] 모든 사용자 입력에 `require()` 검증?
- [ ] 0 주소 체크 (`address(0)`)?
- [ ] 배열 길이 제한 (DoS 방지)?

### 일반 보안

- [ ] `tx.origin` 대신 `msg.sender` 사용?
- [ ] Solidity 0.8.0+ 사용? (오버플로우 보호)
- [ ] 중요한 작업에 이벤트 발생?
- [ ] 긴급 중지 기능 (`Pausable`)?

### 외부 호출

- [ ] 신뢰할 수 없는 외부 컨트랙트 호출 최소화?
- [ ] 외부 호출 실패 처리? (`try/catch` 또는 반환값 확인)
- [ ] 콜백 시 상태 일관성 유지?

### 테스트

- [ ] 단위 테스트 작성?
- [ ] 엣지 케이스 테스트?
- [ ] Fuzz 테스트 실행? (`forge test --fuzz-runs 1000`)
- [ ] 불변성(invariant) 테스트?

### 감사

- [ ] Slither 정적 분석 실행?
- [ ] Mythril 심볼릭 실행?
- [ ] 전문 보안 감사 의뢰? (메인넷 배포 전)

---

## 요약

| 취약점 | 원인 | 방어 |
|--------|------|------|
| 재진입 | 외부 호출 후 상태 변경 | CEI 패턴, ReentrancyGuard |
| 접근 제어 미흡 | modifier 누락 | Ownable, AccessControl |
| 오버플로우 | Solidity < 0.8 | Solidity 0.8+ 사용 |
| tx.origin 피싱 | tx.origin 인증 | msg.sender 사용 |
| 프론트러닝 | mempool 노출 | Commit-reveal 패턴 |

**핵심 원칙**:
1. **상태 먼저, 호출 나중** - CEI 패턴
2. **최소 권한 원칙** - 필요한 권한만 부여
3. **Fail-safe 기본값** - 기본적으로 제한, 명시적 허용
4. **검증된 코드 사용** - OpenZeppelin 등 검증된 라이브러리
5. **테스트, 테스트, 테스트** - 자동화된 테스트 필수

---

## 참고 자료

- [SWC Registry](https://swcregistry.io/) - Smart Contract Weakness Classification
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/) - 검증된 라이브러리
- [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Slither](https://github.com/crytic/slither) - 정적 분석 도구
- [Foundry Book](https://book.getfoundry.sh/) - Foundry 테스트 프레임워크

---

*Bay-17th Ethereum Study - Week 3 Security Patterns Guide*
