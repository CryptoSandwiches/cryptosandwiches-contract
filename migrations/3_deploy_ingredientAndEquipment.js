const Ingredient = artifacts.require('IngredientERC1155');
const Equipment = artifacts.require("EquipmentERC1155");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');


module.exports = async function(deployer, network) {
  if (network === 'development'  || network === 'bsctestnet' || network === 'bscmainnet') {
    await deployProxy(Ingredient, { deployer });
    await deployProxy(Equipment, { deployer });
  }
};
