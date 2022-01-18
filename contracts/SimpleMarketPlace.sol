// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**Working nft simple contract for trading */

contract SimpleMarketPlace {
    
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _itemsSold;

    address public sellerA;

    mapping(address => mapping(uint256 => Listing)) public listings;

    mapping(uint256 => Listing) idToListing;

    struct Listing {
        address seller;
        uint256 price;
    }

    function addListing(address contractAddress, uint256 price, uint256 tokenId) public {
        ERC1155 token = ERC1155(contractAddress);
        require(token.balanceOf(msg.sender, tokenId) > 0, "caller must own given token");
        require(token.isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");
        listings[contractAddress][tokenId] = Listing(msg.sender, price);
    }

    function purchase(address contractAddress, uint256 tokenId, uint256 amount) public payable {
        require(msg.value >= listings[contractAddress][tokenId].price * amount, "Insufficient funds!");
        _itemsSold.increment();
        ERC1155 token = ERC1155(contractAddress);
        token.safeTransferFrom(listings[contractAddress][tokenId].seller, msg.sender, tokenId, amount, "");
        payable(listings[contractAddress][tokenId].seller).transfer(msg.value);
    }

}
