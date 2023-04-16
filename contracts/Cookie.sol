// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cookie is ERC20 {
    address public owner;

    function setOwner(address _owner) public {
        owner = _owner;
    }

    constructor() ERC20("Cookie", "CKIE") {
        owner = msg.sender;
        _mint(msg.sender, 1000 * 10 ** 18);
    }

    function mint(uint256 mintAmount) public {
        require(msg.sender == owner);
        _mint(msg.sender, mintAmount);
    }
}
