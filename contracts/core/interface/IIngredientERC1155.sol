// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIngredientERC1155 {
    
    event IngredientCreated(uint8 childType, uint256 indexed id, address indexed owner);

    /**
     * @dev Create a random ingredient.
     *
     * Emits a {IngredientCreated} event.
     *
     * Requirements:
     *
     * Only can be called from bellybox contract.
     *
     */
    function createIngredient(address recipient, string calldata _name, string calldata _describe, uint256 seed) external;

    /**
     * @dev return the details of ingredient.
     */
    function getIngredient(uint256 _id) external view returns (
        uint32[3] memory attr,
        string memory ingredientName,
        string memory ingredientDescribe,
        uint8 childType
    );


    /**
     * @dev approve self token to sandwich token
     */
    function permitSandwichForAll(address owner) external;
    
}
