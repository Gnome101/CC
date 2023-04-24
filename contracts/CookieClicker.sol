// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Interfaces/IMailbox.sol";
import "./Interfaces/IMessageRecipient.sol";
import "./Interfaces/IInterchainGasPaymaster.sol";
import "./Interfaces/IInterchainQueryRouter.sol";

//Users can upgrade their cookie and earn more
//For example, a user can do a cursor upgrade and earn 0.1 cookies per second
//Users are given an ERC20 token called cookies(right now just points)
interface ZKaptchaInterface {
    function verifyZkProof(bytes calldata zkProof) external view returns (bool);
}

contract CookieClicker {
    address immutable dev;
    IMailbox immutable mailBox;
    IInterchainQueryRouter public immutable queryRouter;
    IInterchainGasPaymaster public immutable interchainGasPaymaster;
    event captchaNeededForUser(address indexed user);

    modifier sessionStarted(address user) {
        //The game only works if a session was started
        require(block.timestamp <= mostRecentUserSession[user].expiraryDate);
        require(mostRecentUserSession[user].sessionActive);
        _;
    }
    modifier onlyDev() {
        //The game only works if a session was started
        require(msg.sender == dev);
        _;
    }
    modifier userHasStarted(address user) {
        if (userCookie[user].interestLastComputed == 0) {
            //If user has not started, then give set them at current timestamp
            userCookie[user].interestLastComputed = block.timestamp;
        }
        _;
    }
    uint32 public constant arbGoerliDomainID = 421613;

    // implement ZKaptcha anti-bot in your smart contract

    constructor(
        address arbogerliMailBoxAddy,
        address argbGoerliQueryAddy,
        address arbGasAddy
    ) {
        dev = msg.sender;
        idToUpgrade[1] = Upgrade(10, 1, 0);
        idToUpgrade[2] = Upgrade(10, 0, 1);
        queryRouter = IInterchainQueryRouter(argbGoerliQueryAddy);
        mailBox = IMailbox(arbogerliMailBoxAddy);
        interchainGasPaymaster = IInterchainGasPaymaster(arbGasAddy);
    }

    mapping(address => cookieGame) public userCookie;
    mapping(address => GameSession) public mostRecentUserSession;
    mapping(uint256 => Upgrade) public idToUpgrade;
    mapping(address => mapping(uint256 => uint256)) public idUserToNum; //Tracks the number of purchases of a single upgrade

    struct cookieGame {
        uint256 totalClicks;
        uint256 totalSpent;
        uint256 cookiePerSecond; //Users can earn more per second
        uint256 interestLastComputed;
        uint256 clickModifier;
    }
    struct GameSession {
        uint256 expiraryDate;
        bool sessionActive;
        bytes32 sessionHash;
        cookieGame sessionGame;
        uint256 userInterest;
    }
    struct Upgrade {
        //Turn into NFT in future
        uint256 cost;
        uint256 cookieRateBooster;
        uint256 clickModiferBooster;
    }

    function createCookie() public userHasStarted(msg.sender) {
        //Make sure user does block.timestamp first
        userCookie[msg.sender] = cookieGame(0, 0, 0, block.timestamp, 0);
    }

    function click() public userHasStarted(msg.sender) {
        userCookie[msg.sender].totalClicks +=
            1 +
            userCookie[msg.sender].clickModifier;
    }

    function simulateClick(
        address user
    ) public view returns (uint256 clickAmount) {
        clickAmount +=
            1 +
            mostRecentUserSession[user].sessionGame.clickModifier;
    }

    mapping(address => userCaptchaInformation) public userCaptchaInfo;
    uint256 public timeSpent;

    function giveUserCaptcha(address user) public onlyDev {
        userCaptchaInfo[user] = userCaptchaInformation(
            false,
            block.timestamp,
            0
        );
    }

    struct userCaptchaInformation {
        bool finished;
        uint256 captchaStart;
        uint256 captchEnd;
    }

    // alignment preserving cast

    function submitCaptcha(
        uint32 _destinationDomain,
        address captchaContract,
        uint256 gasAmount,
        //string memory message,
        bytes memory message,
        address user
    ) external payable {
        bytes32 _messageId = mailBox.dispatch(
            arbGoerliDomainID,
            addressToBytes32(captchaContract),
            abi.encode(message, user)
            //abi.encode(message)
        );
    }

    uint256 public returnedNum;
    uint256 public worked;
    uint256 public numRes;
    address public user;
    event userDidCaptcha(address user, bool correct);

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external {
        require(msg.sender == address(mailBox));
        require(_origin == uint32(arbGoerliDomainID));
        worked = 31213;
        (numRes, user) = abi.decode(_message, (uint256, address));
        if (numRes == 2) {
            returnedNum = 321;
            userCaptchaInfo[user].captchEnd = block.timestamp;
            userCaptchaInfo[user].finished = true;
            emit userDidCaptcha(user, true);
        }
        if (numRes == 1) {
            returnedNum = 123;
            userCaptchaInfo[user].captchEnd += 1;
            userCaptchaInfo[user].finished = false;
            emit userDidCaptcha(user, false);
        }
    }

    //Might make it so that a user has to send a transaction when they purchase an upgrade
    //Whenever a user purchases a cookie, the program adds up their interest
    function purchaseUpgrade(uint256 upgradeID) public {
        idUserToNum[msg.sender][upgradeID]++;
        uint256 cookieBalance = getUserCookieBalance(msg.sender);
        userCookie[msg.sender].interestLastComputed = block.timestamp;
        require(cookieBalance >= idToUpgrade[upgradeID].cost);
        userCookie[msg.sender].totalSpent +=
            idToUpgrade[upgradeID].cost *
            idUserToNum[msg.sender][upgradeID];
        userCookie[msg.sender].cookiePerSecond += idToUpgrade[upgradeID]
            .cookieRateBooster;
        userCookie[msg.sender].clickModifier += idToUpgrade[upgradeID]
            .clickModiferBooster;
    }

    function purchaseUpgradeForUser(
        address user,
        uint256 upgradeID
    ) public onlyDev {
        //We are going to be applying a debt to the user
        idUserToNum[msg.sender][upgradeID]++;
        require(idToUpgrade[upgradeID].cost > 0, "Not Real ID");
        mostRecentUserSession[user].sessionGame.totalSpent +=
            idToUpgrade[upgradeID].cost *
            idUserToNum[msg.sender][upgradeID];
        mostRecentUserSession[user].userInterest = getSessionUserInterest(user);

        //require(cookieBalance >= idToUpgrade[upgradeID].cost);
        mostRecentUserSession[user].sessionGame.cookiePerSecond += idToUpgrade[
            upgradeID
        ].cookieRateBooster;
        mostRecentUserSession[user].sessionGame.clickModifier += idToUpgrade[
            upgradeID
        ].clickModiferBooster;
        userCookie[user].interestLastComputed = block.timestamp; //Resetting interest
    }

    function getSessionUserInterest(
        address user
    ) public view returns (uint256 interestEarned) {
        uint256 timePassed = block.timestamp -
            userCookie[user].interestLastComputed;

        interestEarned =
            timePassed *
            mostRecentUserSession[user].sessionGame.cookiePerSecond;
    }

    function getUserInterest(
        address user
    ) public view returns (uint256 interestEarned) {
        uint256 timePassed = block.timestamp -
            userCookie[user].interestLastComputed;

        interestEarned = timePassed * userCookie[user].cookiePerSecond;
        if (mostRecentUserSession[user].sessionActive) interestEarned = 0; //If there is already a session then dont count regular interest NO DOUBLE DIPPING
    }

    function getUserCookieBalance(
        address user
    ) public view returns (uint256 cookieBalance) {
        cookieGame memory currentGame = userCookie[user];
        uint256 interestEarned = getUserInterest(user);
        cookieBalance =
            currentGame.totalClicks -
            currentGame.totalSpent +
            interestEarned;
    }

    function startSession(
        bytes32 createdHash,
        uint256 sessionLength
    ) public userHasStarted(msg.sender) {
        mostRecentUserSession[msg.sender].sessionHash = createdHash;
        mostRecentUserSession[msg.sender].expiraryDate =
            block.timestamp +
            sessionLength;
        //Set the session cookie rate as the users current rate
        mostRecentUserSession[msg.sender]
            .sessionGame
            .cookiePerSecond = userCookie[msg.sender].cookiePerSecond;
        //Set the session click modifier as the user's current modifier
        mostRecentUserSession[msg.sender]
            .sessionGame
            .clickModifier = userCookie[msg.sender].clickModifier;

        mostRecentUserSession[msg.sender].sessionActive = true;
    }

    function createHash(
        uint256 browserID,
        address userAddy
    ) public pure returns (bytes32 newHash) {
        newHash = keccak256(abi.encodePacked(browserID, userAddy));
    }

    function verifySession(
        uint256 browserID, //We can make this bytes
        address userAddy
    ) public view returns (bool valid) {
        valid = mostRecentUserSession[userAddy].sessionHash ==
            keccak256(abi.encodePacked(browserID, userAddy))
            ? true
            : false;
    }

    function endSession() public {
        //Allows a user to end a session and prevent it from happening
        mostRecentUserSession[msg.sender].sessionActive = false;
        //We could have an event fire off or something
    }

    function completeSession(
        uint256 browserID,
        address userAddress
    ) public onlyDev sessionStarted(userAddress) {
        require(verifySession(browserID, userAddress));
        userCookie[userAddress].totalClicks += mostRecentUserSession[
            userAddress
        ].sessionGame.totalClicks;
        uint256 userDebt = mostRecentUserSession[userAddress]
            .sessionGame
            .totalSpent;
        uint256 userInterest = mostRecentUserSession[userAddress].userInterest;

        require(getUserCookieBalance(userAddress) + userInterest >= userDebt);
        userCookie[userAddress].totalSpent += userDebt;
        userCookie[userAddress].clickModifier = mostRecentUserSession[
            userAddress
        ].sessionGame.clickModifier;
        userCookie[userAddress].cookiePerSecond = mostRecentUserSession[
            userAddress
        ].sessionGame.cookiePerSecond;
        mostRecentUserSession[userAddress].sessionActive = false;
        userCookie[userAddress].interestLastComputed = block.timestamp; //Resetting interest

        delete mostRecentUserSession[userAddress];
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function interchainSecurityModule() external pure returns (address) {
        return 0x5Fe9b2cAcD42593408A49D97aa061a1666C595E9;
    }
}
