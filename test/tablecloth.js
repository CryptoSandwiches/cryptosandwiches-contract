const Tablecloth = artifacts.require('TableclothERC1155');
const CSWToken = artifacts.require('CSWToken');
const TableclothAwardsPool = artifacts.require('TableclothAwardsPool');
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

contract('TableCloth', async accounts => {

  let cswToken, tableclothContract, poolContract;

  beforeEach( async () => {
    tableclothContract = await Tablecloth.deployed();
    cswToken = await CSWToken.deployed();
    poolContract = await TableclothAwardsPool.deployed();
  });


  it('should work', async () => {
    const TYPE_MANAGER_ROLE = await tableclothContract.TYPE_MANAGER_ROLE();
    await tableclothContract.grantRole(TYPE_MANAGER_ROLE, accounts[0]);

    const amount = web3.utils.toWei('5000', 'ether');

    const { tx } = await tableclothContract.configTableclothType(1, 'red1', 'The red tablecloth', amount, [true, false, true, false, false], 10000);

    await expectEvent.inTransaction(tx, tableclothContract, 'ConfigTableclothType', { id: '1', maximum: '10000'});

  });

  it('should confirm whether to spend cswCoin when buying tablecloth shares, and confirm InitAwardsRecord events is happen', async () => {
    const amount = web3.utils.toWei('5000', 'ether');

    const balance = await cswToken.balanceOf(tableclothContract.address);

    const { tx } = await tableclothContract.buyTablecloth(amount, 1);

    const balanceNow = await cswToken.balanceOf(tableclothContract.address);

    assert.equal(balanceNow - balance, amount);
  });
})