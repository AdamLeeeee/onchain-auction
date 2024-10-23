// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    uint256 public startingPrice;
    address payable public owner;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public waitingReturns;
    mapping(address => uint256) public coolTime;
    uint256 public coolTimeLimit;
    uint256 public endTime;
    bool public ended;

    event Bid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed highestBidder, uint256 highestBid);

    constructor(uint256 _startingPrice, uint256 _endTime, uint256 _coolTimeLimit) {
        require(_startingPrice > 0, "Starting price must be greater than 0");
        require(_endTime > block.timestamp, "End time must be in the future");
        require(_coolTimeLimit > 0, "Cool time limit must be greater than 0");

        startingPrice = _startingPrice;
        endTime = _endTime;
        coolTimeLimit = _coolTimeLimit;
        highestBid = startingPrice - 1;
        owner = payable(msg.sender);
    }

    function bid() public payable {
        require(block.timestamp < endTime, "Auction already ended.");
        require(coolTime[msg.sender] < block.timestamp, "You must wait for the cool time to pass.");
        require(msg.value > highestBid, "There already is a higher bid.");

        if (highestBid != 0) {
            waitingReturns[highestBidder] += highestBid;
            waitingReturns[msg.sender] = 0;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        coolTime[highestBidder] = block.timestamp + coolTimeLimit;

        if (block.timestamp > endTime - coolTimeLimit) {
            endTime += coolTimeLimit;
        }

        emit Bid(highestBidder, highestBid);
    }

    function withdraw() public returns (bool) {
        require(waitingReturns[msg.sender] > 0, "No funds to withdraw.");

        uint256 amount = waitingReturns[msg.sender];
        waitingReturns[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");

        return true;
    }

    function end() public returns (bool) {
        require(msg.sender == owner, "Only the owner can end the auction.");
        require(block.timestamp >= endTime, "Auction not yet ended.");
        require(!ended, "end function has already been called.");

        (bool success,) = payable(owner).call{value: highestBid}("");
        require(success, "Transfer failed.");
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);

        return true;
    }
}
