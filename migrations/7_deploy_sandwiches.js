const Sandwiches = artifacts.require("SandwichesERC1155");
const Ingredient = artifacts.require('IngredientERC1155');
const Equipment = artifacts.require('EquipmentERC1155');
const Tablecloth = artifacts.require("TableclothERC1155");
const TableclothAwardsPool = artifacts.require('TableclothAwardsPool');
const ChiCoin = artifacts.require("ChiCoin");
const IERC20 = artifacts.require("IERC20");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function(deployer, network) {
  if (network === 'development'  || network === 'bsctestnet' || network === 'bscmainnet') {
    const ingredient = await Ingredient.deployed();
    const equipment = await Equipment.deployed();
    const tablecloth = await Tablecloth.deployed();
    const awardsPool = await TableclothAwardsPool.deployed();
    let chiCoin;

    if (network === 'bsctestnet') {
      chiAddress = '0xf31ceaa87be2123c60396083c583b3ec436ec5ec';
      chiCoin = await IERC20.at(chiAddress);
    } else if (network === 'development') {
      chiCoin = await ChiCoin.deployed();
      chiAddress = chiCoin.address;
    }else if (network === 'bscmainnet') {
      chiAddress = '0x51d9aB40FF21f5172B33e3909d94abdC6D542679';
      chiCoin = await IERC20.at(chiAddress);
    }

    await deployProxy(Sandwiches, [ingredient.address, equipment.address, tablecloth.address, chiAddress], { deployer });
    const sandwiches = await Sandwiches.deployed();
    await sandwiches.setTableclothAwardsPool(awardsPool.address);
    const AWARDSSENDER_ROLE = await awardsPool.AWARDSSENDER_ROLE();
    await awardsPool.grantRole(AWARDSSENDER_ROLE, sandwiches.address);

    if (network === 'development') {
      await chiCoin.approve(sandwiches.address, web3.utils.toWei('10000000000', 'ether'));;
    }
    
    const SANDWICHES_ROLE = await ingredient.SANDWICHES_ROLE();
    await ingredient.grantRole(SANDWICHES_ROLE, sandwiches.address);
    await equipment.grantRole(SANDWICHES_ROLE, sandwiches.address);
  }
};
