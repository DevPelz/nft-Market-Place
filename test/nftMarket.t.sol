// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {NftMarketplace} from "../src/NftMarket.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

interface ITestNft {
   function safeMint(address to, uint256 tokenId) external;
}

contract NftMarketplaceTest is Test{
  using ECDSA for bytes32;
  NftMarketplace public NftMarket;

  uint256 ownerPriv = 123444;
  address public owner = vm.addr(ownerPriv);
  address public nftAddr = 0xEA6BA4682ADa04434baC0A76FbB18f429a332d9A;
  uint256 public tokenId = 9351;
  uint256 public price = 3 ether;
  uint256 public deadline = 1 days;
  bytes public signature;

  function setUp() public {
      vm.startPrank(owner);
      NftMarket = new NftMarketplace();
      ITestNft(nftAddr).safeMint(owner, tokenId);
       bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
  
      (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPriv, msgHash.toEthSignedMessageHash());
      signature = getSig(v, r, s);
      console2.logBytes(signature);
      vm.stopPrank();
  }
   function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }
  
  function testSig() public {
    vm.prank(owner);
    bytes32 msgHash = NftMarket.createMessageHash(nftAddr, tokenId, price, deadline);
    bytes32 _signedMsg = msgHash.toEthSignedMessageHash();
    address signer = _signedMsg.recover(signature);
    assertEq(signer, owner);

  }

  

}
