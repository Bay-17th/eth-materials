# wagmi로 Web3 프론트엔드 개발하기

이 문서는 wagmi를 사용하여 이더리움과 상호작용하는 React 애플리케이션을 개발하는 방법을 설명합니다.

## 목차

1. [wagmi란?](#1-wagmi란)
2. [설치 및 설정](#2-설치-및-설정)
3. [계정 상태 훅](#3-계정-상태-훅)
4. [컨트랙트 읽기](#4-컨트랙트-읽기)
5. [컨트랙트 쓰기](#5-컨트랙트-쓰기)
6. [이벤트 리스닝](#6-이벤트-리스닝)
7. [BigInt 다루기](#7-bigint-다루기)
8. [에러 처리](#8-에러-처리)

---

## 1. wagmi란?

wagmi는 "We're All Gonna Make It"의 약자로, 이더리움과 상호작용하는 React 애플리케이션을 쉽게 개발할 수 있게 해주는 **React Hooks 라이브러리**입니다.

### 주요 특징

| 특징 | 설명 |
|------|------|
| React Hooks | 선언적인 React Hooks API 제공 |
| viem 기반 | ethers.js 대신 가볍고 빠른 viem 사용 |
| 타입 안전 | TypeScript 기반으로 완벽한 타입 지원 |
| 캐싱 | TanStack Query 기반의 자동 캐싱 |
| 자동 리페치 | 블록 갱신, 포커스 복귀 시 자동 데이터 갱신 |

### 왜 wagmi를 사용하나요?

```typescript
// 직접 viem을 사용하면 복잡한 상태 관리가 필요
const [data, setData] = useState(null);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);

// wagmi를 사용하면 한 줄로 해결
const { data, isLoading, error } = useReadContract({ ... });
```

---

## 2. 설치 및 설정

### 2.1 패키지 설치

```bash
npm install wagmi viem @tanstack/react-query
```

| 패키지 | 역할 |
|--------|------|
| wagmi | React hooks 제공 |
| viem | 이더리움 상호작용 (ABI 인코딩, 트랜잭션 전송 등) |
| @tanstack/react-query | 데이터 캐싱 및 상태 관리 |

### 2.2 Config 파일 생성

`config/wagmi.ts`:

```typescript
import { createConfig, http } from 'wagmi';
import { sepolia, mainnet } from 'wagmi/chains';

// createConfig로 wagmi 설정을 생성합니다
export const config = createConfig({
  // 지원할 체인 목록
  chains: [sepolia, mainnet],

  // 각 체인의 RPC 연결 설정
  // http()는 기본 public RPC를 사용합니다
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
});
```

> **팁:** 프로덕션에서는 Alchemy나 Infura의 RPC URL을 사용하세요:
> ```typescript
> [sepolia.id]: http('https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY'),
> ```

### 2.3 Provider 설정

`app/layout.tsx`:

```typescript
'use client';

import { WagmiProvider } from 'wagmi';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { config } from '@/config/wagmi';

// React Query 클라이언트 생성
const queryClient = new QueryClient();

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {/* WagmiProvider가 QueryClientProvider보다 바깥에 위치해야 합니다 */}
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </WagmiProvider>
      </body>
    </html>
  );
}
```

---

## 3. 계정 상태 훅

### 3.1 useAccount: 연결된 지갑 정보

```typescript
import { useAccount } from 'wagmi';

function WalletInfo() {
  const {
    address,        // 지갑 주소 (0x...)
    isConnected,    // 연결 여부 (boolean)
    isConnecting,   // 연결 시도 중 (boolean)
    isDisconnected, // 연결 해제됨 (boolean)
    connector,      // 사용 중인 지갑 커넥터 (MetaMask, WalletConnect 등)
  } = useAccount();

  if (!isConnected) {
    return <div>지갑이 연결되지 않았습니다</div>;
  }

  return (
    <div>
      <p>주소: {address}</p>
      <p>지갑: {connector?.name}</p>
    </div>
  );
}
```

### 3.2 useBalance: ETH 잔액 조회

```typescript
import { useBalance } from 'wagmi';

function Balance() {
  const { address } = useAccount();

  const { data: balance, isLoading } = useBalance({
    address: address,
  });

  if (isLoading) return <div>로딩 중...</div>;

  return (
    <div>
      잔액: {balance?.formatted} {balance?.symbol}
    </div>
  );
}
```

### 3.3 useChainId: 현재 체인 ID

```typescript
import { useChainId } from 'wagmi';

function NetworkInfo() {
  const chainId = useChainId();

  const networkName = {
    1: 'Ethereum Mainnet',
    11155111: 'Sepolia Testnet',
  };

  return <div>현재 네트워크: {networkName[chainId] ?? `Chain ID: ${chainId}`}</div>;
}
```

---

## 4. 컨트랙트 읽기

### 4.1 useReadContract 기본 사용법

컨트랙트의 view/pure 함수를 호출하여 데이터를 읽습니다.

```typescript
import { useReadContract } from 'wagmi';

// ABI는 반드시 as const로 선언해야 타입 추론이 됩니다!
const counterABI = [
  {
    name: 'getCount',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: 'count', type: 'uint256' }],
  },
] as const;

function Counter() {
  const { data, isLoading, error, refetch } = useReadContract({
    address: '0x...', // 컨트랙트 주소
    abi: counterABI,
    functionName: 'getCount',
  });

  if (isLoading) return <div>로딩 중...</div>;
  if (error) return <div>에러: {error.message}</div>;

  return (
    <div>
      <p>카운트: {data?.toString()}</p>
      <button onClick={() => refetch()}>새로고침</button>
    </div>
  );
}
```

### 4.2 인자가 있는 함수 호출

```typescript
const balanceOfABI = [
  {
    name: 'balanceOf',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: 'balance', type: 'uint256' }],
  },
] as const;

function TokenBalance({ address }) {
  const { data: balance } = useReadContract({
    address: '0x...', // 토큰 컨트랙트 주소
    abi: balanceOfABI,
    functionName: 'balanceOf',
    args: [address], // 함수 인자를 배열로 전달
  });

  return <div>토큰 잔액: {balance?.toString()}</div>;
}
```

### 4.3 자동 리페치 설정

```typescript
const { data } = useReadContract({
  address: '0x...',
  abi: counterABI,
  functionName: 'getCount',
  query: {
    // 10초마다 자동으로 데이터 갱신
    refetchInterval: 10000,

    // 윈도우 포커스 복귀 시 자동 갱신 (기본값: true)
    refetchOnWindowFocus: true,

    // 네트워크 재연결 시 자동 갱신
    refetchOnReconnect: true,
  },
});
```

---

## 5. 컨트랙트 쓰기

### 5.1 useWriteContract 기본 사용법

컨트랙트의 상태를 변경하는 함수를 호출합니다.

```typescript
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

const incrementABI = [
  {
    name: 'increment',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [],
    outputs: [],
  },
] as const;

function IncrementButton() {
  // 트랜잭션 전송
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  // 트랜잭션 확인 대기
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleIncrement = () => {
    writeContract({
      address: '0x...',
      abi: incrementABI,
      functionName: 'increment',
    });
  };

  return (
    <div>
      <button
        onClick={handleIncrement}
        disabled={isPending || isConfirming}
      >
        {isPending ? '서명 대기 중...' :
         isConfirming ? '확인 중...' :
         '증가'}
      </button>

      {isSuccess && <p>트랜잭션 성공!</p>}
      {error && <p>에러: {error.message}</p>}
    </div>
  );
}
```

### 5.2 인자가 있는 함수 호출

```typescript
const setValueABI = [
  {
    name: 'setValue',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'newValue', type: 'uint256' }],
    outputs: [],
  },
] as const;

function SetValueForm() {
  const [value, setValue] = useState('');
  const { writeContract, isPending } = useWriteContract();

  const handleSubmit = (e) => {
    e.preventDefault();
    writeContract({
      address: '0x...',
      abi: setValueABI,
      functionName: 'setValue',
      args: [BigInt(value)], // uint256은 BigInt로 변환
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="number"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder="새 값 입력"
      />
      <button disabled={isPending}>설정</button>
    </form>
  );
}
```

### 5.3 payable 함수 호출 (ETH 전송)

```typescript
const donateABI = [
  {
    name: 'donate',
    type: 'function',
    stateMutability: 'payable',
    inputs: [],
    outputs: [],
  },
] as const;

function DonateButton() {
  const { writeContract } = useWriteContract();

  const handleDonate = () => {
    writeContract({
      address: '0x...',
      abi: donateABI,
      functionName: 'donate',
      value: parseEther('0.1'), // 0.1 ETH 전송
    });
  };

  return <button onClick={handleDonate}>0.1 ETH 기부하기</button>;
}
```

---

## 6. 이벤트 리스닝

### 6.1 useWatchContractEvent로 실시간 이벤트 구독

```typescript
import { useWatchContractEvent } from 'wagmi';

const transferEventABI = [
  {
    name: 'Transfer',
    type: 'event',
    inputs: [
      { indexed: true, name: 'from', type: 'address' },
      { indexed: true, name: 'to', type: 'address' },
      { indexed: false, name: 'value', type: 'uint256' },
    ],
  },
] as const;

function TransferWatcher() {
  const [transfers, setTransfers] = useState([]);

  useWatchContractEvent({
    address: '0x...', // 토큰 컨트랙트 주소
    abi: transferEventABI,
    eventName: 'Transfer',
    onLogs(logs) {
      // 새 이벤트가 발생하면 호출됨
      console.log('새 전송 이벤트:', logs);

      setTransfers((prev) => [
        ...prev,
        ...logs.map((log) => ({
          from: log.args.from,
          to: log.args.to,
          value: log.args.value?.toString(),
        })),
      ]);
    },
  });

  return (
    <div>
      <h3>최근 전송 내역</h3>
      <ul>
        {transfers.map((t, i) => (
          <li key={i}>
            {t.from?.slice(0, 6)} → {t.to?.slice(0, 6)}: {t.value}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### 6.2 특정 주소 필터링

```typescript
useWatchContractEvent({
  address: '0x...',
  abi: transferEventABI,
  eventName: 'Transfer',
  args: {
    // 특정 주소에서 발생한 전송만 구독
    from: '0x...myAddress',
  },
  onLogs(logs) {
    console.log('내 전송 이벤트:', logs);
  },
});
```

---

## 7. BigInt 다루기

이더리움에서 숫자는 모두 uint256으로 표현되어 JavaScript의 Number 범위를 초과합니다.
wagmi와 viem은 이를 위해 **BigInt**를 사용합니다.

### 7.1 viem의 유틸리티 함수

```typescript
import { parseEther, formatEther, parseUnits, formatUnits } from 'viem';

// ETH 변환
parseEther('1.5');           // 1500000000000000000n (BigInt)
formatEther(1500000000000000000n); // '1.5'

// 임의의 단위 변환 (토큰 등)
parseUnits('100', 18);       // 100 * 10^18 (BigInt)
formatUnits(100000000n, 6);  // '100' (USDC 같은 6 decimal 토큰)
```

### 7.2 BigInt 주의사항

```typescript
// 잘못된 예
const wrong = balance + 1; // BigInt + Number는 오류!

// 올바른 예
const correct = balance + 1n; // 1n은 BigInt 리터럴

// 문자열로 변환
const str = balance.toString();

// 화면에 표시할 때
<span>{formatEther(balance)} ETH</span>
```

### 7.3 입력값 BigInt 변환

```typescript
function AmountInput() {
  const [amount, setAmount] = useState('');

  const handleSubmit = () => {
    // 문자열을 BigInt로 변환
    const amountWei = parseEther(amount);
    console.log('Wei 값:', amountWei);
  };

  return (
    <div>
      <input
        type="text"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="ETH 금액"
      />
      <button onClick={handleSubmit}>전송</button>
    </div>
  );
}
```

---

## 8. 에러 처리

### 8.1 try/catch 패턴

```typescript
import { useWriteContract } from 'wagmi';

function SafeTransfer() {
  const { writeContractAsync } = useWriteContract();
  const [status, setStatus] = useState('');

  const handleTransfer = async () => {
    try {
      setStatus('트랜잭션 전송 중...');

      const hash = await writeContractAsync({
        address: '0x...',
        abi: transferABI,
        functionName: 'transfer',
        args: ['0x...', parseEther('1')],
      });

      setStatus(`성공! 해시: ${hash}`);
    } catch (error) {
      // 에러 타입에 따른 처리
      if (error.name === 'ContractFunctionExecutionError') {
        setStatus('컨트랙트 실행 실패: ' + error.shortMessage);
      } else if (error.name === 'UserRejectedRequestError') {
        setStatus('사용자가 트랜잭션을 거부했습니다');
      } else {
        setStatus('알 수 없는 에러: ' + error.message);
      }
    }
  };

  return (
    <div>
      <button onClick={handleTransfer}>전송</button>
      <p>{status}</p>
    </div>
  );
}
```

### 8.2 일반적인 에러 유형

| 에러 이름 | 원인 | 해결 방법 |
|-----------|------|-----------|
| `UserRejectedRequestError` | 사용자가 지갑에서 거부 | 사용자에게 안내 |
| `ContractFunctionExecutionError` | require 조건 실패 | 컨트랙트 조건 확인 |
| `InsufficientFundsError` | ETH 잔액 부족 | 잔액 확인 후 안내 |
| `ChainMismatchError` | 잘못된 네트워크 | 네트워크 전환 안내 |

### 8.3 사용자 친화적 에러 메시지

```typescript
function getErrorMessage(error) {
  // 사용자 거부
  if (error.message.includes('User rejected')) {
    return '지갑에서 트랜잭션을 승인해주세요.';
  }

  // 잔액 부족
  if (error.message.includes('insufficient funds')) {
    return 'ETH 잔액이 부족합니다. Sepolia Faucet에서 테스트 ETH를 받으세요.';
  }

  // require 실패
  if (error.message.includes('execution reverted')) {
    return '컨트랙트 조건을 만족하지 못합니다. 입력값을 확인하세요.';
  }

  // 기본 메시지
  return '트랜잭션 처리 중 오류가 발생했습니다.';
}
```

---

## 실습: Counter 컨트랙트 연동

아래는 간단한 Counter 컨트랙트와 연동하는 전체 예제입니다.

### Solidity 컨트랙트

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Counter {
    uint256 public count;

    event CountChanged(uint256 newCount);

    function increment() public {
        count += 1;
        emit CountChanged(count);
    }

    function decrement() public {
        require(count > 0, "Count cannot be negative");
        count -= 1;
        emit CountChanged(count);
    }
}
```

### React 컴포넌트

```typescript
'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

const counterABI = [
  { name: 'count', type: 'function', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint256' }] },
  { name: 'increment', type: 'function', stateMutability: 'nonpayable', inputs: [], outputs: [] },
  { name: 'decrement', type: 'function', stateMutability: 'nonpayable', inputs: [], outputs: [] },
] as const;

const CONTRACT_ADDRESS = '0x...'; // 배포된 컨트랙트 주소

export function CounterApp() {
  // 카운트 읽기
  const { data: count, refetch } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: counterABI,
    functionName: 'count',
  });

  // 트랜잭션 전송
  const { writeContract, data: hash, isPending } = useWriteContract();

  // 트랜잭션 확인
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    onSuccess: () => refetch(), // 성공 시 카운트 새로고침
  });

  return (
    <div>
      <h1>Counter: {count?.toString() ?? '로딩 중...'}</h1>

      <button
        onClick={() => writeContract({ address: CONTRACT_ADDRESS, abi: counterABI, functionName: 'increment' })}
        disabled={isPending || isConfirming}
      >
        + 증가
      </button>

      <button
        onClick={() => writeContract({ address: CONTRACT_ADDRESS, abi: counterABI, functionName: 'decrement' })}
        disabled={isPending || isConfirming}
      >
        - 감소
      </button>

      {isPending && <p>지갑에서 서명해주세요...</p>}
      {isConfirming && <p>트랜잭션 확인 중...</p>}
      {isSuccess && <p>성공!</p>}
    </div>
  );
}
```

---

## 참고 자료

- [wagmi 공식 문서](https://wagmi.sh)
- [viem 공식 문서](https://viem.sh)
- [TanStack Query 문서](https://tanstack.com/query)
- [RainbowKit 연동 가이드](/week-05/dev/rainbowkit-guide.md)
