// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

//Users can upgrade their cookie and earn more
//For example, a user can do a cursor upgrade and earn 0.1 cookies per second
//Users are given an ERC20 token called cookies(right now just points)
interface ZKaptchaInterface {
    function verifyZkProof(bytes calldata zkProof) external view returns (bool);
}

contract ZKCaptcha {
    address immutable dev;
    address immutable cookieGame;
    ZKaptchaInterface immutable zkaptcha;
    event captchaNeededForUser(address indexed user);

    uint32 public constant arbNovaDID = 42170;

    modifier onlyDev() {
        //The game only works if a session was started
        require(msg.sender == dev);
        _;
    }

    // implement ZKaptcha anti-bot in your smart contract

    constructor(address _cookieGame) {
        dev = msg.sender;
        cookieGame = _cookieGame;
        zkaptcha = ZKaptchaInterface(
            0xCDA94740093d8ca3dBF7f8E0c9a22580D032D91d
        );
    }

    mapping(address => uint256) userCaptchaStart;
    uint256 public timeSpent;

    function submitCaptcha(bytes memory proof) internal {
        require(zkaptcha.verifyZkProof(proof));
        timeSpent = block.timestamp - userCaptchaStart[msg.sender];
    }

    function isCaptchaValid(bytes memory proof) public view returns (uint256) {
        if (zkaptcha.verifyZkProof(proof)) {
            return 1921;
        }
        return 1;
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}
