// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "./interface/ITableclothERC1155.sol";
import "./interface/ITableclothAwardsPool.sol";

/**
 * @dev This is the implement about acclocation of chitoken to tablecloth holders
 */
contract TableclothAwardsPool is Initializable, AccessControlUpgradeable, ITableclothAwardsPool{

    struct AwardsPool{
        //current awardsAmount in pool
        uint256 currentAmount;
        //pool total amount, will only increase
        uint256 totalAmount;
    }

    ITableclothERC1155 public tableclothERC1155;
    IERC20Upgradeable public chiCoin;

    bytes32 public constant TABLECLOTH_ROLE = keccak256("TABLECLOTH_ROLE");
    bytes32 public constant AWARDSSENDER_ROLE = keccak256("AWARDSSENDER_ROLE");

    uint128 public constant override AWARDS_TYPE_BATTLE = 1;
    uint128 public constant override AWARDS_TYPE_MERGE = 2;
    

    // tableclothType => remainingAwards
    // This mapping will record the remaining awards amount while adding awards to pool but the tableCloth is not sold out. admin will realloc those awards to all token holder.
    mapping(uint128 => uint256) public remainingAwardsMapping;

    // tableclothType => AwardsPool
    mapping(uint128 => AwardsPool) public awardsPoolMapping;

    // tableclothId => indexPoolAmount
    mapping(uint256 => uint256) public tokenRecordMapping;

     /**
     * @dev Initialization constructor related parameters
     */
    function initialize(address _tableclothERC1155Address, address chiCoinAddress) public initializer{
        tableclothERC1155 = ITableclothERC1155(_tableclothERC1155Address);
        chiCoin = IERC20Upgradeable(chiCoinAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Add awards in pool.
     * only permit sandwith or qualifying role
     */
    function addAwards(
        address sender,
        uint128 awardsType,
        uint128 tableclothType,
        uint256 chiAmount
    ) external override onlyRole(AWARDSSENDER_ROLE) {
        //need approval at before
        SafeERC20Upgradeable.safeTransferFrom(chiCoin, sender, address(this), chiAmount);
        _addAwards(awardsType, tableclothType, chiAmount);
    }

    /**
     * @dev Add awards in pool.
     * only permit sandwith or qualifying role
     */
    function addAwards(
        address sender,
        uint128 awardsType,
        uint128[] memory tableclothTypes,
        uint256 chiAmount
    ) external override onlyRole(AWARDSSENDER_ROLE) {
        //need approval at before
        SafeERC20Upgradeable.safeTransferFrom(chiCoin, sender, address(this), chiAmount);
        uint256 amount = chiAmount/tableclothTypes.length;
        for(uint i = 0; i< tableclothTypes.length; i++)
            _addAwards(awardsType, tableclothTypes[i], amount);
    }

    function _addAwards(
        uint128 awardsType,
        uint128 tableclothType,
        uint256 chiAmount
        ) internal{
        
        //Add current awards amount.
        awardsPoolMapping[tableclothType].currentAmount += chiAmount;
        //Add total awards amount.
        awardsPoolMapping[tableclothType].totalAmount += chiAmount;
        
        emit AddAwards(awardsType, tableclothType, chiAmount);
    }


    /**
     * @dev Get the token's unaccalimed awards amount in pool.
     * only amount in pool of tokentype can you get
     */
    function getUnaccalimedAmount(uint256 tableclothId) external view override returns(uint256 amounts){
        return _getUnaccalimedAmount(tableclothId, tableclothERC1155.getTableclothType(tableclothId));
    }

    function getUnaccalimedAmountByType(uint128 tableclothType, address user) external view override returns(uint256 amounts){
         uint256[] memory ids = tableclothERC1155.getHoldArray(tableclothType, user);
        for(uint i = 0; i < ids.length; i++){
            if(ids[i] == 0) continue;
            amounts += _getUnaccalimedAmount(ids[i], tableclothType);
        }
    }

    function _getUnaccalimedAmount(uint256 tableclothId, uint128 typeId) internal view returns(uint256 amounts){
        //Unaccalimed amount = (totalAmount - indexPoolAmount)*1/10000
        uint256 deltaAmounts = awardsPoolMapping[typeId].totalAmount - tokenRecordMapping[tableclothId];
        amounts = deltaAmounts / 10000;
    }

    /**
     * @dev Withdraw the token's unaccalimed awards amount in pool.
     *  only amount in pool of tokentype can you withdraw
     */
    function withdraw(uint256 tableclothId, address to) external override{
        require(IERC1155Upgradeable(address(tableclothERC1155)).balanceOf(_msgSender(), tableclothId) >= 1, "TableclothAwardsPool error: not the owner");
        uint128 typeId = tableclothERC1155.getTableclothType(tableclothId);
        uint256 amount = _getUnaccalimedAmount(tableclothId, typeId);
        require(amount > 0, "No awards can withdraw");
        _withdraw(tableclothId, typeId, amount, to);
    }

    function withdrawByType(uint128 tableclothType, address to) external override{
        uint256[] memory ids = tableclothERC1155.getHoldArray(tableclothType, _msgSender());
        for(uint i = 0; i < ids.length; i++){
            if(ids[i] == 0) continue;
            uint256 awards = _getUnaccalimedAmount(ids[i], tableclothType);
            _withdraw(ids[i], tableclothType, awards, to);
        }

    }

    /**
     * @dev Get the pool's historical total awards amount in pool.
     */
    function getPoolTotalAmount(uint128 tableclothType) external override view returns(uint256 amounts){
        amounts= awardsPoolMapping[tableclothType].totalAmount;
    }

    /** internal function
     * @dev Withdraw the token's unaccalimed awards amount in pool.
     */
    function _withdraw(uint256 tableclothId, uint128 typeId, uint256 amount, address to) internal{
        if(amount > 0){
            //refresh indexPoolAmount
            tokenRecordMapping[tableclothId] = awardsPoolMapping[typeId].totalAmount;
            //reduce AwardsPool amount
            awardsPoolMapping[typeId].currentAmount -= amount;
            SafeERC20Upgradeable.safeTransfer(chiCoin, to, amount);
            emit Withdraw(tableclothId, to, amount);
        }
        
    }

}