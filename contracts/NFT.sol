// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract NFT is ERC1155Burnable {

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

}