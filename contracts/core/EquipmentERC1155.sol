  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./random/Random.sol";
import "./interface/IEquipmentERC1155.sol";
import "../lib/ArrayUtil.sol";


contract EquipmentERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, IEquipmentERC1155, ERC2981Upgradeable {
    
    // Only blind box permissions can create tokens
    bytes32 public constant BELLYBOX_ROLE = keccak256("BELLYBOX_ROLE");

    // Only Sandwich permission can use this Token
    bytes32 public constant SANDWICHES_ROLE = keccak256("SANDWICHES_ROLE");

    uint256 private totalEquipment;

    struct Equipment {
        string equipmentName;
        string equipmentDescribe;
        uint8 childType;  // 11 hat, 12 hand, 13 foot
        uint32 aggressivity;
        uint32 defensive;
        uint32 healthPoint;
    }
    
    mapping(uint256 => Equipment) internal equipments;
    // This array and mapping is for recording the number of childen type's sales and which type can getting.
    uint256[] private typeArray;
    // Each type can sale 6000 copies
    mapping(uint256 => uint256) private typeSales;

    /**
     * @dev Initialization constructor related parameters
     */
    function initialize() initializer public {
        __ERC1155_init("https://cryptosandwiches.com/api/metadata/equipments/");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // 11 hat, 12 hand, 13 foot
        typeArray = [11, 12, 13];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(IEquipmentERC1155).interfaceId || 
        ERC1155Upgradeable.supportsInterface(interfaceId) ||
        AccessControlUpgradeable.supportsInterface(interfaceId) ||
        ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /**
     *  @dev Create a equipment ERC1155 token through a blind box
     *  generate equipment related property values
     *
     *  Emits a {equipmentCreated} event.
     */
    function createEquipment(
        address recipient,
        string memory _name,
        string memory _describe,
        uint256 seed
    ) onlyRole(BELLYBOX_ROLE) external override{
        uint length = typeArray.length;
        require(length > 0, "Ingredient: All ingredient box sales out");
        nextEquipmentId();

        uint256 seed2 = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), totalEquipment)));
        uint256 typeIndex = Random.createRandom(1, length, seed, seed2) - 1;
        uint8 childType =  uint8(typeArray[typeIndex]);
        if(++ typeSales[childType] >= 6000){
            // remove the type from typeArray
            typeArray = ArrayUtil.removeAt(typeArray, typeIndex);
        }
        unchecked {
            uint8 aggressivity = Random.createRandom(1, 50, seed,  ++ seed2);
            uint8 defensive = Random.createRandom(1, 50, seed,  ++ seed2);
            uint8 healthPoint = Random.createRandom(1, 50, seed,  ++ seed2);
            Equipment memory equipment = Equipment({
                equipmentName: _name,
                equipmentDescribe: _describe,
                childType: childType, // 11 hat, 12 hand, 13 foot
                aggressivity: uint32(aggressivity),
                defensive: uint32(defensive),
                healthPoint: uint32(healthPoint)
            });

            equipments[totalEquipment] = equipment;
        }
        _setTokenRoyalty(totalEquipment, recipient, 100);
        _mint(recipient, totalEquipment, 1, "");
        emit EquipmentCreated(childType, totalEquipment, recipient);
    }

    /**
     *  @dev Get equipment details by token id
     */
    function getEquipment(uint256 _id) public view override returns (
        uint32[3] memory adh,
        string memory equipmentName,
        string memory equipmentDescribe,
        uint8 childType
    ) {
        Equipment storage equipment = equipments[_id];
        adh[0] = equipment.aggressivity;
        adh[1] = equipment.defensive;
        adh[2] = equipment.healthPoint;
        equipmentName = equipment.equipmentName;
        equipmentDescribe = equipment.equipmentDescribe;
        childType = equipment.childType;
    }

    function name() external pure returns (string memory) {
        return "Cryptosandwiches Equipment"; 
    }

    function symbol() external pure returns (string memory) {
        return "Equipment";
    }

    function nextEquipmentId() private {
        totalEquipment ++;
    }

    function getTotalEquipment() external view returns (uint256) {
        return totalEquipment;
    }

    function getTypes() external view returns(uint256[] memory){
        return typeArray;
    }

    function getTypeSales(uint256 typeId) external view returns(uint256){
        return typeSales[typeId];
    }

    function setBaseUrl(string memory url) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setURI(url);
    }

    /**
     * @dev returns the metadata uri for a given id
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), StringsUpgradeable.toString(_id)));
    }

    /**
     * @dev approve self token to sandwich token
     */
    function permitSandwichForAll(address owner) external override onlyRole(SANDWICHES_ROLE){
        _setApprovalForAll(owner, _msgSender(), true);
    }   
}

