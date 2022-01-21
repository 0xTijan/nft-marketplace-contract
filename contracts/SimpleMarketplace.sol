// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/*
 * Smart contract allowing users to trade (list and buy) NTFs from any ERC1155 smart contract.
 */

contract SimpleMarketplace is Ownable, ReentrancyGuard{
    
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _tokensSold;
    uint256 private _volume;

    event TokenListed(address contractAddress, address seller, uint256 tokenId, uint256 amount, uint256 pricePerToken);
    event TokenSold(address contractAddress, address seller, address buyer, uint256 tokenId, uint256 amount, uint256 pricePerToken);

    mapping(uint256 => Listing) private idToListing;

    struct Listing {
        address contractAddress;
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 tokensAvailable;
        bool completed;
    }

    struct Stats {
        uint256 volume;
        uint256 itemsSold;
    }

    function listToken(address contractAddress, uint256 tokenId, uint256 amount, uint256 price) public nonReentrant returns(uint256) {
        ERC1155 token = ERC1155(contractAddress);

        require(token.balanceOf(msg.sender, tokenId) > amount, "Caller must own given token!");
        require(token.isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();
        idToListing[listingId] = Listing(contractAddress, msg.sender, tokenId, amount, price, amount, false);

        emit TokenListed(contractAddress, msg.sender, tokenId, amount, price);

        return _listingIds.current();
    }

    function purchaseToken(uint256 listingId, uint256 amount) public payable nonReentrant {
        ERC1155 token = ERC1155(idToListing[listingId].contractAddress);

        require(msg.sender != idToListing[listingId].seller, "Can't buy your onw tokens!");
        require(msg.value >= idToListing[listingId].price * amount, "Insufficient funds!");
        require(token.balanceOf(idToListing[listingId].seller, idToListing[listingId].tokenId) >= amount, "Seller doesn't have enough tokens!");
        require(idToListing[listingId].completed == false, "Listing not available anymore!");
        require(idToListing[listingId].tokensAvailable >= amount, "Not enough tokens left!");
        
        _tokensSold.increment();
        _volume += idToListing[listingId].price * amount;

        idToListing[listingId].tokensAvailable -= amount;
        if(idToListing[listingId].tokensAvailable == 0) {
            idToListing[listingId].completed = true;
        }

        emit TokenSold(
            idToListing[listingId].contractAddress,
            idToListing[listingId].seller,
            msg.sender,
            idToListing[listingId].tokenId,
            amount,
            idToListing[listingId].price
        );

        token.safeTransferFrom(idToListing[listingId].seller, msg.sender, idToListing[listingId].tokenId, amount, "");
        payable(idToListing[listingId].seller).transfer((idToListing[listingId].price * amount/50)*49); //Transfering 98% to seller, fee 2%  ((msg.value/50)*49)
    }

    function  viewAllListings() public view returns (Listing[] memory) {
        uint itemCount = _listingIds.current();
        uint unsoldItemCount = _listingIds.current() - _tokensSold.current();
        uint currentIndex = 0;

        Listing[] memory items = new Listing[](unsoldItemCount);

        for (uint i = 0; i < itemCount; i++) {
                uint currentId = i + 1;
                Listing storage currentItem = idToListing[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
        }

        return items;
    }

    function viewListingById(uint256 _id) public view returns(Listing memory) {
        return idToListing[_id];
    }

    function viewStats() public view returns(Stats memory) {
        return Stats(_volume, _tokensSold.current());
    }

    function withdrawFees() public onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

}