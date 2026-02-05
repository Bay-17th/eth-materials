# Foundry로 스마트 컨트랙트 테스트하기

> Foundry의 테스트 프레임워크를 사용하여 스마트 컨트랙트를 검증하는 방법을 배웁니다.

---

## 1. Foundry란?

Foundry는 Rust로 작성된 **빠르고 강력한** 스마트 컨트랙트 개발 도구입니다.

### 특징

| 특징 | 설명 |
|------|------|
| **속도** | Rust로 작성되어 매우 빠른 컴파일 및 테스트 |
| **Solidity 테스트** | JavaScript 대신 Solidity로 테스트 작성 |
| **Cheatcodes** | 블록체인 상태를 조작하는 강력한 테스트 유틸리티 |
| **Fuzz 테스트** | 자동으로 다양한 입력값을 생성하여 테스트 |

### Foundry 구성 요소

| 도구 | 역할 |
|------|------|
| `forge` | 컴파일, 테스트, 배포 |
| `cast` | 블록체인과 상호작용 (RPC 호출) |
| `anvil` | 로컬 이더리움 노드 실행 |

> **실생활 비유**: Foundry는 **자동차 검사소**와 같습니다.
> - forge = 차량 검사 장비 (테스트 실행)
> - cast = 진단 도구 (블록체인 조회)
> - anvil = 테스트 주행 코스 (로컬 네트워크)

---

## 2. 프로젝트 구조

Foundry 프로젝트의 표준 디렉토리 구조입니다.

```
project/
├── src/              # 스마트 컨트랙트 소스 코드
│   └── Counter.sol
├── test/             # 테스트 파일 (*.t.sol)
│   └── Counter.t.sol
├── script/           # 배포 스크립트
│   └── Deploy.s.sol
├── lib/              # 외부 라이브러리 (git submodules)
│   └── forge-std/    # Foundry 표준 라이브러리
└── foundry.toml      # 설정 파일
```

### 파일 명명 규칙

| 파일 유형 | 접미사 | 예시 |
|-----------|--------|------|
| 컨트랙트 | `.sol` | `Counter.sol` |
| 테스트 | `.t.sol` | `Counter.t.sol` |
| 스크립트 | `.s.sol` | `Deploy.s.sol` |

---

## 3. setUp() 함수

`setUp()`은 **각 테스트 함수 실행 전에 호출**되는 특별한 함수입니다.

### 기본 구조

```solidity
import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    // 각 테스트 전에 실행됨
    function setUp() public {
        counter = new Counter();  // 새 인스턴스 생성
    }

    function test_Example1() public {
        // setUp() 실행 -> test_Example1() 실행
    }

    function test_Example2() public {
        // setUp() 다시 실행 -> test_Example2() 실행
    }
}
```

### 왜 매번 새로 실행하나요?

**테스트 격리(Test Isolation)** 를 위해서입니다.

- test_Example1에서 변경한 상태가 test_Example2에 영향을 주면 안 됩니다
- 각 테스트는 **깨끗한 상태**에서 시작해야 합니다
- 테스트 순서에 관계없이 결과가 동일해야 합니다

> **실생활 비유**: 과학 실험에서 매번 **새 시험관**을 사용하는 것과 같습니다.
> 이전 실험의 잔여물이 결과에 영향을 주면 안 됩니다.

---

## 4. 테스트 함수 명명

Foundry는 함수 이름으로 테스트를 인식합니다.

### 명명 규칙

| 패턴 | 의미 | 예시 |
|------|------|------|
| `test_*` | 일반 테스트 | `test_Increment_IncreasesCount` |
| `testFuzz_*` | Fuzz 테스트 | `testFuzz_Deposit(uint256 amount)` |
| `testFail_*` | 실패해야 통과 | `testFail_Underflow` (권장하지 않음) |
| `test_RevertWhen_*` | revert 테스트 | `test_RevertWhen_InsufficientBalance` |

### 권장하는 이름 구조

