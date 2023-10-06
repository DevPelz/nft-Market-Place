// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {NftMarketplace, Listing} from "../src/NftMarket.sol";
import "../src/MockNft.sol";
import "./Helpers.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";


contract NftMarketplaceTest is Helpers{
  using ECDSA for bytes32;
  NftMarketplace public NftMarket;
  OurNFT public Nft;

  uint256 ownerPriv = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  address public owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  address public nftAddr = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
  address public user = vm.addr(123444);
  uint256 public tokenId = 9351;
  uint256 public price = 3 ether;
  uint256 public deadline = 1 days;
  bytes public signature;

  Listing public listing;
  

  function setUp() public {
      NftMarket = new NftMarketplace();
      Nft = new OurNFT();

      signature = constructSig(nftAddr, tokenId, price, deadline, owner, ownerPriv);
   
      listing = Listing({
        nftAddress: nftAddr,
        price: price,
        seller: owner,
        deadline: deadline,
        signature: signature
      });

      Nft.mint(owner, tokenId);
  }

function testValidSig() public {
    vm.prank(owner);
    bytes memory sig = constructSig(nftAddr, tokenId, price, deadline, owner, ownerPriv);
    listing.signature = sig;
    assertEq(sig, signature);
  }


  function testNotOwner() public {
    vm.startPrank(user);
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    vm.stopPrank();
} 

  // function testNotApproved() public {
  //  vm.startPrank(owner);
  //  Nft.mint(owner, 444);
  //  vm.expectRevert(NftMarketplace.NotApprovedForMarketplace.selector);
  //   NftMarket.listItem(nftAddr, 444, price, deadline, signature);
  //  vm.stopPrank();
  // }

  function testList() public {
    vm.startPrank(owner);
    Nft.approve(address(NftMarket), tokenId);
    listing.price = 3 ether;
    listing.seller = owner;
    assertEq(listing.price, price);
    assertEq(listing.deadline, deadline);
    assertEq(listing.seller, owner);
    assertEq(listing.signature, signature);
    vm.stopPrank();
  }

  function testFailPrice() public {
    vm.startPrank(owner);
    Nft.mint(owner, 444);
    Nft.approve(address(NftMarket), 444);
    listing.price = 0 ether;
    vm.expectRevert(NftMarketplace.PriceMustBeAboveZero.selector);
    NftMarket.listItem(nftAddr, 444, price, deadline, signature);
  }

  // function testfailDeadline() public {
  //   vm.startPrank(owner);
  //   Nft.approve(address(NftMarket), tokenId);
  //   vm.expectRevert(NftMarketplace.MinDurationNotMet.selector);
  //   NftMarket.listItem(nftAddr, tokenId, price, 1 minutes, signature);
  // }

  function testListFailIfNotOwner() public {
    vm.startPrank(user);
    listing.seller = user;
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, 3 ether, deadline, signature);
    assertEq(listing.price, 3 ether);
    assertEq(listing.deadline, deadline);
    assertEq(listing.seller, user);
    assertEq(listing.signature, signature);
    vm.stopPrank();
  }

  function testBuyShouldRevertIfNotListed() public {
    vm.expectRevert(abi.encodeWithSelector(NftMarketplace.NotListed.selector, 3));
    NftMarket.buyItem(3 );
  }

  function testSuccessBuy() public {
    vm.startPrank(owner);
    Nft.approve(address(NftMarket), tokenId);
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    vm.stopPrank();

    vm.prank(user);
    NftMarket.buyItem(1);
    assertEq(Nft.ownerOf(tokenId), user);
  }

  function testUpdateListingFail() public{
    vm.startPrank(owner);
    Nft.approve(address(NftMarket), tokenId);
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    vm.stopPrank();

    vm.startPrank(user);
    vm.expectRevert(NftMarketplace.NotOwner.selector);
    NftMarket.updateListing(1, 3 ether, true);
    vm.stopPrank();
  }
      
      
  }