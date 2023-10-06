// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Sign} from "./libraries/signature.sol";

struct Listing {
    address nftAddress;
    uint256 tokenId;
    uint256 price;
    address seller;
    uint256 deadline;
    bool status;
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
    error InvalidSignature();



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


    function listItem(
  Listing calldata order
    ) external returns(uint256 id) {
        if(msg.sender != IERC721(order.nftAddress).ownerOf(order.tokenId) ){
            revert NotOwner();
        }
       if(!IERC721(order.nftAddress).isApprovedForAll(msg.sender, address(this))){
           revert NotApprovedForMarketplace();}
       if (order.deadline - block.timestamp <   1 hours) {
            revert MinDurationNotMet();
        }
        if (order.price <= 0 ether) {
            revert PriceMustBeAboveZero();
        }

        bytes32 messageHash =   Sign.constructMessageHash(
                    order.nftAddress,
                    order.tokenId,
                    order.price,
                    order.deadline,
                    msg.sender
                );
             if (
            !Sign.isValid(
                messageHash,
                order.signature,
                msg.sender
            )
        ) revert InvalidSignature();

        uint256 orderId = listCount;

        Listing storage lists = idToListing[orderId];
        lists.nftAddress = order.nftAddress;
        lists.tokenId = order.tokenId;
        lists.price = order.price;
        lists.seller = msg.sender;
        lists.deadline = order.deadline;
        lists.signature = order.signature;
        lists.status = true;
        isActiveListing[orderId] = true;
        id = listCount;
        listCount++;
        id;
    }

    function buyItem(
        uint256 orderId
    )
        external
        payable
        isListed(orderId)
        isExpired(idToListing[orderId].deadline)
    {
        Listing memory listedItem = idToListing[orderId];
        if(isActiveListing[orderId] == false){
            revert NotListed(orderId);
        }
        if (msg.value != listedItem.price) {
            revert PriceNotMet(listedItem.price);
        }
        isActiveListing[orderId] = false;

        payable(listedItem.seller).transfer(listedItem.price);
        IERC721(idToListing[orderId].nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            listedItem.tokenId
        );
    }

    function updateListing(uint orderId, uint _price, bool status) external {
        if(orderId > listCount){
            revert NotListed(orderId);
        }
        if(isActiveListing[orderId] == false){
            revert NotListed(orderId);
        }
        if (idToListing[orderId].seller != msg.sender) {
            revert NotOwner();
        }
             Listing storage lists = idToListing[orderId];
        lists.price = _price;
        lists.status = status;
        isActiveListing[orderId] = status;
        
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
