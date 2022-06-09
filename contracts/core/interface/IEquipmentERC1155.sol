// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEquipmentERC1155 {

    event EquipmentCreated(uint8 childType, uint256 indexed id, address indexed owner);

    /**
     * @dev Create a random equipment.
     *
     * Emits a {EquipmentCreated} event.
     *
     * Requirements:
     *
     * Only can be called from bellybox contract.
     *
     */
    function createEquipment(address recipient, string memory _name, string memory _describe, uint256 seed) external;

    /**
     * @dev return the details of equipment.
     */
    function getEquipment(uint256 _id) external view returns (
        uint32[3] memory adh,
        string memory equipmentName,
        string memory equipmentDescribe,
        uint8 childType
    );

    /**
     * @dev approve self token to sandwich token.
     */
    function permitSandwichForAll(address owner) external;
}