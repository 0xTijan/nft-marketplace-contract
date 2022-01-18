// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyMarketPlace {

    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;
    Counters.Counter private _itemsSold;

    struct Offer{
        address contractAddress;
        address seller;
        uint tokenId;
        uint amount;
        uint price;
        bool completed;
    }

    mapping(uint256 => Offer) allOffers;

    function createOffer(address contractAddress, uint256 tokenId, uint256 amount, uint256 price) public {
        ERC1155 token = ERC1155(contractAddress);
        require(token.balanceOf(msg.sender, tokenId) > 0, "caller must own given token");
        require(token.isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");    

        _offerIds.increment();
        uint256 itemId = _offerIds.current();

        allOffers[itemId] = Offer(
            contractAddress,
            msg.sender,
            tokenId,
            amount,
            price,
            false
        );
    }

    function purchase(uint256 _offerId, uint256 _amount) public payable {
        ERC1155 token = ERC1155(allOffers[_offerId].contractAddress);
        require(msg.value >= allOffers[_offerId].price * _amount, "Insufficient funds sent!");
        require(allOffers[_offerId].completed == false, "Offer not available anymore!");
        require(allOffers[_offerId].seller != msg.sender, "Your Item!");

        allOffers[_offerId].completed = true;

        token.safeTransferFrom(allOffers[_offerId].seller, msg.sender, allOffers[_offerId].tokenId, allOffers[_offerId].amount, "");
    }

    function getOfferById(uint256 _id) public view returns(Offer memory) {
        return allOffers[_id];
    }

    function getCurrentOfferId() public view returns(uint256) {
        return _offerIds.current();
    }

}