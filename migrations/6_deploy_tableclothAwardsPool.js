const Tablecloth = artifacts.require("TableclothERC1155");
const ChiCoin = artifacts.require("ChiCoin");
const IERC20 = artifacts.require("IERC20");
const TableclothAwardsPool = artifacts.require('TableclothAwardsPool');

const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function(deployer, network) {
  if (network === 'development'  || network === 'bsctestnet') {
    const tablecloth = await Tablecloth.deployed();
    let chiCoin;

    if (network === 'bsctestnet') {
      chiAddress = '0xf31ceaa87be2123c60396083c583b3ec436ec5ec';
      chiCoin = await IERC20.at(chiAddress);
    } else if (network === 'development') {
      chiCoin = await ChiCoin.deployed();
      chiAddress = chiCoin.address;
    }

    const instance = await deployProxy(TableclothAwardsPool, [tablecloth.address, chiAddress], { deployer });

    const awardsPool = await TableclothAwardsPool.deployed();
	
	  await tablecloth.setTableclothAwardsPool(awardsPool.address);

	  const TABLECLOTH_ROLE = await awardsPool.TABLECLOTH_ROLE();
    
	  await awardsPool.grantRole(TABLECLOTH_ROLE, tablecloth.address);
	
	  //add Qualifying to AWARDSSENDER_ROLE
  }else if (network === 'bscmainnet'){
    const tablecloth = await Tablecloth.deployed();
    const chiAddress = "0x51d9aB40FF21f5172B33e3909d94abdC6D542679";

    await deployProxy(TableclothAwardsPool, [tablecloth.address, chiAddress], { deployer });
    const awardsPool = await TableclothAwardsPool.deployed();

	  await tablecloth.setTableclothAwardsPool(awardsPool.address);
	  const TABLECLOTH_ROLE = await awardsPool.TABLECLOTH_ROLE();
	  await awardsPool.grantRole(TABLECLOTH_ROLE, tablecloth.address);
  }
};
