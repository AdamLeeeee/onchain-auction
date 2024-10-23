// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    uint256 public startingPrice;
    address payable public owner;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    mapping (address => uint256) public coolTime;
    uint256 public coolTimeLimit;
    uint256 public endTime;
    bool public ended;

    event Bid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed highestBidder, uint256 highestBid);

    constructor(uint256 _startingPrice, uint256 _endTime, uint256 _coolTimeLimit) {
        startingPrice = _startingPrice;
        endTime = _endTime;
        coolTimeLimit = _coolTimeLimit;
        owner = payable(msg.sender);
    }

    function bid() public payable {
        require(block.timestamp < endTime, "Auction already ended.");
        require(msg.value > 0, "Bid must be greater than 0.");
        require(coolTime[msg.sender] < block.timestamp, "You must wait for the cool time to pass.");
        require(bids[msg.sender] + msg.value > highestBid, "There already is a higher bid.");

        highestBidder = msg.sender;
        payable(highestBidder).transfer(msg.value);
        bids[highestBidder] += msg.value;
        highestBid = bids[highestBidder];
        coolTime[highestBidder] = block.timestamp + coolTimeLimit;

        if (block.timestamp > endTime - coolTimeLimit) {
            endTime += coolTimeLimit;
        }

        emit Bid(highestBidder, highestBid);
    }

    function withdraw() public returns (bool) {
        require(bids[msg.sender] > 0, "No funds to withdraw.");
        require(ended || msg.sender != highestBidder, "Only the highest bidder can not withdraw before the auction ends.");
        
        payable(msg.sender).transfer(bids[msg.sender]);
        bids[msg.sender] =  0;
        coolTime[msg.sender] = 0;

        return true;
    }

    function end() public {
        require(block.timestamp >= endTime, "Auction not yet ended.");
        require(!ended, "end function has already been called.");

        payable(owner).transfer(highestBid);
        ended = true; 

        emit AuctionEnded(highestBidder, highestBid);
    }

}
