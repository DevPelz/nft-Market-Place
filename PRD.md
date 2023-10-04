# NFT Marketplace Product Requirements Document (PRD)

## Features

### 1. Listing NFTs

- Users can list their NFTs for sale.
- The contract ensures that only the owner of the NFT can list it.
- A valid listing includes the NFT's address, tokenId, price, deadline, and a VRS signature.

### 2. Buying NFTs

- Users can buy NFTs listed on the marketplace.
- To purchase, the buyer must provide the orderId and a signed message hash.
- The contract verifies the signature before completing the purchase.
- The NFT is transferred to the buyer, and funds go to the seller upon successful purchase.

### 3. Validation and Security

- The contract performs multiple validations, including ownership, approval, price checks, and expiration checks.
- Signature verification is used for secure order creation and confirmation.
- Reverts in case of errors to ensure the security of transactions.

### 4. Listing Management

- Each listing has a unique orderId.
- Listings expire after a specified deadline.
- Listings can be deactivated if the NFT is no longer for sale.

### 5. Error Handling

- Custom error messages are used to provide clear feedback to users in case of issues.
- Errors include PriceNotMet, NotListed, Expired, NotApprovedForMarketplace, PriceMustBeAboveZero, and NotOwner.

---
 