```
test_함수명_조건_기대결과
```

**좋은 예시:**
```solidity
function test_Increment_WhenCalledOnce_IncreasesCountByOne() public { }
function test_Withdraw_WhenBalanceSufficient_TransfersEther() public { }
function test_RevertWhen_WithdrawExceedsBalance() public { }
```

**나쁜 예시:**
```solidity
function test1() public { }           // 무엇을 테스트하는지 모름
function testDeposit() public { }     // 어떤 조건인지 모름
```

---

## 5. Assert 함수

테스트 결과를 검증하는 함수들입니다.

### 주요 Assert 함수

| 함수 | 설명 | 예시 |
|------|------|------|
| `assertEq(a, b)` | a == b 확인 | `assertEq(count, 1)` |
| `assertTrue(x)` | x가 true인지 확인 | `assertTrue(isActive)` |
| `assertFalse(x)` | x가 false인지 확인 | `assertFalse(isPaused)` |
| `assertGt(a, b)` | a > b 확인 | `assertGt(balance, 0)` |
| `assertLt(a, b)` | a < b 확인 | `assertLt(fee, 100)` |
| `assertGe(a, b)` | a >= b 확인 | `assertGe(balance, minAmount)` |
| `assertLe(a, b)` | a <= b 확인 | `assertLe(gas, maxGas)` |

### 에러 메시지 추가

실패 시 원인을 쉽게 파악하려면 메시지를 추가하세요.

```solidity
assertEq(
    counter.count(),
    1,
    "Count should be 1 after increment"  // 실패 시 출력됨
);
```

---

## 6. Cheatcodes

Cheatcodes는 Foundry가 제공하는 **블록체인 상태 조작 함수**입니다.

### 자주 사용하는 Cheatcodes

#### vm.prank(address)

다음 호출의 `msg.sender`를 변경합니다.

```solidity
address alice = address(0x1);

vm.prank(alice);                    // 다음 호출만 alice로 변경
counter.increment();                // msg.sender = alice

// 이후 호출은 원래대로
counter.increment();                // msg.sender = address(this)
```

#### vm.startPrank / vm.stopPrank

여러 호출의 `msg.sender`를 변경합니다.

```solidity
vm.startPrank(alice);               // 여기서부터 alice
counter.increment();
counter.increment();
counter.increment();
vm.stopPrank();                     // 여기서 종료
```

#### vm.deal(address, uint256)

특정 주소에 ETH를 지급합니다.

```solidity
address user = address(0x1234);
vm.deal(user, 10 ether);            // user에게 10 ETH 지급

assertEq(user.balance, 10 ether);   // 잔액 확인
```

#### vm.expectRevert(bytes)

다음 호출이 특정 메시지로 revert될 것을 예상합니다.

```solidity
// 다음 호출이 "Insufficient balance"로 revert되어야 함
vm.expectRevert("Insufficient balance");

// 이 호출이 revert되면 테스트 통과
storage.withdraw(100 ether);
```

#### vm.expectEmit(bool, bool, bool, bool)

다음 호출에서 특정 이벤트가 발생할 것을 예상합니다.

```solidity
// (topic1 체크, topic2 체크, topic3 체크, data 체크)
vm.expectEmit(true, false, false, true);

// 예상되는 이벤트
emit Deposited(user, 1 ether);

// 실제 호출 - 이벤트가 발생해야 함
storage.deposit{value: 1 ether}();
```

---

## 7. Fuzz 테스트

Foundry가 자동으로 **다양한 입력값**을 생성하여 테스트합니다.

### 기본 Fuzz 테스트

```solidity
// amount는 Foundry가 자동 생성 (0 ~ 2^256-1)
function testFuzz_Deposit(uint256 amount) public {
    vm.assume(amount > 0);          // 0은 제외
    vm.assume(amount <= 10 ether);  // 10 ETH 이하만

    vm.prank(user);
    storage.deposit{value: amount}();

    assertEq(storage.getBalance(user), amount);
}
```

