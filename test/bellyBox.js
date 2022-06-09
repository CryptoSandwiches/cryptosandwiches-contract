const Ingredient = artifacts.require('IngredientERC1155');
const Equipment = artifacts.require('EquipmentERC1155');
const BellyBox = artifacts.require('BellyBoxCore');
const CSWToken = artifacts.require('CSWToken');
const CHICoin = artifacts.require('ChiCoin');
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

contract('BellyBox', async accounts => {

  let cswToken, chiCoin, ingredientContract, equipmentContract, bellyBoxContract;

  beforeEach(async () => {
    chiCoin = await CHICoin.deployed();
    cswToken = await CSWToken.deployed();
    ingredientContract = await Ingredient.deployed();
    equipmentContract = await Equipment.deployed();
    bellyBoxContract = await BellyBox.deployed();
  });

  describe('createBellyBox', () => {
    it('should work', async () => {
      const { tx } = await bellyBoxContract.createBellyBox(web3.utils.toWei('25000', 'ether'), 1);

      await expectEvent.inTransaction(tx, ingredientContract, 'IngredientCreated', { id: '1' });
    });

    it('should confirm if cswCoin was received when bellyBox was created', async () => {
      const amount = web3.utils.toWei('25000', 'ether');
  
      const balance = await cswToken.balanceOf(bellyBoxContract.address);
  
      await bellyBoxContract.createBellyBox(amount, 1);
  
      const balanceNow = await cswToken.balanceOf(bellyBoxContract.address);
  
      assert.equal(balanceNow - balance, amount);
    });
  });

  describe('setBellyBox', () => {
    it('should get the same price as set', async () => {
      const amount = web3.utils.toWei('1', 'ether');
      await bellyBoxContract.setBellyBox(1, amount, amount, 1200, '');
      bellyBox = await bellyBoxContract.getBellyBox(1);

      assert.equal(bellyBox[2], 1200);
    });
  });
})