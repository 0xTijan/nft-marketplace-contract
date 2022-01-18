// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*Working tradable ERC1155 */

contract NFT is ERC1155, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;
    Counters.Counter private _itemsSold;
    uint256 private _volume;

    struct Input {
        uint256 id;
        uint256 amount;
        address to;
    }

    struct Offer {
        uint offerId;
        address payable seller;
        address payable owner;
        uint256 tokenId;
        uint amount;
        uint256 price;
        uint256 tokensSold;
    }

    mapping(uint256 => Offer) private idToOffer;
    mapping (address => mapping (uint => uint)) disabledTokens;

    constructor(Input[] memory inputArray) ERC1155("") {
        for (uint i=0; i<inputArray.length; i++) {
            _mint(inputArray[i].to, inputArray[i].id, inputArray[i].amount, "");
        }
    }

    function createOffer(address _seller, uint _id, uint _amount, uint _price) public {
        require(_seller == msg.sender, "Not your tokens!");
        require(balanceOf(msg.sender, _id) >= _amount, "Caller must hold given tokens!");
        require(isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");

        _offerIds.increment();
        uint256 offerId = _offerIds.current();

        idToOffer[offerId] = Offer(
            offerId,
            payable(_seller),
            payable(_seller),
            _id,
            _amount,
            _price,
            0
        );

        //Disables Tokens:
        disabledTokens[_seller][_id] = _amount;
    }

    function executeOffer(uint _offerId, uint256 _amountToBuy) public payable {
        require(msg.value >= idToOffer[_offerId].price * _amountToBuy, "Not enough funds!");
        require(idToOffer[_offerId].amount >= _amountToBuy, "All tokens sold!");
        require(idToOffer[_offerId].tokensSold != idToOffer[_offerId].amount, "Offer is not active!");

        //Updates Offer
        idToOffer[_offerId].tokensSold = idToOffer[_offerId].tokensSold + _amountToBuy;

        _itemsSold.increment();
        _volume = _volume + idToOffer[_offerId].price;

        //enables back unsabled tokens
        disabledTokens[idToOffer[_offerId].seller][idToOffer[_offerId].tokenId] = 0;

        //Transfer ETH:
        idToOffer[_offerId].seller.call{ value: idToOffer[_offerId].price * _amountToBuy };
        safeTransferFrom(idToOffer[_offerId].seller, msg.sender, idToOffer[_offerId].tokenId, _amountToBuy, "");
    }

    /*function getAllOffers() public view returns(Offer[] memory){
        Offer[] memory offers;

        for(uint i; i<_offerIds.current(); i++) {
            offers.push(idToOffer[i]);
        }

        return offers;
    }*/

    function viewVolume() public view returns(uint256) {
        return _volume;
    }

    function viewItemsSold() public view returns(uint256) {
        return _itemsSold.current();
    }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == account, "Only NFT onwers can burn!");
        require(balanceOf(account, id) >= amount, "You don't have engough NFTs");
        _burn(account, id, amount);
    }

    function viewDisabledTokens(address _address, uint256 _tokenId) public view returns(uint256){
        return disabledTokens[_address][_tokenId];
    }

   /*function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); // Call parent hook
        //Checks if tokens are disabled
        if(Ids.lenght == 1) {

        }
    }*/

}