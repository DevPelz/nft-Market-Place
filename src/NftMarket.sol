// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Sign} from "./libraries/signature.sol";

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
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external  {
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender){
            revert NotOwner();
        }
       if(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == false){
           revert NotApprovedForMarketplace();}
       if (deadline - block.timestamp <   1 hours) {
            revert MinDurationNotMet();
        }
        if (price < 0.01 ether) {
            revert PriceMustBeAboveZero();
        }

        bytes32 messageHash =   Sign.constructMessageHash(
                    nftAddress,
                    tokenId,
                    price,
                    deadline,
                    msg.sender
                );
             if (
            !Sign.isValid(
                messageHash,
                signature,
                msg.sender
            )
        ) revert InvalidSignature();

        uint256 orderId = listCount;

        Listing memory lists = idToListing[orderId];
        lists.nftAddress = nftAddress;
        lists.price = price;
        lists.seller = msg.sender;
        lists.deadline = deadline;
        lists.signature = signature;

        listCount++;
        isActiveListing[orderId] = true;
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
            orderId
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

        idToListing[orderId].price = _price;
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
