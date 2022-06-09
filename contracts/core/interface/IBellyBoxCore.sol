// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBellyBoxCore {

    // The fist type is the user opened at website, final type maye be different from  firstType while firstType = 3.
    event BellyBoxOpened(uint256 firstType, uint256 finalType, address payWay, uint256 price);
    
    /**
     * @dev Open a blind box
     *
     * Emits a {BellyBoxOpened} event.
     *
     * A certain amount of CSW needs to be paid as a fee
     *
     * This blind box has a chance to open three erc1155 tokens
     * 1.ingredient token
     * 2.equipment token
     * 3.CHI token
     */
    function createBellyBox(
        uint256 cswAmount,
        uint8 bellyBoxType
    ) external;

    /**
     * @dev Open a blind box
     * A certain amount of BUSD needs to be paid as a fee
     *
     * Emits a {BellyBoxOpened} event.
     *
     * This blind box has a chance to open three erc1155 tokens
     * 1.ingredient token
     * 2.equipment token
     * 3.CHI token
     */
    function createBellyBoxByBUSD(
        uint256 busdAmount,
        uint8 bellyBoxType
    ) external;

    /**
     * @dev Get details based on blind box type
     */
    function getBellyBox(uint256 bellyBoxType) external view returns (
        uint256 price,
        uint256 busdPrice,
        uint64 supply,
        uint64 opened,
        string memory describe
    );
}