// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {NftMarketplace, Listing} from "../src/NftMarket.sol";
import "../src/MockNft.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";


contract NftMarketplaceTest is Test{
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
      listing = Listing({nftAddress: nftAddr, price: price, seller: address(0), deadline: deadline, signature: bytes("")});
      // Nft.mint(owner, tokenId);
        bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
  
      (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPriv, msgHash.toEthSignedMessageHash());
      signature = getSig(v, r, s);
  }

   function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }
  

  function testSig() public {
    vm.startPrank(owner);
    bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
    bytes32 _signedMsg = msgHash.toEthSignedMessageHash();
    address signer = _signedMsg.recover(signature);
    assertEq(signer, owner);
    vm.stopPrank();
  }


  function testApproval() public {
   vm.startPrank(user);
   Nft.mint(user, 443);
   vm.expectRevert("Not approved");
    listing.seller = user;
   vm.stopPrank();
  }

  function testList() public {
    vm.startPrank(owner);
    Nft.mint(owner, tokenId);
    Nft.approve(address(NftMarket), tokenId);
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    Listing memory _l = NftMarket.getListing(0);
    assertEq(_l.price, price);
    assertEq(_l.deadline, deadline);
    assertEq(_l.seller, owner);
    assertEq(_l.signature, signature);
    vm.stopPrank();
  }

  function testPrice() public {
    vm.startPrank(owner);
    Nft.mint(owner, 444);
    Nft.approve(address(NftMarket), 444);
    vm.expectRevert();
    NftMarket.listItem(nftAddr, 444, 0, deadline, signature);
  }

  function testDeadline() public {
    vm.startPrank(owner);
    Nft.mint(owner, tokenId);
    Nft.approve(address(NftMarket), tokenId);
    vm.expectRevert(NftMarketplace.MinDurationNotMet.selector);
    uint256 _deadline = 20 minutes;
    NftMarket.listItem(nftAddr, tokenId, price, _deadline, signature);
  }

  function testListFailIfNotOwner() public {
    vm.startPrank(user);
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, 1 ether, deadline, signature);
    Listing memory _l = NftMarket.getListing(1);
    assertEq(_l.price, 0 ether);
    assertEq(_l.deadline, 0);
    assertEq(_l.seller, address(0));
    assertEq(_l.signature, bytes(""));
    vm.stopPrank();
  }

  // function testIsOwner() public {
  //   vm.expectRevert();
  //   NftMarket.listItem(listing, tokenId, price, deadline, signature);
  // }

  function testBuyShouldRevertIfNotListed() public {
    vm.expectRevert(abi.encodeWithSelector(NftMarketplace.NotListed.selector, 3));
    NftMarket.buyItem(3, bytes32("sss"));
  }
      }