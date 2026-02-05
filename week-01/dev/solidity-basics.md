# Solidity 기초 문법

> 스마트 컨트랙트 개발을 위한 Solidity 언어의 핵심 개념을 배웁니다.

---

## 1. Solidity란?

Solidity는 이더리움 스마트 컨트랙트를 작성하기 위한 **정적 타입 프로그래밍 언어**입니다.

### 특징

- **EVM에서 실행**: 이더리움 가상 머신(EVM)에서 동작합니다
- **정적 타입**: 변수의 타입을 미리 선언해야 합니다 (JavaScript와 다름)
- **컴파일 언어**: 작성한 코드를 바이트코드로 컴파일하여 배포합니다

### 실생활 비유

> 스마트 컨트랙트는 **자동 판매기**와 같습니다.
> - 코드(규칙)가 미리 정해져 있고
> - 조건이 충족되면 자동으로 실행되며
> - 한번 배포되면 변경이 어렵습니다

---

## 2. 기본 구조

모든 Solidity 파일은 다음 세 가지 요소로 시작합니다.

```solidity
// SPDX-License-Identifier: MIT       // 라이선스 명시 (필수)
pragma solidity 0.8.26;               // Solidity 버전 지정

contract MyContract {                  // 컨트랙트 정의
    // 코드 작성
}
```

### 각 요소 설명

| 요소 | 설명 |
|------|------|
| SPDX | 오픈소스 라이선스를 명시합니다 (MIT, GPL 등) |
| pragma | 사용할 Solidity 컴파일러 버전을 지정합니다 |
| contract | 클래스와 비슷한 개념으로, 상태와 함수를 담는 컨테이너입니다 |

---

## 3. 데이터 타입

Solidity에서 자주 사용하는 데이터 타입입니다.

### 값 타입 (Value Types)

```solidity
// 부호 없는 정수 (양수만)
uint256 public balance = 100;        // 0 ~ 2^256-1 범위
uint8 public smallNumber = 255;      // 0 ~ 255 범위

// 부호 있는 정수 (음수/양수)
int256 public temperature = -10;

// 불리언
bool public isActive = true;

// 주소 (이더리움 계정)
address public owner = 0x1234...;    // 20바이트 주소

// 주소 + 송금 기능
address payable public recipient;    // ETH를 받을 수 있는 주소
```

### 참조 타입 (Reference Types)

```solidity
// 문자열
string public name = "Hello";

// 바이트 배열
bytes public data = hex"1234";

// 동적 배열
uint256[] public numbers;

// 고정 크기 배열
uint256[5] public fixedArray;
```

### 매핑 (Mapping)

```solidity
// key => value 저장소
mapping(address => uint256) public balances;

// 사용 예시
balances[msg.sender] = 100;          // 저장
uint256 myBalance = balances[msg.sender];  // 조회
```

> **실생활 비유**: mapping은 **전화번호부**와 같습니다.
> 이름(key)으로 전화번호(value)를 찾을 수 있습니다.

---

## 4. 상태 변수와 지역 변수

### 상태 변수 (State Variable)

- 블록체인에 **영구 저장**됩니다
- 가스비가 발생합니다 (저장에 비용이 듦)
- contract 레벨에서 선언합니다

```solidity
contract Bank {
    // 상태 변수 - 블록체인에 저장됨
    uint256 public totalDeposits;    // 금고의 총 잔고
    address public owner;            // 은행장 주소
}
```

### 지역 변수 (Local Variable)

- 함수 실행 중에만 존재합니다
- 메모리에 저장되어 가스비가 적습니다
- 함수 내부에서 선언합니다

```solidity
function calculate() public pure returns (uint256) {
    // 지역 변수 - 함수 실행 후 사라짐
    uint256 temp = 10;               // 임시 계산용
    uint256 result = temp * 2;
    return result;
}
```

> **실생활 비유**:
> - 상태 변수 = **금고에 보관된 돈** (영구적, 비용 발생)
> - 지역 변수 = **계산기에 표시된 숫자** (일시적, 비용 낮음)

---

## 5. 함수

함수는 컨트랙트의 동작을 정의합니다.

### 함수 선언 구조

```solidity
function 함수이름(매개변수) 가시성 상태변경자 returns (반환타입) {
    // 로직
}
```

