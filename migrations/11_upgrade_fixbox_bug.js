const BellyBoxCore = artifacts.require("BellyBoxCore");
const Tablecloth = artifacts.require("TableclothERC1155");

const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

// This upgrade is for fixing the bug when open box, user can use contract to getting chi every times, and send token to dead address
// For version f28ed3bd30c2e1d9fff41bd2a7e83a4dbfebc6e9
module.exports = async function (deployer, network) {
    if(network === 'bscmainnet'){
        const box = await BellyBoxCore.deployed();
        await upgradeProxy(box.address, BellyBoxCore, { deployer });

        const tablecloth = await Tablecloth.deployed();
        await upgradeProxy(tablecloth.address, Tablecloth, { deployer });
    }
}
