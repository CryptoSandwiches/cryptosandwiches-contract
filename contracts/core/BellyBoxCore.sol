// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/IIngredientERC1155.sol";
import "./interface/IEquipmentERC1155.sol";
import "./interface/IRandoms.sol";
import "./interface/IBellyBoxCore.sol";
import "./random/Random.sol";
import "../lib/ArrayUtil.sol";

contract BellyBoxCore is Initializable, AccessControlUpgradeable, IBellyBoxCore{
    struct BellyBox {
        // Quantity of CSW used to purchase a single blind box
        uint256 price;
        // Quantity of BUSD used to purchase a single blind box
        uint256 busdPrice;
        // Total supply of blind boxes
        uint64 supply;
        // Number of blind boxes that have been opened
        uint64 opened;
        // Description of Blind Box
        string describe;
    }

    uint256 private bellyBoxChiAmount;

    mapping(uint256 => BellyBox) private bellyBoxes;

    IIngredientERC1155 public ingredientERC1155;
    IEquipmentERC1155 public equipmentERC1155;
    IERC20Upgradeable public chiCoin;
    IERC20Upgradeable public cswToken;
    IERC20Upgradeable public busdToken;
    IRandoms public seedBiulder;

    // This array and mapping is for recording the number of childen type's sales and which type can getting.
    uint256[] private typeArray;

    /**
     * @dev Initialization constructor related parameters
     */
    function initialize(address _ingredientERC1155Address, address _equipmentERC1155Address, address chiCoinAddress, address cswAddress, address _seedBiulder, address _busdToken) public initializer{
        ingredientERC1155 = IIngredientERC1155(_ingredientERC1155Address);
        equipmentERC1155 = IEquipmentERC1155(_equipmentERC1155Address);
        chiCoin = IERC20Upgradeable(chiCoinAddress);
        cswToken = IERC20Upgradeable(cswAddress);
        seedBiulder = IRandoms(_seedBiulder);
        busdToken = IERC20Upgradeable(_busdToken);

        {
            BellyBox memory bellyBox1 = BellyBox({
                price: 25000 ether, // 25000 CSW
                busdPrice: 82.5 ether,
                supply: 24000,
                opened: 0,
                describe: "Go crack open the greasy Jumbo Belly Box! To grab a bite of the fine art BEP1155 NFTs cooked on BNB Smart Chain! The cuisine ingredient buried inside is gonna take you by big surprise! "
            });
            BellyBox memory bellyBox2 = BellyBox({
                price: 30000 ether, // 30000 CSW
                busdPrice: 99 ether,
                supply: 18000,
                opened: 0,
                describe: "Bust that dumb Deluxe Belly Box wide open! Spare no chance trying out the artsy BEP1155 NFTs forged on BNB Smart Chain. The hidden equipment is gonna fit you well!"
            });
            BellyBox memory bellyBox3 = BellyBox({
                price: 35000 ether, // 35000 CSW
                busdPrice: 115.5 ether,
                supply: 10000,
                opened: 0,
                describe: "Take good care of your supreme Royale Belly Box! Try your luck for the cuisine ingredient & hero equipment NFTs all-in-one with extra Chi Coin parcel sealed in. You can be the lucky dog!"
            });

            bellyBoxes[1] = bellyBox1;
            bellyBoxes[2] = bellyBox2;
            bellyBoxes[3] = bellyBox3;
        }

        bellyBoxChiAmount = 20000 ether; // 20000 CHI

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // 1 ingredients, 2 equipment, 3 chi token
        typeArray = [1, 2, 3];
    }

    /**
     * @dev Open a blind box
     * A certain amount of CSW needs to be paid as a fee
     *
     * This blind box has a chance to open three erc1155 tokens
     * 1.ingredient token
     * 2.equipment token
     * 3.CHI token
     */
    function createBellyBox(
        uint256 cswAmount,
        uint8 bellyBoxType
    ) public override {
        require(bellyBoxes[bellyBoxType].price == cswAmount, "CSW value sent is not correct");
        require(bellyBoxes[bellyBoxType].opened < bellyBoxes[bellyBoxType].supply, "The belly box exceeds the upper limit");
        require(!AddressUpgradeable.isContract(_msgSender()), "Only permit personal address");
        SafeERC20Upgradeable.safeTransferFrom(cswToken, _msgSender(), 0x000000000000000000000000000000000000dEaD , cswAmount);
        _openBox(bellyBoxType, address(cswToken), cswAmount);
    }

    /**
     * @dev Open a blind box
     * A certain amount of BUSD needs to be paid as a fee
     *
     * This blind box has a chance to open three erc1155 tokens
     * 1.ingredient token
     * 2.equipment token
     * 3.CHI token
     */
    function createBellyBoxByBUSD(
        uint256 busdAmount,
        uint8 bellyBoxType
    ) public override {
        require(bellyBoxes[bellyBoxType].busdPrice == busdAmount, "BUSD value sent is not correct");
        require(bellyBoxes[bellyBoxType].opened < bellyBoxes[bellyBoxType].supply, "The belly box exceeds the upper limit");
        require(!AddressUpgradeable.isContract(_msgSender()), "Only permit personal address");
        SafeERC20Upgradeable.safeTransferFrom(busdToken, _msgSender(), address(this), busdAmount);
        _openBox(bellyBoxType, address(busdToken), busdAmount);
    }

    function _openBox(
        uint8 bellyBoxType,
        address payWay,
        uint256 price
        ) private {
        uint length = typeArray.length;
        require(length > 0, "Ingredient: All belly box sales out");
        
        uint256 seed = seedBiulder.getRandomSeedUsingHash(_msgSender(), keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), bellyBoxes[bellyBoxType].opened)));
        uint256 firstType = bellyBoxType;
        if(bellyBoxType == 3) {
            bellyBoxType = uint8(typeArray[Random.createRandom(1, length, seed, block.timestamp) - 1]);
        }
        if(++ bellyBoxes[bellyBoxType].opened >= bellyBoxes[bellyBoxType].supply){
            for(uint i = 0; i < length; ++i){
                if(typeArray[i] == bellyBoxType){
                    // remove the box type from typeArray
                    typeArray = ArrayUtil.removeAt(typeArray, i);
                    break;
                }
            }
        }
        if (bellyBoxType == 1) {
            ingredientERC1155.createIngredient(_msgSender(), "", "", seed);
        }else if (bellyBoxType == 2) {
            equipmentERC1155.createEquipment(_msgSender(), "", "", seed);
        }else if (bellyBoxType == 3) {
            SafeERC20Upgradeable.safeTransfer(chiCoin, _msgSender(), bellyBoxChiAmount);
        }
        emit BellyBoxOpened(firstType, bellyBoxType, payWay, price);
    }

    function getTypes() external view returns(uint256[] memory){
        return typeArray;
    }

    /**
     * @dev Set the number of CHI required to open a blind box
     */
    function setBellyBoxChiAmount(uint256 amount) onlyRole(DEFAULT_ADMIN_ROLE) external {
        bellyBoxChiAmount = amount;
    }

    /**
     * @dev Get the number of CHI Tokens issued in the blind box
     */
    function getBellyBoxChiAmount() external view returns (uint256) {
        return bellyBoxChiAmount;
    }

    /**
     * @dev Set the random seed biulder
     */
    function setRandomSeedBiulder(address _seedBiulder) onlyRole(DEFAULT_ADMIN_ROLE) external {
        seedBiulder = IRandoms(_seedBiulder);
    }

    /**
     * @dev Set details based on blind box type
     *
     * Requirements:
     * - `bellyBoxType` blind box type: 1.ingredient 2.equipment 3.CHI
     * - `price` set blind box price
     * - `supply` set blind box supply
     * - `describe` set blind box describe
     */
    function setBellyBox(uint8 bellyBoxType, uint256 price, uint256 busdPrice, uint64 supply, string calldata describe) onlyRole(DEFAULT_ADMIN_ROLE) external {
        BellyBox storage box = bellyBoxes[bellyBoxType];
        box.price = price;
        box.busdPrice = busdPrice;
        box.supply = supply;
        box.describe = describe;
    }

    /**
     * @dev Get details based on blind box type
     */
    function getBellyBox(uint256 bellyBoxType) public view override returns (
        uint256 price,
        uint256 busdPrice,
        uint64 supply,
        uint64 opened,
        string memory describe
    ) {
        BellyBox storage box = bellyBoxes[bellyBoxType];
        price = box.price;
        busdPrice = box.busdPrice;
        supply = box.supply;
        opened = box.opened;
        describe = box.describe;
    } 

    function withrawERC20(address _token, address to) external onlyRole(DEFAULT_ADMIN_ROLE){
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        SafeERC20Upgradeable.safeTransfer(token, to, token.balanceOf(address(this)));
    }
    
}