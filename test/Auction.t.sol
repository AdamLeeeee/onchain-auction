// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Auction.sol";

contract AuctionTest is Test {
    Auction public auction;
    address public owner;
    address public bidder1;
    address public bidder2;

    function setUp() public {
        owner = address(0x3);
        bidder1 = address(0x1);
        bidder2 = address(0x2);

        vm.prank(owner);
        auction = new Auction(100, block.timestamp + 1000, 10);
    }

    function testInitialState() public view {
        assertEq(auction.startingPrice(), 100);
        assertEq(auction.owner(), owner);
        assertEq(auction.highestBidder(), address(0));
        assertEq(auction.highestBid(), 99);
        assertEq(auction.ended(), false);
    }

    function testBid() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 200);
        auction.bid{value: 150}();

        assertEq(auction.highestBidder(), bidder1);
        assertEq(auction.highestBid(), 150);
        assertEq(auction.waitingReturns(bidder1), 0);

        vm.warp(block.timestamp + auction.coolTimeLimit() + 1);

        vm.prank(bidder2);
        vm.deal(bidder2, 300);
        auction.bid{value: 200}();

        assertEq(auction.highestBidder(), bidder2);
        assertEq(auction.highestBid(), 200);
        assertEq(auction.waitingReturns(bidder1), 150);
    }

    function testFailBidTooLow() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 100);
        auction.bid{value: 50}();
    }

    function testFailBidAfterEnd() public {
        vm.warp(block.timestamp + 1001);
        vm.prank(bidder1);
        vm.deal(bidder1, 200);
        auction.bid{value: 150}();
    }

    function testWithdraw() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 200);
        auction.bid{value: 150}();

        vm.warp(block.timestamp + auction.coolTimeLimit() + 1);

        vm.prank(bidder2);
        vm.deal(bidder2, 300);
        auction.bid{value: 200}();

        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        uint256 balanceAfter = bidder1.balance;

        assertEq(balanceAfter - balanceBefore, 150);
        assertEq(auction.waitingReturns(bidder1), 0);
    }

    function testEnd() public {
        vm.prank(bidder1);
        vm.deal(bidder1, 200);
        auction.bid{value: 150}();

        vm.warp(auction.endTime() + auction.coolTimeLimit() + 1);

        uint256 ownerBalanceBefore = owner.balance;

        assertGe(address(auction).balance, auction.highestBid(), "Contract doesn't have enough balance");

        vm.prank(owner);
        auction.end();

        assertEq(auction.ended(), true);
        assertEq(owner.balance - ownerBalanceBefore, 150);
    }

    function testFailEndTooEarly() public {
        auction.end();
    }
}
