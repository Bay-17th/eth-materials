// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title HelloWorld
/// @notice 가장 간단한 스마트 컨트랙트 예제
/// @dev 이 파일은 문법 참조용입니다
contract HelloWorld {
    /// @notice 저장된 인사말
    string public greeting = "Hello, Bay-17th!";

    /// @notice 인사말을 변경합니다
    /// @param _newGreeting 새로운 인사말
    function setGreeting(string memory _newGreeting) public {
        greeting = _newGreeting;
    }

    /// @notice 현재 인사말을 반환합니다
    /// @return 저장된 인사말 문자열
    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}
