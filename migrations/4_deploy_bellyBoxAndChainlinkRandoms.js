const BellyBox = artifacts.require('BellyBoxCore');
const Ingredient = artifacts.require('IngredientERC1155');
const Equipment = artifacts.require('EquipmentERC1155');
const ChiCoin = artifacts.require('ChiCoin');
const CSWToken = artifacts.require('CSWToken');
const IERC20 = artifacts.require("IERC20");
const ChainlinkRandoms = artifacts.require('ChainlinkRandoms');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');


module.exports = async function(deployer, network, accounts) {

  if (network === 'development' || network === 'bsctestnet') {
    const ingredient = await Ingredient.deployed();
    const equipment = await Equipment.deployed();

    let chiCoin;
    let cswToken;
    let busdToken;
    let chiAddress;
    let cswAddress;
	  let randomAddress;
    let busdAddress;
    
    if (network === 'bsctestnet') {
      chiAddress = '0xf31ceaa87be2123c60396083c583b3ec436ec5ec';
      cswAddress = '0x0bbDD301bB85000c68F3D3928274D877F10a1C8c';
      randomAddress = '0x88A7Ce9F7471BE796Fb8c0eE97D61fE1fcAD988B';
      busdAddress = '0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee';
      chiCoin = await IERC20.at(chiAddress);
      cswToken = await IERC20.at(cswAddress);
      busdToken = await IERC20.at(busdAddress);
    } else if (network === 'development') {
      chiCoin = await ChiCoin.deployed();
      cswToken = await CSWToken.deployed();
      await deployer.deploy(ChainlinkRandoms, 620, '0x6168499c0cFfCaCD319c818142124B7A15E857ab', '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc');
      const chainlinkRandoms = await ChainlinkRandoms.deployed();
      randomAddress = chainlinkRandoms.address;
      chiAddress = chiCoin.address;
      cswAddress = cswToken.address;
      busdAddress = cswAddress;
    }
	

    await deployProxy(BellyBox, [ingredient.address, equipment.address, chiAddress, cswAddress, randomAddress, busdAddress], { deployer });

    const bellyBox = await BellyBox.deployed();
    
    await cswToken.approve(bellyBox.address, web3.utils.toWei('10000000000', 'ether'));
    await chiCoin.transfer(bellyBox.address, web3.utils.toWei('10000000', 'ether')); // 10000000 test token

    const BELLYBOX_ROLE = await ingredient.BELLYBOX_ROLE();
    await ingredient.grantRole(BELLYBOX_ROLE, bellyBox.address);
    await equipment.grantRole(BELLYBOX_ROLE, bellyBox.address);

  }else if (network === 'bscmainnet'){
    const ingredient = await Ingredient.deployed();
    const equipment = await Equipment.deployed();
    const chiAddress = "0x51d9aB40FF21f5172B33e3909d94abdC6D542679";
    const cswAddress = "0x537b29fDBdA890583aF6398ECe76D57fEe2Dac7f";
    const busdAddress = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
	  await deployer.deploy(ChainlinkRandoms, 169, '0xc587d9053cd1118f25F645F9E08BB98c9712A4EE', '0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04');
    const chainlinkRandoms = await ChainlinkRandoms.deployed();

    await deployProxy(BellyBox, [ingredient.address, equipment.address, chiAddress, cswAddress, chainlinkRandoms.address, busdAddress], { deployer });
    const bellyBox = await BellyBox.deployed();
    const BELLYBOX_ROLE = await ingredient.BELLYBOX_ROLE();
    await ingredient.grantRole(BELLYBOX_ROLE, bellyBox.address);
    await equipment.grantRole(BELLYBOX_ROLE, bellyBox.address);
  }
};
