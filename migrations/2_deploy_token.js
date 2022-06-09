const ChiCoin = artifacts.require('ChiCoin');
const cswToken = artifacts.require('CSWToken');

module.exports = async function(deployer, network) {
  if (network === 'development') {
    await deployer.deploy(ChiCoin);
    await deployer.deploy(cswToken);
  }
};
