// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./random/Random.sol";
import "./interface/IIngredientERC1155.sol";
import "../lib/ArrayUtil.sol";

contract IngredientERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, IIngredientERC1155, ERC2981Upgradeable {
    
    // Only blind box permissions can create tokens
    bytes32 public constant BELLYBOX_ROLE = keccak256("BELLYBOX_ROLE");

    // Only Sandwich permission can use this Token
    bytes32 public constant SANDWICHES_ROLE = keccak256("SANDWICHES_ROLE");

    address private bellyBoxAddress;

    uint256 private totalIngredient;

    struct Ingredient {
        string ingredientName;
        string ingredientDescribe;
        uint8 childType; // 1 meat, 2 veg, 3 fruit, 4 sauce
        uint32 calories;
        uint32 scent;
        uint32 freshness;
    }

    mapping(uint256 => Ingredient) internal ingredients;
    // This array and mapping is for recording the number of childen type's sales and which type can getting.
    uint256[] private typeArray;
    // Each type can sale 6000 copies
    mapping(uint256 => uint256) private typeSales;
    
    /**
     * @dev Initialization constructor related parameters
     */
    function initialize() initializer public {
        __ERC1155_init("https://cryptosandwiches.com/api/metadata/ingredients/");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        totalIngredient = 0;
        // 1 meat, 2 veg, 3 fruit, 4 sauce
        typeArray = [1, 2, 3, 4];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(IIngredientERC1155).interfaceId ||
        ERC1155Upgradeable.supportsInterface(interfaceId) ||
        AccessControlUpgradeable.supportsInterface(interfaceId) ||
        ERC2981Upgradeable.supportsInterface(interfaceId);
    }


    /**
     *  @dev Create an ingredient ERC1155 token through a blind box
     *  generate ingredient related property values
     *
     *  Emits a {ingredientCreated} event.
     */
    function createIngredient(
        address recipient,
        string calldata _name,
        string calldata _describe,
        uint256 seed
    ) onlyRole(BELLYBOX_ROLE)  external override {
        uint length = typeArray.length;
        require(length > 0, "Ingredient: All ingredient box sales out");
        nextIngredientId();
        uint256 seed2 = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), totalIngredient)));
        uint256 typeIndex = Random.createRandom(1, length, seed, seed2) - 1;
        uint8 childType =  uint8(typeArray[typeIndex]);
        if(++ typeSales[childType] >= 6000){
            // remove the type from typeArray
            typeArray = ArrayUtil.removeAt(typeArray, typeIndex);
        }
        unchecked {
            uint32 calories = Random.createRandom(1, 50, seed, ++ seed2);
            uint32 scent = Random.createRandom(1, 50, seed, ++ seed2);
            uint32 freshness = Random.createRandom(1, 50, seed, ++ seed2);
            
            Ingredient memory ingredient = Ingredient({
                ingredientName: _name,
                ingredientDescribe: _describe,
                childType: childType,
                calories: calories,
                scent: scent,
                freshness:freshness
            });

            ingredients[totalIngredient] = ingredient;
        }
        _setTokenRoyalty(totalIngredient, recipient, 100);
        _mint(recipient, totalIngredient, 1, "");
        emit IngredientCreated(childType, totalIngredient, recipient);
    }
    
    /**
     *  @dev Get ingredient details by token id
     */
    function getIngredient(uint256 _id) public view override returns (
        uint32[3] memory attr,
        string memory ingredientName,
        string memory ingredientDescribe,
        uint8 childType
    ) {
        Ingredient storage ingredient = ingredients[_id];
        attr[0] = ingredient.calories;
        attr[1] = ingredient.scent;
        attr[2] = ingredient.freshness;
        ingredientName = ingredient.ingredientName;
        ingredientDescribe = ingredient.ingredientDescribe;
        childType = ingredient.childType;
    }

    function getTypes() external view returns(uint256[] memory){
        return typeArray;
    }

    function getTypeSales(uint256 typeId) external view returns(uint256){
        return typeSales[typeId];
    }
    
    function name() external pure returns (string memory) {
        return "Cryptosandwiches Ingredient"; 
    }
    
    function symbol() external pure returns (string memory) {
        return "Ingredient";
    }

    function nextIngredientId() private {
         totalIngredient ++;
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