### vm.assume

특정 조건을 만족하는 입력만 테스트합니다.

```solidity
function testFuzz_Transfer(address to, uint256 amount) public {
    vm.assume(to != address(0));     // 영주소 제외
    vm.assume(amount > 0);           // 0 제외
    vm.assume(amount <= balance);    // 잔액 이하만

    // 테스트 로직
}
```

### Fuzz 실행 횟수 설정

`foundry.toml`에서 설정:

```toml
[profile.default]
fuzz = { runs = 256 }     # 기본 256회

[profile.ci]
fuzz = { runs = 1000 }    # CI에서는 1000회
```

> **실생활 비유**: Fuzz 테스트는 **스트레스 테스트**와 같습니다.
> 다양한 조건에서 시스템이 올바르게 동작하는지 자동으로 검증합니다.

---

## 8. 테스트 실행

### 기본 명령어

```bash
# 모든 테스트 실행
forge test

# 특정 파일 테스트
forge test --match-path test/Counter.t.sol

# 특정 테스트 함수만 실행
forge test --match-test test_Increment

# 특정 컨트랙트의 테스트만 실행
forge test --match-contract CounterTest
```

### 출력 상세도 (-v 옵션)

| 옵션 | 출력 내용 |
|------|-----------|
| (없음) | 통과/실패만 표시 |
| `-v` | 실패한 테스트의 로그 |
| `-vv` | 모든 테스트의 로그 |
| `-vvv` | 트랜잭션 trace |
| `-vvvv` | 상세 trace (스택, 메모리) |

```bash
# 권장: 테스트 결과와 로그 확인
forge test -vv
```

### 가스 리포트

```bash
# 각 함수의 가스 사용량 확인
forge test --gas-report
```

출력 예시:

```
| src/Counter.sol:Counter contract |                 |       |        |       |
|----------------------------------|-----------------|-------|--------|-------|
| Deployment Cost                  | Deployment Size |       |        |       |
| 97947                            | 436             |       |        |       |
| Function Name                    | min             | avg   | median | max   |
| count                            | 261             | 261   | 261    | 261   |
| increment                        | 22338           | 22338 | 22338  | 22338 |
```

---

## AAA 패턴

테스트 코드 작성의 표준 패턴입니다.

### Arrange-Act-Assert (준비-실행-검증)

```solidity
function test_Withdraw_UpdatesBalance() public {
    // =========== Arrange (준비) ===========
    // 테스트에 필요한 상태를 설정합니다
    vm.prank(user);
    storage.deposit{value: 2 ether}();

    // =========== Act (실행) ===========
    // 테스트할 동작을 실행합니다
    vm.prank(user);
    storage.withdraw(1 ether);

    // =========== Assert (검증) ===========
    // 결과가 예상과 일치하는지 확인합니다
    assertEq(storage.getBalance(user), 1 ether);
}
```

### 왜 AAA 패턴을 사용하나요?

1. **가독성**: 테스트의 의도가 명확해집니다
2. **유지보수**: 테스트 수정이 쉬워집니다
3. **디버깅**: 어느 단계에서 문제가 발생했는지 파악하기 쉽습니다

---

## 정리

| 개념 | 핵심 포인트 |
|------|-------------|
| setUp() | 각 테스트 전에 실행, 테스트 격리 보장 |
| 테스트 명명 | `test_함수_조건_결과` 형식 |
| Assert | assertEq, assertTrue, assertGt 등 |
| Cheatcodes | vm.prank, vm.deal, vm.expectRevert |
| Fuzz 테스트 | 자동 입력 생성, vm.assume으로 필터링 |
| AAA 패턴 | Arrange-Act-Assert로 구조화 |

---

## 다음 단계

이 개념들을 [SimpleStorage 과제](../../../eth-homework/week-02/dev/README.md)에서 실습해보세요!

---

*[2주차 목차로 돌아가기](../README.md)*
