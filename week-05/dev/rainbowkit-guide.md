# RainbowKit으로 지갑 연결하기

이 문서는 RainbowKit을 사용하여 Web3 dApp에 지갑 연결 기능을 구현하는 방법을 설명합니다.

## 목차

1. [RainbowKit이란?](#1-rainbowkit이란)
2. [설치 및 설정](#2-설치-및-설정)
3. [ConnectButton](#3-connectbutton)
4. [트랜잭션 전송](#4-트랜잭션-전송)
5. [체인 전환](#5-체인-전환)
6. [테스트넷 사용하기](#6-테스트넷-사용하기)
7. [일반적인 문제 해결](#7-일반적인-문제-해결)

---

## 1. RainbowKit이란?

RainbowKit은 이더리움 dApp에 **지갑 연결 UI**를 쉽게 추가할 수 있는 React 라이브러리입니다.

### 주요 특징

| 특징 | 설명 |
|------|------|
| 다양한 지갑 지원 | MetaMask, Coinbase Wallet, Rainbow, WalletConnect 등 100+ 지갑 |
| 아름다운 UI | 별도 디자인 없이 바로 사용 가능한 완성된 UI |
| 반응형 디자인 | 모바일과 데스크톱 모두 최적화 |
| 커스터마이징 | 테마, 언어, 지갑 목록 등 커스터마이징 가능 |
| wagmi 통합 | wagmi v2와 완벽 호환 |

### RainbowKit이 제공하는 것

```
RainbowKit = 지갑 연결 UI + 지갑 목록 관리 + 연결 상태 표시
wagmi      = 이더리움 상호작용 (트랜잭션, 컨트랙트 호출 등)
```

즉, RainbowKit은 **UI 레이어**이고, 실제 블록체인 상호작용은 **wagmi**가 담당합니다.

---

## 2. 설치 및 설정

### 2.1 패키지 설치

```bash
npm install @rainbow-me/rainbowkit wagmi viem @tanstack/react-query
```

### 2.2 WalletConnect Project ID 발급

RainbowKit은 WalletConnect를 통해 모바일 지갑과 연결합니다.

1. [WalletConnect Cloud](https://cloud.walletconnect.com) 접속
2. 회원가입 후 새 프로젝트 생성
3. Project ID 복사

### 2.3 Config 파일 생성

`config/wagmi.ts`:

```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

// WalletConnect Cloud에서 발급받은 Project ID
const WALLETCONNECT_PROJECT_ID = 'your-project-id';

export const config = getDefaultConfig({
  appName: 'My dApp',           // 지갑에서 표시되는 앱 이름
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [sepolia],            // 지원하는 체인
  ssr: true,                    // Next.js SSR 지원
});
```

### 2.4 Provider 설정

`app/layout.tsx`:

```typescript
'use client';

// RainbowKit 스타일 import (필수!)
import '@rainbow-me/rainbowkit/styles.css';

import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { config } from '@/config/wagmi';

const queryClient = new QueryClient();

export default function RootLayout({ children }) {
  return (
    <html lang="ko">
      <body>
        {/* Provider 순서 중요! */}
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            <RainbowKitProvider>
              {children}
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </body>
    </html>
  );
}
```

---

## 3. ConnectButton

### 3.1 기본 사용법

가장 간단한 방법: `ConnectButton` 컴포넌트를 그대로 사용

```typescript
'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

export default function Header() {
  return (
    <header>
      <h1>My dApp</h1>
      <ConnectButton />
    </header>
  );
}
```

ConnectButton은 자동으로:
- 연결되지 않음 → "Connect Wallet" 버튼 표시
- 연결됨 → 주소, 잔액, 네트워크 표시 + 드롭다운 메뉴

### 3.2 ConnectButton Props

```typescript
<ConnectButton
  showBalance={false}           // 잔액 숨기기
  chainStatus="icon"            // 체인을 아이콘으로만 표시
  accountStatus="avatar"        // 주소를 아바타로만 표시
/>
```

| Prop | 값 | 설명 |
|------|-----|------|
| `showBalance` | `true/false` | 잔액 표시 여부 |
| `chainStatus` | `"full"/"icon"/"name"/"none"` | 체인 표시 방식 |
| `accountStatus` | `"full"/"avatar"/"address"` | 계정 표시 방식 |

### 3.3 ConnectButton.Custom으로 완전 커스터마이징

완전히 커스텀 UI가 필요할 때:

```typescript
'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

export function CustomConnectButton() {
  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        mounted,
      }) => {
        const ready = mounted;
        const connected = ready && account && chain;

        return (
          <div>
            {!connected ? (
              <button
                onClick={openConnectModal}
                className="bg-blue-500 text-white px-4 py-2 rounded"
              >
                지갑 연결하기
              </button>
            ) : chain.unsupported ? (
              <button
                onClick={openChainModal}
                className="bg-red-500 text-white px-4 py-2 rounded"
              >
                잘못된 네트워크
              </button>
            ) : (
              <div className="flex gap-2">
                <button
                  onClick={openChainModal}
                  className="bg-gray-200 px-3 py-2 rounded"
                >
                  {chain.name}
                </button>
                <button
                  onClick={openAccountModal}
                  className="bg-gray-200 px-3 py-2 rounded"
                >
                  {account.displayName}
                </button>
              </div>
            )}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
}
```

---

## 4. 트랜잭션 전송

RainbowKit은 지갑 연결 UI만 담당합니다. 트랜잭션은 **wagmi**를 사용합니다.

### 4.1 ETH 전송 (useSendTransaction)

```typescript
'use client';

import { useSendTransaction, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { useState } from 'react';

export function SendETH() {
  const [to, setTo] = useState('');
  const [amount, setAmount] = useState('');

  // 트랜잭션 전송
  const { sendTransaction, data: hash, isPending } = useSendTransaction();

  // 트랜잭션 확인 대기
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleSend = () => {
    sendTransaction({
      to: to as `0x${string}`,
      value: parseEther(amount),
    });
  };

  return (
    <div className="space-y-4">
      <input
        type="text"
        placeholder="받는 주소 (0x...)"
        value={to}
        onChange={(e) => setTo(e.target.value)}
        className="border p-2 w-full"
      />
      <input
        type="text"
        placeholder="금액 (ETH)"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        className="border p-2 w-full"
      />
      <button
        onClick={handleSend}
        disabled={isPending || isConfirming}
        className="bg-blue-500 text-white px-4 py-2 rounded disabled:opacity-50"
      >
        {isPending ? '서명 대기 중...' : isConfirming ? '확인 중...' : '전송'}
      </button>

      {isSuccess && (
        <p className="text-green-500">
          성공! 해시: {hash?.slice(0, 10)}...
        </p>
      )}
    </div>
  );
}
```

### 4.2 컨트랙트 호출 (useWriteContract)

```typescript
'use client';

import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

const abi = [
  {
    name: 'mint',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [],
    outputs: [],
  },
] as const;

export function MintButton() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  return (
    <div>
      <button
        onClick={() =>
          writeContract({
            address: '0x...', // 컨트랙트 주소
            abi,
            functionName: 'mint',
          })
        }
        disabled={isPending || isConfirming}
        className="bg-purple-500 text-white px-4 py-2 rounded"
      >
        {isPending ? '서명 대기...' : isConfirming ? '민팅 중...' : 'NFT 민트'}
      </button>

      {isSuccess && <p className="text-green-500">민팅 완료!</p>}
      {error && <p className="text-red-500">{error.message}</p>}
    </div>
  );
}
```

### 4.3 트랜잭션 상태 표시 패턴

```typescript
type TxStatus = 'idle' | 'pending' | 'confirming' | 'success' | 'error';

function getStatusMessage(status: TxStatus) {
  const messages = {
    idle: '준비됨',
    pending: '지갑에서 서명을 기다리는 중...',
    confirming: '블록체인에서 트랜잭션 확인 중...',
    success: '트랜잭션이 성공적으로 완료되었습니다!',
    error: '트랜잭션이 실패했습니다.',
  };
  return messages[status];
}
```

---

## 5. 체인 전환

### 5.1 useSwitchChain으로 네트워크 변경

```typescript
'use client';

import { useSwitchChain, useChainId } from 'wagmi';
import { sepolia, mainnet } from 'wagmi/chains';

export function NetworkSwitcher() {
  const chainId = useChainId();
  const { switchChain, isPending } = useSwitchChain();

  const chains = [sepolia, mainnet];

  return (
    <div className="flex gap-2">
      {chains.map((chain) => (
        <button
          key={chain.id}
          onClick={() => switchChain({ chainId: chain.id })}
          disabled={isPending || chainId === chain.id}
          className={`px-3 py-2 rounded ${
            chainId === chain.id
              ? 'bg-green-500 text-white'
              : 'bg-gray-200 hover:bg-gray-300'
          }`}
        >
          {chain.name}
        </button>
      ))}
    </div>
  );
}
```

### 5.2 지원하지 않는 체인 감지

```typescript
'use client';

import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';

export function ChainChecker() {
  const { chain } = useAccount();

  // chain이 없으면 지원하지 않는 체인에 연결됨
  if (chain?.unsupported) {
    return (
      <div className="bg-red-100 p-4 rounded">
        <p>지원하지 않는 네트워크입니다.</p>
        <p>아래 버튼을 눌러 Sepolia로 전환하세요.</p>
        <ConnectButton chainStatus="full" />
      </div>
    );
  }

  return <div>연결된 네트워크: {chain?.name}</div>;
}
```

---

## 6. 테스트넷 사용하기

### 6.1 Sepolia 테스트넷 설정

`config/wagmi.ts`에서 Sepolia만 포함:

```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'My dApp',
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [sepolia],  // Sepolia만 지원
  ssr: true,
});
```

### 6.2 테스트넷 ETH 받기 (Faucet)

개발과 테스트에 필요한 Sepolia ETH를 받을 수 있는 Faucet 목록:

| Faucet | URL | 참고 |
|--------|-----|------|
| Alchemy | [sepoliafaucet.com](https://sepoliafaucet.com) | Alchemy 계정 필요 |
| Infura | [infura.io/faucet/sepolia](https://www.infura.io/faucet/sepolia) | Infura 계정 필요 |
| QuickNode | [faucet.quicknode.com](https://faucet.quicknode.com/ethereum/sepolia) | QuickNode 계정 필요 |
| Google Cloud | [cloud.google.com/...](https://cloud.google.com/application/web3/faucet/ethereum/sepolia) | Google 계정 필요 |

> **팁:** 대부분의 Faucet은 계정이 필요하고, 하루 요청 횟수가 제한됩니다.
> 여러 Faucet을 번갈아 사용하세요.

### 6.3 테스트넷/메인넷 구분 UI

```typescript
'use client';

import { useChainId } from 'wagmi';

export function NetworkBadge() {
  const chainId = useChainId();

  // 메인넷이 아니면 경고 배지 표시
  const isTestnet = chainId !== 1;

  if (!isTestnet) return null;

  return (
    <div className="fixed top-0 left-0 right-0 bg-yellow-400 text-center py-1 text-sm">
      테스트넷에 연결되어 있습니다. 실제 ETH가 아닙니다.
    </div>
  );
}
```

---

## 7. 일반적인 문제 해결

### 7.1 SSR Hydration 오류

**증상:**
```
Text content does not match server-rendered HTML
```

**원인:** 서버와 클라이언트에서 렌더링 결과가 다름

**해결:**
1. `config/wagmi.ts`에서 `ssr: true` 확인
2. 지갑 관련 컴포넌트에 `'use client'` 추가
3. 조건부 렌더링 시 `mounted` 상태 체크:

```typescript
import { useAccount } from 'wagmi';
import { useState, useEffect } from 'react';

function WalletInfo() {
  const { address } = useAccount();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  // 마운트 전에는 아무것도 렌더링하지 않음
  if (!mounted) return null;

  return <div>{address}</div>;
}
```

### 7.2 WalletConnect 연결 안 됨

**증상:** QR 코드가 표시되지 않거나 모바일 지갑이 연결되지 않음

**확인사항:**
1. Project ID가 올바른지 확인
2. `config/wagmi.ts`에서 `projectId` 값이 `'YOUR_PROJECT_ID'`가 아닌지 확인
3. WalletConnect Cloud에서 프로젝트가 활성화되어 있는지 확인

### 7.3 BigInt 타입 오류

**증상:**
```
TypeError: Cannot convert a BigInt value to a number
```

**원인:** BigInt를 Number처럼 사용하려고 함

**해결:**
```typescript
// 잘못된 예
const display = balance / 1e18;

// 올바른 예
import { formatEther } from 'viem';
const display = formatEther(balance);
```

### 7.4 "Cannot find WagmiContext" 오류

**원인:** Provider 순서가 잘못됨

**해결:** 올바른 순서로 Provider 배치:
```typescript
<WagmiProvider config={config}>
  <QueryClientProvider client={queryClient}>
    <RainbowKitProvider>
      {children}
    </RainbowKitProvider>
  </QueryClientProvider>
</WagmiProvider>
```

### 7.5 RainbowKit 스타일이 적용 안 됨

**원인:** 스타일 import 누락

**해결:** `layout.tsx`에 스타일 import 추가:
```typescript
import '@rainbow-me/rainbowkit/styles.css';
```

---

## 실습: 지갑 연결 + 잔액 표시 컴포넌트

```typescript
'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useBalance } from 'wagmi';
import { formatEther } from 'viem';

export function WalletDashboard() {
  const { address, isConnected } = useAccount();
  const { data: balance, isLoading } = useBalance({
    address,
    query: { enabled: isConnected },
  });

  return (
    <div className="p-6 max-w-md mx-auto bg-white rounded-lg shadow">
      <h2 className="text-xl font-bold mb-4">내 지갑</h2>

      <div className="mb-4">
        <ConnectButton showBalance={false} />
      </div>

      {isConnected && (
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500">주소</span>
            <span className="font-mono">
              {address?.slice(0, 6)}...{address?.slice(-4)}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500">잔액</span>
            <span>
              {isLoading
                ? '로딩 중...'
                : `${Number(formatEther(balance?.value ?? 0n)).toFixed(4)} ETH`}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## 참고 자료

- [RainbowKit 공식 문서](https://www.rainbowkit.com/docs/introduction)
- [wagmi 공식 문서](https://wagmi.sh)
- [WalletConnect Cloud](https://cloud.walletconnect.com)
- [wagmi 기초 가이드](/week-04/dev/wagmi-basics.md)
