// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface about acclocation of chitoken to tablecloth holders
 */
interface ITableclothAwardsPool {

    event AddAwards(uint128 indexed awardsType, uint128 indexed tableclothType, uint256 chiAmount);
    event Withdraw(uint256 indexed tableclothId, address indexed to, uint256 chiAmount);

    function AWARDS_TYPE_BATTLE() external view returns(uint128);
    function AWARDS_TYPE_MERGE() external view returns(uint128);

    /**
     * @dev Add awards in pool.
     * only permit sandwith or qualifying role
     *
     * Emits a {AddAwards} event.
     *
     */
    function addAwards(
        address sender,
        uint128 awardsType,
        uint128 tableclothType,
        uint256 chiAmount
    ) external;

    /**
     * @dev Add awards in pool.
     * only permit sandwith or qualifying role
     *
     * Emits a {AddAwards} event.
     *
     */
    function addAwards(
        address sender,
        uint128 awardsType,
        uint128[] memory tableclothTypes,
        uint256 chiAmount
    ) external;

    /**
     * @dev Get the token's unaccalimed awards amount in pool.
     * only amount in pool of tokentype can you get
     */
    function getUnaccalimedAmount(uint256 tableclothId) external view returns(uint256);

    function getUnaccalimedAmountByType(uint128 tableclothType, address user) external view returns(uint256 amounts);

    /**
     * @dev Get the pool's historical total awards amount in pool.
     */
    function getPoolTotalAmount(uint128 tableclothType) external view returns(uint256);


    /**
     * @dev Withdraw the token's unaccalimed awards amount in pool.
     * only amount in pool of tokentype can you withdraw
     *
     * Emits a {Withdraw} event.
     *
     */
    function withdraw(uint256 tableclothId, address to) external;

    /**
     * @dev Withdraw the token's unaccalimed awards amount in pool.
     * only amount in pool of tokentype can you withdraw
     * This funtion will withdraw all awards of table cloth you hold which typeid = tableclothType
     *
     * Emits {Withdraw} event repeatedly.
     *
     */
    function withdrawByType(uint128 tableclothType, address to) external;

}