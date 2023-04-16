// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

//Users can upgrade their cookie and earn more
//For example, a user can do a cursor upgrade and earn 0.1 cookies per second
//Users are given an ERC20 token called cookies(right now just points)
interface ZKaptchaInterface {
    function verifyZkProof(bytes calldata zkProof) external view returns (bool);
}

contract CaptchaPoints {
    event captchaCompleted(
        address indexed user,
        uint256 timeStarted,
        uint256 timeEnded
    );

    address immutable dev;
    ZKaptchaInterface immutable zkaptcha;
    modifier onlyDev() {
        //The game only works if a session was started
        require(msg.sender == dev);
        _;
    }

    constructor() {
        dev = msg.sender;

        zkaptcha = ZKaptchaInterface(
            0xf5DCa59461adFFF5089BE5068364eC10B86c2a88
        );
    }

    mapping(address => uint256) userCaptchaStart;
    mapping(address => uint256) userTimeSpent;

    function giveUserCaptcha(address user) public onlyDev {
        userCaptchaStart[user] = block.timestamp;
    }

    function submitCaptcha(bytes memory proof) public {
        require(zkaptcha.verifyZkProof(proof));
        userTimeSpent[msg.sender] =
            block.timestamp -
            userCaptchaStart[msg.sender];
        emit captchaCompleted(
            msg.sender,
            userCaptchaStart[msg.sender],
            block.timestamp
        );
    }
}
