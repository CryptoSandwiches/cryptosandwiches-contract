// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev 
 */
interface ISandwichesERC1155 {

    event SandwichesCreated(uint256 indexed id, address indexed owner);

    /**
     * @dev Create new sandwich heroes by ingredients, tablecloths, and equipments.
     *
     * The length of ingredient Tokens required for merging must be 4,
     * The length of equipment Tokens required for merging must be greater than 3 and less than 4.
     *
     * CHI coins must be paid as a handling fee when merging, 
     * and CHI coins will be equally distributed to the holders of the tablecloth shares.
     */
    function merge(
        uint256 chiAmount,
        uint256[] calldata ingredients,
        uint256[] calldata equipments, 
        uint128 tableclothType,
        string calldata _name,
        string calldata _describe
    ) external;


    /**
     *  @dev Get sandwich details by token id.
     */
    function getSandwich(uint256 _id) external view returns (
        string memory _name,
        string memory describe,
        uint256 aggressivity,
        uint256 defensive,
        uint256 healthPoint,
        uint256 calories,
        uint256 scent,
        uint256 freshness,
        bool[5] memory attributes,
        uint16 attrnum
    );

    /**
     *  @dev Get sandwich parts by token id.
     */
    function getSandwichParts(uint256 _id) external view returns (
        uint256[] memory ingredients,
        uint256[] memory equipments
    );

    /**
     *  @dev Burn your sandwich and the parts will send to receiver.
     *
     *  Requirements: receiver not address(0) and msg.sender have this token
     */
    function burn(uint256 id, address receiver) external;

    /**
     *  @dev Burn your sandwich and the parts will send to you.
     *
     *  Requirements: msg.sender have this token
     */
    function burn(uint256 id) external;

}