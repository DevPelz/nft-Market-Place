// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {NftMarketplace, Listing} from "../src/NftMarket.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ITestNft is IERC721 {
   function safeMint(address to, uint256 tokenId) external;
}

contract NftMarketplaceTest is Test{
  using ECDSA for bytes32;
  NftMarketplace public NftMarket;

  uint256 ownerPriv = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  address public owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  address public nftAddr = 0xEA6BA4682ADa04434baC0A76FbB18f429a332d9A;
  uint256 public tokenId = 9351;
  uint256 public price = 3 ether;
  uint256 public deadline = 1 days;
  bytes public signature;

  function setUp() public {
      NftMarket = new NftMarketplace();
       bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
  
      (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPriv, msgHash.toEthSignedMessageHash());
      signature = getSig(v, r, s);
      console2.logBytes(signature);
  }
   function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }
  
  function testSig() public {
    bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
    bytes32 _signedMsg = msgHash.toEthSignedMessageHash();
    address signer = _signedMsg.recover(signature);
    assertEq(signer, owner);
  }

  function approveAll() public {
    ITestNft nft = ITestNft(nftAddr);
    nft.setApprovalForAll(address(NftMarket), true);
  }

  function testApproval() public {
   vm.expectRevert();
   NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
  }

  function testPrice() public {
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, 0, deadline, signature);
  }

  function testDeadline() public {
     uint256 _deadline = 3 minutes;
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, price, _deadline, signature);
  }

  function testIsListed() public {
    vm.expectRevert();
    NftMarket.getListing(1);
  }

  function testIsOwner() public {
    vm.expectRevert();
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
  }

  function testListItem() public {
    approveAll();
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    Listing memory listedItem = NftMarket.getListing(1);
    assertEq(listedItem.nftAddress, nftAddr);
    assertEq(listedItem.price, price);
    assertEq(listedItem.seller, owner);
    assertEq(listedItem.deadline, block.timestamp + deadline);
    assertEq(listedItem.signature, signature);
  }

  function testBuyItem() public {
    approveAll();
    NftMarket.listItem(nftAddr, tokenId, price, deadline, signature);
    bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
    NftMarket.buyItem(1, msgHash);
    Listing memory listedItem = NftMarket.getListing(1);
    assertEq(listedItem.nftAddress, nftAddr);
    assertEq(listedItem.price, price);
    assertEq(listedItem.seller, owner);
    assertEq(listedItem.deadline, deadline);
    assertEq(listedItem.signature, bytes(""));
  }
      }