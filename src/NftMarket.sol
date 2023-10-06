// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

struct Listing {
    address nftAddress;
    uint256 price;
    address seller;
    uint256 deadline;
    bytes signature;
}
contract NftMarketplace {
    using ECDSA for bytes32;
    uint256 public listCount;

    error PriceNotMet(uint256 price);
    error NotListed(uint256 listId);
    error Expired(uint256 deadline);
    error NotApprovedForMarketplace();
    error PriceMustBeAboveZero();
    error NotOwner();
    error MinDurationNotMet();



    mapping(uint256 => Listing) public idToListing;
    mapping(uint256 => bool) public isActiveListing;

    modifier isListed(uint256 listId) {
        if (isActiveListing[listId] == false) {
            revert NotListed(listId);
        }
        _;
    }

    modifier isExpired(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired(deadline);
        }
        _;
    }


    function createMessageHash(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 deadline
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(nftAddress, tokenId, price, deadline));
    }

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external  {
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender){
            revert NotOwner();
        }
       if (block.timestamp + deadline < block.timestamp + 1 hours) {
            revert MinDurationNotMet();
        }
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
       if(!IERC721(nftAddress).isApprovedForAll(msg.sender, address(this))){
           revert NotApprovedForMarketplace();}

        listCount++;
        uint256 orderId = listCount;
        idToListing[orderId] = Listing(
            nftAddress,
            price,
            msg.sender,
            deadline,
            signature
        );
        isActiveListing[orderId] = true;
    }

    function buyItem(
        uint256 orderId,
        bytes32 messageHash
    )
        external
        payable
        isListed(orderId)
        isExpired(idToListing[orderId].deadline)
    {
        Listing memory listedItem = idToListing[orderId];
        bytes32 _signedMsg = messageHash.toEthSignedMessageHash();
        address signer = _signedMsg.recover(listedItem.signature);
        require(signer == listedItem.seller, "Invalid signature");

        if (msg.value != listedItem.price) {
            revert PriceNotMet(listedItem.price);
        }
        isActiveListing[orderId] = false;

        payable(listedItem.seller).transfer(msg.value);
        IERC721(idToListing[orderId].nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            orderId
        );
    }

    function getListing(uint256 orderId)
        external
        view
        returns (Listing memory
        )
    {
        return idToListing[orderId];
    }
}
