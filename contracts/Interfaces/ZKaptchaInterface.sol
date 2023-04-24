// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

//Users can upgrade their cookie and earn more
//For example, a user can do a cursor upgrade and earn 0.1 cookies per second
//Users are given an ERC20 token called cookies(right now just points)
interface ZKaptchaInterface {
    function verifyZkProof(bytes calldata zkProof) external view returns (bool);
}
