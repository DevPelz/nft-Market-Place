// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NftMarketplace} from "../src/NftMarket.sol";
import {Vm} from "../out/Vm.sol";


contract NftMarketplaceTest is Test {
  NftMarketplace public NftMarket;
  Vm cheat = Vm(0x08c1AE7E46D4A13b766566033b5C47c735e19F6f);
  address public nftAddr = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  uint256 public tokenId = 9351;
  uint256 public price = 30 ether;
  uint256 public deadline = block.timestamp + 1 days;

  function setUp() public {
      NftMarket = new NftMarketplace();
      NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
  }

  function testListItem(address nftAddr, uint256 tokenId, uint256 price, uint256 deadline) public{

  }

}
