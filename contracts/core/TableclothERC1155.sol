// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./interface/ITableclothERC1155.sol";
import "./interface/ITableclothAwardsPool.sol";


contract TableclothERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, ITableclothERC1155, ERC2981Upgradeable {

    uint256 private idIndex;

    bytes32 public constant TYPE_MANAGER_ROLE = keccak256("TYPE_MANAGER_ROLE");

    struct TableclothType {
        string tableclothName;
        string tableclothDescribe;
        uint256 tableclothPrice;
        uint256 maximum;
        uint256 soldQuantity;
        uint16 attrnum;
    }

    struct HoldInfo{
        uint256 number;
        uint256[] tokenIds;
    }
    
    mapping(uint128 => TableclothType) public types;

    mapping(uint256 => uint128) public tokenTypeMapping;
    

    // This is an array on behalf of [Gold, Wood, Water, Fire, Earth] attributes
    uint16[5] private attributes;
    // This is an array on behalf of attributes' enemy [Fire, Gold, Earth, Water, Wood]
    uint16[5] private attributesEnemy;

    IERC20Upgradeable public cswCoin;
    ITableclothAwardsPool public tableclothAwardsPool;

    // The max holds of each type for an address.
    uint256 public maxHolds;
    // This mapping will record user tokens of every tablecloth type
    mapping(uint256 => mapping(address => HoldInfo)) private userHolds;


    /**
     * @dev Initialization constructor related parameters
     *
     * Requirements:
     * - `_attr` set gold, wood, water, fire and earth, five attributes values
     */
    function initialize(address cswAddress) initializer public {
        __ERC1155_init("https://cryptosandwiches.com/api/metadata/tablecloths/");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        attributes = [1, 2, 3, 4, 5];
        attributesEnemy = [4, 1, 5, 3, 2];
        cswCoin = IERC20Upgradeable(cswAddress);
        maxHolds = 10;
        _configTableclothType(1, "Metal Tablecloth", "", 5000 ether, 1, 10000);
        _configTableclothType(2, "Wood Tablecloth", "", 5000 ether, 2, 10000);
        _configTableclothType(3, "Water Tablecloth", "", 5000 ether, 3, 10000);
        _configTableclothType(4, "Fire Tablecloth", "", 5000 ether, 4, 10000);
        _configTableclothType(5, "Earth Tablecloth", "", 5000 ether, 5, 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(ITableclothERC1155).interfaceId || 
        ERC1155Upgradeable.supportsInterface(interfaceId) ||
        AccessControlUpgradeable.supportsInterface(interfaceId) ||
        ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setTableclothAwardsPool(address _address) onlyRole(DEFAULT_ADMIN_ROLE) external{
        tableclothAwardsPool = ITableclothAwardsPool(_address);
    }

    function setMaxHolds(uint256 _maxHolds) onlyRole(DEFAULT_ADMIN_ROLE) external{
        maxHolds = _maxHolds;
    }

    /**
     * @dev Get the enemy of attributes
     *
     * Requirements:
     * - attr >= 1 and <= 5
     */
    function getAttributesEnemy(uint16 attr) public view override returns(uint16){
        return attributesEnemy[attr - 1];
    }

    function configTableclothType(
        uint128 id,
        string memory _name,
        string memory _describe,
        uint256 tableclothPrice,
        bool[5] memory _attr,
        uint256 _maximum
    ) onlyRole(TYPE_MANAGER_ROLE) override external {
        require(id != 0, "Zero type id didn't support");
        uint16 attrnum;
        for(uint i = 0; i < 5; i++){
            if(_attr[i]){
                attrnum = attributes[i];
                break;
            }
        }
        _configTableclothType(id, _name, _describe, tableclothPrice, attrnum, _maximum);
        emit ConfigTableclothType(id, tableclothPrice, _maximum );
    }

    function _configTableclothType(
        uint128 id,
        string memory _name,
        string memory _describe,
        uint256 tableclothPrice,
        uint16 attrnum,
        uint256 _maximum
    ) internal {
        types[id].tableclothName = _name;
        types[id].tableclothDescribe = _describe;
        types[id].tableclothPrice = tableclothPrice;
        types[id].attrnum = attrnum;
        types[id].maximum = _maximum;
    }

    
     /**
     *  @dev Buy a tablecloth
     *
     *  Emits a {tableclothPurchase} event.
     */
    function buyTablecloth(
        uint256 cswAmount,
        uint128 typeId
    )  external override {
        require(types[typeId].tableclothPrice == cswAmount, "CSW value sent is not correct");
        require(types[typeId].soldQuantity + 1 <= types[typeId].maximum, "Quantity sold exceeds limit");
        nextTableclothId();

        _addHold(typeId, _msgSender(), idIndex);
        types[typeId].soldQuantity ++;
        tokenTypeMapping[idIndex] = typeId;
        SafeERC20Upgradeable.safeTransferFrom(cswCoin, _msgSender(), address(this), cswAmount);
        _setTokenRoyalty(idIndex, _msgSender(), 100);
        _mint(_msgSender(), idIndex, 1, "");
        emit TableclothPurchase(idIndex, _msgSender());
    }


    /**
     * @dev Get the token id list of holder
     *
     */
    function getHoldArray(uint128 typeId, address holder) external view override returns(uint256[] memory ids){
        return userHolds[typeId][holder].tokenIds;
    }

    function _addHold(uint128 typeId, address holder, uint256 tokenId) internal{
        HoldInfo storage holdInfo = userHolds[typeId][holder];
        require(++holdInfo.number <= maxHolds, "Exceed the purchase quantity limit");
        if(holdInfo.tokenIds.length < maxHolds)
            holdInfo.tokenIds.push(tokenId);
        else
            for(uint i = 0; i < maxHolds; i++){
                if(holdInfo.tokenIds[i] == 0){
                    holdInfo.tokenIds[i] = tokenId;
                    break;
                }
            }
    }

    function _reduceHold(uint128 typeId, address holder, uint256 tokenId) internal{
        HoldInfo storage holdInfo = userHolds[typeId][holder];
        holdInfo.number--;
        for(uint i = 0; i < holdInfo.tokenIds.length; i++)
            if(holdInfo.tokenIds[i] == tokenId){
                holdInfo.tokenIds[i] = 0;
                break;
            }
    }


    /**
     *  @dev Get tablecloth details by token id
     */
    function getTablecloth(uint256 _id) public view override returns (
        uint256 maximum,
        uint256 soldQuantity,
        uint256 price,
        bool[5] memory _attr,
        uint128 typeId,
        string memory tableclothName,
        string memory tableclothDescribe   
    ) {
        typeId = tokenTypeMapping[_id];
        TableclothType storage tableclothType = types[typeId];
        _attr[tableclothType.attrnum - 1] = true;
        maximum = tableclothType.maximum;
        soldQuantity = tableclothType.soldQuantity;
        price = tableclothType.tableclothPrice;
        tableclothName = tableclothType.tableclothName;
        tableclothDescribe = tableclothType.tableclothDescribe;
    }

    /**
     *  @dev Get tablecloth type by token id
     */
    function getTableclothType(uint256 _id) public view override returns (
        uint128 typeId
    ) {
        typeId = tokenTypeMapping[_id];
    }

    /**
     *  @dev Get tablecloth type details by type id
     */
    function getTypeDetails(uint128 typeId) public view override returns (
        string memory tableclothName,
        string memory tableclothDescribe,
        uint256 tableclothPrice,
        uint256 maximum,
        uint256 soldQuantity,
        bool[5] memory attr,
        uint16 attrnum,
        uint256 totalAwards
    ) {
        TableclothType storage tableclothType = types[typeId];
        tableclothName = tableclothType.tableclothName;
        tableclothDescribe = tableclothType.tableclothDescribe;
        tableclothPrice = tableclothType.tableclothPrice;
        maximum = tableclothType.maximum;
        soldQuantity = tableclothType.soldQuantity;
        attr[tableclothType.attrnum - 1] = true;
        attrnum = tableclothType.attrnum;
        totalAwards = tableclothAwardsPool.getPoolTotalAmount(typeId);
    }


    function name() external pure returns (string memory) {
        return "Cryptosandwiches Tablecloth"; 
    }

    function symbol() external pure returns (string memory) {
        return "Tablecloth";
    }

    function nextTableclothId() private {
         idIndex ++;
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
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _addHold(tokenTypeMapping[id], to, id);
        _reduceHold(tokenTypeMapping[id], from, id);
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        for(uint i = 0; i < ids.length; i++){
            uint128 typeId = tokenTypeMapping[ids[i]];
            _addHold(typeId, to, ids[i]);
           _reduceHold(typeId, from, ids[i]);
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}

