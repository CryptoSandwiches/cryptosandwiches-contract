const Sandwiches = artifacts.require('SandwichesERC1155');
const Tablecloth = artifacts.require('TableclothERC1155');
const Ingredient = artifacts.require('IngredientERC1155');
const Equipment = artifacts.require('EquipmentERC1155');
const BellyBox = artifacts.require('BellyBoxCore');
const TableclothAwardsPool = artifacts.require('TableclothAwardsPool');
const ChiCoin = artifacts.require('ChiCoin');

const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

contract('Sandwiches', async accounts => {

  let sandwichesContract, bellyBoxContract, tableclothContract, pool, chi, ingredientContract, equipmentContract;

  beforeEach( async () => {
    ingredientContract = await Ingredient.deployed();
    equipmentContract = await Equipment.deployed();
    bellyBoxContract = await BellyBox.deployed();
    sandwichesContract = await Sandwiches.deployed();
    tableclothContract = await Tablecloth.deployed();
    pool = await TableclothAwardsPool.deployed();
    chi = await ChiCoin.deployed();
  });

  it('should work for merge sandwiches ', async () => {
  
    for (i = 0; i < 4; i ++) {
      await bellyBoxContract.createBellyBox(web3.utils.toWei('25000', 'ether'), 1);
    }
    
    for (i = 0; i < 3; i ++) {
      await bellyBoxContract.createBellyBox(web3.utils.toWei('30000', 'ether'), 2);
    }

    const TYPE_MANAGER_ROLE = await tableclothContract.TYPE_MANAGER_ROLE();
    await tableclothContract.grantRole(TYPE_MANAGER_ROLE, accounts[0]);

    await tableclothContract.configTableclothType(1, 'red1', 'The red tablecloth', web3.utils.toWei('5000', 'ether'), [true, false, true, false, false], 10000);

    //approve
    console.log("pool address: ", pool.address);
    await chi.approve(pool.address, web3.utils.toWei('210000', 'ether'));

    // make sure your ingredients and equipments contains all child types
    // other way, you can remove limit of types while test at local or testnet in contracts/core/SandwichesERC1155.sol at line 204 and 233 for testing merge heroes.
    const { tx } = await sandwichesContract.merge(web3.utils.toWei('210000', 'ether'), [1,2,3,4], [1,2,3], 1, '', '');

    await expectEvent.inTransaction(tx, sandwichesContract, 'SandwichesCreated', { id: '1'});

    const balance = await chi.balanceOf(pool.address);
    assert.equal(balance, web3.utils.toWei('20000', 'ether'));

  });
})