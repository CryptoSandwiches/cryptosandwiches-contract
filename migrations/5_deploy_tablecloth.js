const Tablecloth = artifacts.require("TableclothERC1155");
const CSWToken = artifacts.require("CSWToken");
const IERC20 = artifacts.require("IERC20");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function(deployer, network) {
  if (network === 'development'  || network === 'bsctestnet') {
    let cswToken;
    let cswAddress;
    
    if (network === 'bsctestnet') {
      cswAddress = '0x0bbDD301bB85000c68F3D3928274D877F10a1C8c'
      cswToken = await IERC20.at(cswAddress);
    } else if (network === 'development') {
      cswToken = await CSWToken.deployed();
      cswAddress = cswToken.address;
    }

    await deployProxy(Tablecloth, [cswAddress], { deployer });

    const tablecloth = await Tablecloth.deployed();
    await tablecloth.setMaxHolds(10);

    await cswToken.approve(tablecloth.address, web3.utils.toWei('10000000000', 'ether'));
  }else if (network === 'bscmainnet'){
    const cswAddress = "0x537b29fDBdA890583aF6398ECe76D57fEe2Dac7f";
    await deployProxy(Tablecloth, [cswAddress], { deployer });
    const tablecloth = await Tablecloth.deployed();
  }
};
