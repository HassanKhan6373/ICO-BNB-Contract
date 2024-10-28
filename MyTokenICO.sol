// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MyTokenICO {
    IMyToken public token;
    address public owner;
    uint256 public rate;  // How many tokens per BNB
    uint256 public startTime;
    uint256 public endTime;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event WithdrawBNB(address indexed owner, uint256 amount);

    constructor(
        address _tokenAddress,  // Use deployed token address
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_rate > 0, "Rate should be greater than 0");
        require(_endTime > _startTime, "Invalid ICO duration");

        token = IMyToken(_tokenAddress);  // Initialize token interface with the deployed address
        rate = _rate;
        startTime = _startTime;
        endTime = _endTime;
        owner = msg.sender;
    }

    modifier onlyWhileOpen() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ICO not active");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function buyTokens() public payable onlyWhileOpen {
        uint256 tokenAmount = msg.value * rate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        token.transfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount);
    }

    // Owner withdraws the collected BNB
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit WithdrawBNB(owner, balance);
    }

    // Withdraw unsold tokens after ICO ends
    function withdrawUnsoldTokens() public onlyOwner {
        require(block.timestamp > endTime, "ICO not ended");
        uint256 unsoldTokens = token.balanceOf(address(this));
        token.transfer(owner, unsoldTokens);
    }
}
