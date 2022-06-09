// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITableclothERC1155 {

    event TableclothPurchase(uint256 indexed id, address indexed owner);
    event ConfigTableclothType(uint256 indexed id, uint256 price, uint256 maximum);

    /**
     *  @dev Buy a tablecloth
     *
     *  Emits a {tableclothPurchase} event.
     */
    function buyTablecloth(
        uint256 cswAmount,
        uint128 typeId
    )  external;

    /**
     * @dev Return details of Tablecloth 
     *
     * Requirements:
     * - tokenId
     */
    function getTablecloth(uint256 _id) external view returns (
        uint256 maximum,
        uint256 soldQuantity,
        uint256 price,
        bool[5] memory _attr,
        uint128 typeId,
        string memory tableclothName,
        string memory tableclothDescribe
    );

    /**
     *  @dev Config attributes of tablecloth types.
     *
     *  Emits a {ConfigTableclothType} event.
     */
    function configTableclothType(
        uint128 id,
        string memory _name,
        string memory _describe,
        uint256 tableclothPrice,
        bool[5] memory _attr,
        uint256 _maximum
    ) external;

    /**
     * @dev Return tablecloth type of token 
     *
     * Requirements:
     * - tokenId
     */
    function getTableclothType(uint256 _id) external view returns(uint128);


    /**
     *  @dev Get tablecloth type details by type id
     */
    function getTypeDetails(uint128 typeId) external view returns (
        string memory tableclothName,
        string memory tableclothDescribe,
        uint256 tableclothPrice,
        uint256 maximum,
        uint256 soldQuantity,
        bool[5] memory attr,
        uint16 attrnum,
        uint256 totalAwards
    );

    /**
     * @dev Get the enemy of attributes
     *
     * Requirements:
     * - attr >= 1 and <= 5
     */
    function getAttributesEnemy(uint16 attr) external view returns(uint16);

    /**
     * @dev Get the token id list of holder
     *
     */
    function getHoldArray(uint128 typeId, address holder) external view returns(uint256[] memory);
}
