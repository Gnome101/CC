// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Interfaces/IMailbox.sol";
import "./Interfaces/IInterchainSecurityModule.sol";
import "./Interfaces/IMessageRecipient.sol";
import "./Interfaces/ZKaptchaInterface.sol";

contract ZKCaptcha {
    address immutable dev;
    address public immutable cookieGame;
    ZKaptchaInterface immutable zkaptcha;
    IMailbox immutable mailBox;

    uint32 public constant arbNovaDID = 42170;

    modifier onlyDev() {
        //The game only works if a session was started
        require(msg.sender == dev);
        _;
    }

    constructor(address _cookieGame) {
        dev = msg.sender;
        cookieGame = _cookieGame;
        zkaptcha = ZKaptchaInterface(
            0xf5DCa59461adFFF5089BE5068364eC10B86c2a88 //zKaptcha contract
        );
        mailBox = IMailbox(0xCC737a94FecaeC165AbCf12dED095BB13F037685); //Arbitum Goerli Mailbox
    }

    mapping(address => uint256) userCaptchaStart;
    uint256 public timeSpent;

    function submitCaptcha(bytes memory proof) internal {
        require(zkaptcha.verifyZkProof(proof));
        timeSpent = block.timestamp - userCaptchaStart[msg.sender];
    }

    uint256 public requests;
    bool public validResponse;
    mapping(address => bytes) public userData;

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external {
        require(msg.sender == address(mailBox));
        require(_origin == uint32(arbNovaDID));
        requests = requests + 1;
        (bytes memory res, address user) = abi.decode(
            _message,
            (bytes, address)
        );
        bytes memory newMessage = abi.encodePacked(res);
        try zkaptcha.verifyZkProof(newMessage) returns (bool) {
            validResponse = zkaptcha.verifyZkProof(newMessage);
        } catch {
            validResponse = false;
        }
        if (validResponse) {
            uint256 num = 2;
            bytes memory response = abi.encode(num, user);
            mailBox.dispatch(
                arbNovaDID,
                addressToBytes32(cookieGame),
                response
            );
        } else {
            uint256 num = 1;
            bytes memory response = abi.encode(num, user);
            mailBox.dispatch(
                arbNovaDID,
                addressToBytes32(cookieGame),
                response
            );
        }
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }

    function interchainSecurityModule() external pure returns (address) {
        return 0x963C7950B97e2ce301Eb49Fb1928aA5C7fe8e8eC;
    }
}
