# 최종 프로젝트 가이드

이 문서는 Week 6 최종 프로젝트를 성공적으로 완료하기 위한 상세 가이드입니다.

## 목차

1. [프로젝트 계획](#1-프로젝트-계획)
2. [개발 순서 권장](#2-개발-순서-권장)
3. [아이디어별 힌트](#3-아이디어별-힌트)
4. [일반적인 문제 해결](#4-일반적인-문제-해결)
5. [평가 기준](#5-평가-기준)

---

## 1. 프로젝트 계획

### 1.1 아이디어 선정

**원칙: 간단한 것부터!**

처음 dApp을 만드는 것이라면 복잡한 기능보다 핵심 기능 하나에 집중하세요.

| 난이도 | 예시 | 권장 대상 |
|--------|------|-----------|
| 쉬움 | 메시지 저장소, 간단한 투표 | 처음 dApp 개발 |
| 보통 | 기부 컨트랙트, 에스크로 | 컨트랙트 익숙함 |
| 어려움 | NFT 민팅, 토큰 스왑 | 경험 있음 |

### 1.2 핵심 기능 1개에 집중

**좋은 예:**
- 투표 dApp → "투표하기" 기능만 완벽하게

**나쁜 예:**
- 투표 dApp → 투표 + 댓글 + 공유 + 알림 + ... (다 중도 포기)

### 1.3 스코프 조절

**목표: 2-3일 안에 MVP 완성**

1일차: 컨트랙트 + 테스트
2일차: 프론트엔드 연동
3일차: 배포 + 버그 수정 + 마무리

시간이 부족하면 기능을 줄이세요. 기능이 적어도 동작하는 것이 낫습니다.

---

## 2. 개발 순서 권장

### 2.1 1단계: 스마트 컨트랙트 작성 + 테스트

**먼저 컨트랙트를 완성하세요.**

```bash
# Foundry 프로젝트 생성
forge init contracts
cd contracts
```

```solidity
// src/YourContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract YourContract {
    // 상태 변수
    uint256 public value;

    // 이벤트
    event ValueChanged(uint256 newValue);

    // 함수
    function setValue(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value);
    }
}
```

### 2.2 2단계: Foundry 테스트 작성

**최소 5개의 테스트를 작성하세요.**

```solidity
// test/YourContract.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/YourContract.sol";

contract YourContractTest is Test {
    YourContract public target;

    function setUp() public {
        target = new YourContract();
    }

    function test_InitialValueIsZero() public view {
        assertEq(target.value(), 0);
    }

    function test_SetValue() public {
        target.setValue(42);
        assertEq(target.value(), 42);
    }

    function test_SetValueEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit YourContract.ValueChanged(100);
        target.setValue(100);
    }

    function test_SetValueTwice() public {
        target.setValue(1);
        target.setValue(2);
        assertEq(target.value(), 2);
    }

    function testFuzz_SetValue(uint256 x) public {
        target.setValue(x);
        assertEq(target.value(), x);
    }
}
```

```bash
# 테스트 실행
forge test -vvv
```

### 2.3 3단계: 배포 스크립트 작성

```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/YourContract.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        YourContract yourContract = new YourContract();
        console.log("Deployed at:", address(yourContract));

        vm.stopBroadcast();
    }
}
```

### 2.4 4단계: Sepolia 배포

```bash
# .env 파일 생성 (PRIVATE_KEY는 절대 공개하지 마세요!)
echo "PRIVATE_KEY=your_private_key_here" > .env
echo "SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY" >> .env

# 배포
source .env
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

**배포된 주소를 기록하세요!** 프론트엔드에서 사용합니다.

### 2.5 5단계: 프론트엔드 연동

```bash
# frontend-template 복사
cp -r eth-materials/resources/frontend-template/ week-06/dev/frontend/
cd week-06/dev/frontend
npm install
```

**컨트랙트 정보 추가:**

```typescript
// config/contract.ts
export const CONTRACT_ADDRESS = '0x...' as const; // 배포된 주소

export const CONTRACT_ABI = [
  {
    name: 'value',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ type: 'uint256' }],
  },
  {
    name: 'setValue',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: '_value', type: 'uint256' }],
    outputs: [],
  },
] as const;
```

### 2.6 6단계: 테스트 및 디버깅

1. 로컬에서 모든 기능 테스트
2. 실제 Sepolia에서 트랜잭션 전송 테스트
3. 에러 처리 확인
4. 모바일에서 RainbowKit 테스트

---

## 3. 아이디어별 힌트

### 3.1 투표 시스템

**핵심 개념:**
- `mapping(address => bool) public hasVoted` - 투표 여부 추적
- `require(!hasVoted[msg.sender], "Already voted")` - 중복 투표 방지
- `event Voted(address voter, uint256 candidateId)` - 투표 이벤트

**주의:**
- 투표 종료 조건 정의 (시간? 참여자 수?)
- 누가 후보를 등록할 수 있나?

### 3.2 기부 컨트랙트

**핵심 개념:**
- `function donate() external payable` - ETH 받기
- `msg.value` - 전송된 ETH 금액
- `address(this).balance` - 컨트랙트 잔액
- `payable(owner).transfer(amount)` - ETH 전송

**주의:**
- 목표 달성 전/후 로직 분리
- 환불 기능이 필요한가?
- 인출 권한은 누구에게?

### 3.3 메시지 저장소

**핵심 개념:**
- `struct Message { address author; string content; uint256 timestamp; }`
- `Message[] public messages` - 메시지 배열
- `block.timestamp` - 현재 시간

**주의:**
- 가스비가 비쌀 수 있음 (문자열 저장)
- 메시지 길이 제한 고려
- 삭제/수정 기능이 필요한가?

### 3.4 NFT 민팅

**핵심 개념:**
- OpenZeppelin ERC721 사용 권장
- `_mint(to, tokenId)` - NFT 발행
- `tokenURI(tokenId)` - 메타데이터 URI

**주의:**
- 민팅 비용(가격) 설정
- 최대 발행량 제한
- 메타데이터 저장 위치 (IPFS? on-chain?)

### 3.5 에스크로 컨트랙트

**핵심 개념:**
- `enum State { Created, Funded, Shipped, Completed }`
- 상태 전이 로직 (state machine)
- 구매자/판매자 역할 분리

**주의:**
- 분쟁 해결 방법
- 시간 제한 (자동 환불?)
- 수수료 모델

---

## 4. 일반적인 문제 해결

### 4.1 가스 부족

**증상:** "out of gas" 오류

**해결:**
1. Sepolia Faucet에서 ETH 받기
   - [sepoliafaucet.com](https://sepoliafaucet.com)
   - [infura.io/faucet/sepolia](https://www.infura.io/faucet/sepolia)
2. 가스 리밋 늘리기 (wagmi에서 `gas` 옵션)

### 4.2 트랜잭션 실패 (Reverted)

**증상:** "execution reverted" 오류

**해결:**
1. require 조건 확인
   - 권한이 있는지? (msg.sender)
   - 값이 유효한지?
   - 상태가 맞는지?
2. Foundry 테스트에서 같은 시나리오 재현

### 4.3 프론트엔드 연결 안 됨

**증상:** 컨트랙트 함수 호출 안 됨

**해결:**
1. 컨트랙트 주소 확인 (배포된 주소와 일치?)
2. ABI 확인 (함수 이름, 인자 타입 일치?)
3. 네트워크 확인 (Sepolia인지?)

### 4.4 BigInt 타입 오류

**증상:** "Cannot convert BigInt to Number" 오류

**해결:**
```typescript
// 잘못된 예
const display = value / 1e18;

// 올바른 예
import { formatEther } from 'viem';
const display = formatEther(value);
```

### 4.5 Hydration 오류 (Next.js)

**증상:** "Text content does not match server-rendered HTML"

**해결:**
```typescript
'use client';

import { useState, useEffect } from 'react';

function WalletInfo() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  if (!mounted) return null;
  // 지갑 관련 렌더링
}
```

### 4.6 WalletConnect 연결 안 됨

**증상:** QR 코드 안 뜸, 모바일 지갑 연결 실패

**해결:**
1. `config/wagmi.ts`에서 projectId 확인
2. WalletConnect Cloud에서 프로젝트 활성화 확인
3. 브라우저 콘솔에서 에러 메시지 확인

---

## 5. 평가 기준

### 5.1 기술 요구사항 (40%)

| 항목 | 점수 | 체크 |
|------|------|------|
| Solidity 버전 | 5점 | 0.8.26+ 사용 |
| 상태 변수 | 5점 | 1개 이상 |
| public/external 함수 | 5점 | 2개 이상 |
| 이벤트 | 5점 | 상태 변경 시 발생 |
| Foundry 테스트 | 10점 | 5개 이상 |
| 프론트엔드 연동 | 10점 | wagmi + RainbowKit |

### 5.2 기능 요구사항 (30%)

| 항목 | 점수 | 체크 |
|------|------|------|
| 지갑 연결 | 10점 | ConnectButton 동작 |
| 컨트랙트 읽기 | 5점 | useReadContract |
| 컨트랙트 쓰기 | 10점 | useWriteContract |
| 트랜잭션 상태 | 5점 | pending/success 표시 |

### 5.3 코드 품질 (20%)

| 항목 | 점수 | 체크 |
|------|------|------|
| 주석 | 5점 | 주요 로직에 주석 |
| 네이밍 | 5점 | 의미 있는 변수/함수 이름 |
| 구조 | 10점 | 파일 분리, 폴더 구조 |

### 5.4 창의성 (10%)

| 항목 | 점수 | 체크 |
|------|------|------|
| 독창적 아이디어 | 5점 | 예시 아이디어 변형 또는 새로운 아이디어 |
| 추가 기능 | 5점 | 기본 요구사항 이상 구현 |

---

## 마무리 체크리스트

제출 전 최종 확인:

- [ ] 컨트랙트가 Sepolia에 배포됨
- [ ] 프론트엔드에서 지갑 연결 동작
- [ ] 컨트랙트 읽기/쓰기 동작
- [ ] README.md에 프로젝트 설명 작성
- [ ] README.md에 컨트랙트 주소 기재
- [ ] CHECKLIST.md의 필수 항목 모두 체크
- [ ] 스크린샷 또는 데모 영상 준비

---

## 도움 요청

막히는 부분이 있으면:

1. 에러 메시지 복사
2. 시도한 방법 정리
3. Slack 채널에 질문

**응원합니다! 완성하시면 Bay-17th의 첫 dApp 개발자가 됩니다.**