### 가시성 (Visibility)

| 가시성 | 설명 |
|--------|------|
| `public` | 어디서든 호출 가능 (외부, 내부, 상속) |
| `private` | 현재 컨트랙트 내부에서만 호출 가능 |
| `internal` | 현재 컨트랙트 + 상속받은 컨트랙트에서 호출 가능 |
| `external` | 외부에서만 호출 가능 (내부 호출 불가) |

### 상태 변경자

| 변경자 | 설명 |
|--------|------|
| `view` | 상태 변수를 읽기만 함 (변경 안 함) |
| `pure` | 상태 변수를 읽지도 변경하지도 않음 |
| (없음) | 상태 변수를 변경할 수 있음 |

### 예시 코드

```solidity
contract Example {
    uint256 public count;

    // view: 읽기만 함
    function getCount() public view returns (uint256) {
        return count;
    }

    // pure: 상태와 무관한 계산
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    // 상태 변경 함수
    function increment() public {
        count += 1;
    }
}
```

> **실생활 비유**: 함수는 **은행원**과 같습니다.
> - `view` = 잔고 조회 (장부를 읽기만 함)
> - `pure` = 이자 계산 (장부와 관계없이 계산만 함)
> - 일반 = 입금/출금 (장부를 수정함)

---

## 6. 제어문

조건과 반복을 제어하는 구문입니다.

### 조건문 (if-else)

```solidity
function checkAmount(uint256 amount) public pure returns (string memory) {
    if (amount > 100) {
        return "Large";
    } else if (amount > 10) {
        return "Medium";
    } else {
        return "Small";
    }
}
```

### 반복문 (for, while)

```solidity
function sum(uint256 n) public pure returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 1; i <= n; i++) {
        total += i;
    }
    return total;
}
```

### require (조건 검사)

```solidity
function withdraw(uint256 amount) public {
    // 조건이 false면 트랜잭션 취소 + 가스 환불
    require(amount > 0, "Amount must be positive");
    require(balances[msg.sender] >= amount, "Insufficient balance");

    balances[msg.sender] -= amount;
}
```

> **주의**: 블록체인에서 무한 반복은 가스 한도를 초과하여 실패합니다.

---

## 7. 이벤트

이벤트는 블록체인에 로그를 기록합니다. 프론트엔드에서 구독할 수 있습니다.

### 이벤트 선언과 발생

```solidity
contract Bank {
    // 이벤트 선언
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;

        // 이벤트 발생 (emit)
        emit Deposited(msg.sender, msg.value);
    }
}
```

### indexed 키워드

- `indexed`를 붙이면 해당 값으로 검색할 수 있습니다
- 최대 3개까지 indexed 가능

> **실생활 비유**: 이벤트는 **영수증**과 같습니다.
> 거래 기록이 남아서 나중에 조회할 수 있습니다.

---

## 8. 수정자 (Modifier)

반복되는 조건 검사를 재사용 가능하게 만듭니다.

### 수정자 정의

```solidity
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // 수정자 정의
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;  // 원래 함수의 코드가 여기서 실행됨
    }

    // 수정자 사용
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function withdraw() public onlyOwner {
        // onlyOwner 검사 후 실행됨
        payable(owner).transfer(address(this).balance);
    }
}
```

### 여러 수정자 조합

```solidity
modifier validAddress(address _addr) {
    require(_addr != address(0), "Invalid address");
    _;
}

function transfer(address to, uint256 amount) public onlyOwner validAddress(to) {
    // onlyOwner 검사 -> validAddress 검사 -> 본문 실행
}
```

> **실생활 비유**: modifier는 **보안 게이트**와 같습니다.
> 함수 실행 전에 권한을 확인합니다.

---

## 정리

| 개념 | 핵심 포인트 |
|------|-------------|
| 상태 변수 | 블록체인에 영구 저장, 가스비 발생 |
| 함수 | public/private/view/pure 조합 |
| mapping | key-value 저장소 |
| require | 조건 불충족 시 revert |
| event | 로그 기록, 프론트엔드 구독 |
| modifier | 재사용 가능한 조건 검사 |

---

## 다음 단계

이 개념들을 [Counter 과제](../../../eth-homework/week-01/dev/README.md)에서 실습해보세요!

---

*[1주차 목차로 돌아가기](../README.md)*
