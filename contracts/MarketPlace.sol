// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
*/

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        uint amount;
        bool sold;
    }
    
    mapping(uint256 => MarketItem) private idToMarketItem;
    
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        uint amount,
        bool sold
    );
     
    event MarketItemSold (
        uint indexed itemId,
        address owner,
        uint amount
    );
     
    
    
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    ) public payable nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(amount > 0, "Amount must be greater than 0");
        
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            amount,
            false
        );
        
        ERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
            
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            amount,
            false
        );
    }
        
    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        bool sold = idToMarketItem[itemId].sold;
        uint amount = idToMarketItem[itemId].amount;
        
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        require(sold != true, "This Sale has alredy finnished");
        
        emit MarketItemSold(
            itemId,
            msg.sender,
            amount
        );

        idToMarketItem[itemId].seller.transfer(msg.value);
        ERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        idToMarketItem[itemId].owner = payable(msg.sender);
        _itemsSold.increment();
        idToMarketItem[itemId].sold = true;
    }
        
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
      
}
