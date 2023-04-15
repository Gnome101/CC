// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

//Users can upgrade their cookie and earn more
//For example, a user can do a cursor upgrade and earn 0.1 cookies per second
//Users are given an ERC20 token called cookies(right now just points)
contract CookieClicker {
    address immutable dev;
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

    constructor() {
        dev = msg.sender;
        idToUpgrade[1] = Upgrade(10, 1, 0);
        idToUpgrade[2] = Upgrade(10, 0, 1);
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

    function createCookie() public {
        //Make sure user does block.timestamp first
        userCookie[msg.sender] = cookieGame(0, 0, 0, block.timestamp, 0);
    }

    function click() public {
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

    function addClick(
        address user,
        uint256 clickAmount
    ) public sessionStarted(user) {
        mostRecentUserSession[user].sessionGame.totalClicks += clickAmount;
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

    function startSession(bytes32 createdHash, uint256 sessionLength) public {
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
}
