// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC1155, Ownable {

    struct Input {
        uint256 id;
        uint256 amount;
        address to;
    }

    constructor(Input[] memory inputArray) ERC1155("") {
        for (uint i=0; i<inputArray.length; i++) {
            _mint(inputArray[i].to, inputArray[i].id, inputArray[i].amount, "");
        }
    }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == account, "Only NFT onwers can burn!");
        require(balanceOf(msg.sender, id) >= amount, "Not enough tokens!");
        _burn(account, id, amount);
    }

}