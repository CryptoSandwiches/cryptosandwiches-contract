// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interface/IIngredientERC1155.sol";
import "./interface/IEquipmentERC1155.sol";
import "./interface/ITableclothERC1155.sol";
import "./interface/ITableclothAwardsPool.sol";
import "./interface/ISandwichesERC1155.sol";


contract SandwichesERC1155 is ERC1155Upgradeable, ISandwichesERC1155, AccessControlUpgradeable, IERC1155ReceiverUpgradeable, ERC2981Upgradeable {

    IERC20Upgradeable public chiCoin;
    
    IIngredientERC1155 public ingredientERC1155;
    IEquipmentERC1155 public equipmentERC1155;
    ITableclothERC1155 public tableclothERC1155;
    ITableclothAwardsPool public tableclothAwardsPool;

    uint256 private mergePrice;
    uint256 private totalSandwiches;

    // Mapping from token ID to owner address
    mapping (uint256 => address) public _owners;
    mapping(uint256 => Sandwich) internal sandwiches;

    struct Sandwich {
        string name;
        string describe;
        uint32 aggressivity;
        uint32 defensive;
        uint32 healthPoint;
        uint32 calories;
        uint32 scent;
        uint32 freshness;
        uint16 attrnum;
    }

    struct Part {
        uint256[] ingredients;
        uint256[] equipments;
    }

    mapping(uint256 => Part) internal sandwicheParts;

    /**
     * @dev Initialization constructor related parameters
     */
    function initialize(address _ingredientERC1155Address, address _equipmentERC1155Address, address _tableclothERC1155Address, address chiAddress) initializer public {
        __ERC1155_init("https://cryptosandwiches.com/api/metadata/sandwiches/");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        chiCoin = IERC20Upgradeable(chiAddress);
        ingredientERC1155 = IIngredientERC1155(_ingredientERC1155Address);
        equipmentERC1155 = IEquipmentERC1155(_equipmentERC1155Address);
        tableclothERC1155 = ITableclothERC1155(_tableclothERC1155Address);
        mergePrice = 210000 ether; // 210000 CHI
    }

    function setTableclothAwardsPool(address _address) onlyRole(DEFAULT_ADMIN_ROLE) external{
        tableclothAwardsPool = ITableclothAwardsPool(_address);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(ISandwichesERC1155).interfaceId || 
        interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || 
        ERC1155Upgradeable.supportsInterface(interfaceId) ||
        AccessControlUpgradeable.supportsInterface(interfaceId) ||
        ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function name() external pure returns (string memory) {
        return "Cryptosandwiches Hero"; 
    }
    
    function symbol() external pure returns (string memory) {
        return "Hero";
    }

    /**
     * @dev Create new sandwich heroes by ingredients, tablecloths, and equipments.
     *
     * Requirements:
     * - Approve  
     * - The length of ingredient Tokens required for merging must be 4,
     * - The length of equipment Tokens required for merging must be 3.
     *
     * - CHI coins must be paid as a handling fee when merging, 
     * - and CHI coins will be equally distributed to the holders of the tablecloth shares.
     * 
     */
    function merge(
        uint256 chiAmount,
        uint256[] calldata ingredients,
        uint256[] calldata equipments, 
        uint128 tableclothType,
        string calldata _name,
        string calldata _describe
    ) public override{
        require(mergePrice == chiAmount, "CHI value sent is not correct");
        require(tableclothType != 0, "Invalid tablecloth type");
        totalSandwiches ++;
        ingredientERC1155.permitSandwichForAll(_msgSender());
        equipmentERC1155.permitSandwichForAll(_msgSender());

        // Transfer parts
        _transferParts(_msgSender(), address(this), ingredients, equipments);
        
        //@ msgsender need approve(address(tableclothAwardsPool), chiAmount);
        tableclothAwardsPool.addAwards(_msgSender(), tableclothAwardsPool.AWARDS_TYPE_MERGE(), tableclothType, chiAmount);
        Sandwich storage _sandwich = sandwiches[totalSandwiches];
        //@dev Calculate the attribute value when the sandwich is generated.
        {
            (uint32 _calories, uint32 _scent, uint32 _freshness) = getIngredientsAttr(ingredients);
            _sandwich.calories = _calories;
            _sandwich.scent = _scent;
            _sandwich.freshness = _freshness;
        }
        {
            (uint32 _aggressivity, uint32 _defensive, uint32 _healthPoint) = getEquipmentsAttr(equipments);
            _sandwich.aggressivity = _aggressivity;
            _sandwich.defensive = _defensive;
            _sandwich.healthPoint = _healthPoint;
            (, , , , , , uint16 _attrnum,) = tableclothERC1155.getTypeDetails(tableclothType);
            _sandwich.attrnum = _attrnum;
        }
        _sandwich.name = _name;
        _sandwich.describe = _describe;

        sandwicheParts[totalSandwiches].equipments = equipments;
        sandwicheParts[totalSandwiches].ingredients = ingredients;
        _setTokenRoyalty(totalSandwiches, _msgSender(), 100);
        _mint(_msgSender(), totalSandwiches, 1, "");     
        emit SandwichesCreated(totalSandwiches, _msgSender());
    }

    /**
     *  @dev Get sandwich parts by token id.
     */
    function getSandwichParts(uint256 _id) external view override returns (
        uint256[] memory ingredients,
        uint256[] memory equipments
    ){
        ingredients = sandwicheParts[_id].ingredients;
        equipments = sandwicheParts[_id].equipments;
    }

    /**
     *  @dev Get sandwich details by token id.
     */
    function getSandwich(uint256 _id) public view override returns (
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
    ) {
        Sandwich storage sandwich = sandwiches[_id];
        calories = sandwich.calories;
        scent = sandwich.scent;
        freshness = sandwich.freshness;
        aggressivity = sandwich.aggressivity;
        defensive = sandwich.defensive;
        healthPoint = sandwich.healthPoint;
        _name = sandwich.name;
        describe = sandwich.describe;
        attributes[sandwich.attrnum - 1] = true;
        attrnum = sandwich.attrnum;
    }

    /**
     * @dev Call ingredientERC1155 contract for details.
     */
    function getIngredientsAttr(uint256[] memory ingredients) private view returns(
        uint32 f_calories,
        uint32 f_scent,
        uint32 f_freshness
    ){
        // need to verifying token types in main network
        bool[4] memory flags;
        for (uint i = 0; i < ingredients.length; i++){
            uint32[3] memory attr;
            uint8 childType;
            ( attr, , , childType) = ingredientERC1155.getIngredient(ingredients[i]);

            // ingredientERC1155 type enums: 1 meat, 2 veg, 3 fruit, 4 sauce
            flags[childType - 1] = true;
            
            f_calories += attr[0];
            f_scent += attr[1];
            f_freshness += attr[2];
        }
        // require 4 type of tokens
        for (uint i = 0; i < 4; i++){
            require(flags[i], "Incorrect type of ingredients required for merge");
        }
    }

    /**
     * @dev Call equipmentERC1155 contract for details.
     */
    function getEquipmentsAttr(uint256[] memory _equipments) private view returns(
        uint32 e_aggressivity,
        uint32 e_defensive,
        uint32 e_healthPoint
    ){

        // need to verifying token types in main network
        bool[3] memory flags;

        for (uint i = 0; i < _equipments.length; i++){
            uint32[3] memory adh;
            uint8 childType;
            (adh, , , childType) = equipmentERC1155.getEquipment(_equipments[i]);
            // equipmentERC1155 type enums: // 11 hat, 12 hand, 13 foot
            flags[childType - 11] = true;
            e_aggressivity += adh[0];
            e_defensive += adh[1];
            e_healthPoint += adh[2];
        }

        // require 3 type of tokens
        for (uint i = 0; i < 3; i++){
            require(flags[i], "Incorrect type of equipments required for merge");
        }
    }

    /**
     * @dev Set the number of CHI Tokens required for merge.
     */
    function setMergePrice(uint256 amount) onlyRole(DEFAULT_ADMIN_ROLE) external {
        mergePrice = amount;
    }

    /**
     * @dev Get the number of CHI Tokens required for merge.
     */
    function getMergePrice() external view returns (uint256) {
        return mergePrice;
    }

    function getTotalSandwiches() external view returns (uint256) {
        return totalSandwiches;
    }

    /**
     *  @dev Burn your sandwich and the parts will send to receiver.
     *
     *  Requirements: receiver not address(0) and msg.sender have this token
     */
    function burn(uint256 id, address receiver) public virtual override{
        _burn(_msgSender(), id, 1);
        // Return parts to holder
        _transferParts(address(this), receiver, sandwicheParts[id].ingredients, sandwicheParts[id].equipments);
    }

    /**
     *  @dev Burn your sandwich and the parts will send to you.
     *
     *  Requirements: msg.sender have this token
     */
    function burn(uint256 id) public virtual override {
        _burn(_msgSender(), id, 1);
        // Return parts to holder
        _transferParts(address(this), _msgSender(), sandwicheParts[id].ingredients, sandwicheParts[id].equipments);
    }

    function _transferParts(address from, address to, uint256[] memory ingredients, uint256[] memory equipments) internal{
        {
            uint[] memory amounts = new uint[](4);
            for(uint i = 0; i < 4; ++i)
                amounts[i] = 1;
            IERC1155Upgradeable(address(ingredientERC1155)).safeBatchTransferFrom(from, to, ingredients, amounts, "");
        }
        {
            uint[] memory amounts = new uint[](3);
            for(uint i = 0; i < 3; ++i)
                amounts[i] = 1;
            IERC1155Upgradeable(address(equipmentERC1155)).safeBatchTransferFrom(from, to, equipments, amounts, "");
        }
    }

    /**
     * @dev returns the metadata uri for a given id
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), StringsUpgradeable.toString(_id)));
    }

        /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function setBaseUrl(string memory url) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setURI(url);
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}