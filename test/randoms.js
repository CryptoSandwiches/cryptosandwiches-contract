const ChainlinkRandoms = artifacts.require('ChainlinkRandoms');
const BellyBox = artifacts.require('BellyBoxCore');
const Ingredient = artifacts.require('IngredientERC1155');
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

contract('ChainlinkRandoms', async accounts => {

  let randomContract,ingredientContract;
  let bellyBox;

  beforeEach(async () => {
    randomContract = await ChainlinkRandoms.deployed();
    ingredientContract = await Ingredient.deployed();
    bellyBox = await BellyBox.deployed();
  });
  
  it('should get random seed', async () => {
    const seed = await randomContract.getRandomSeed(accounts[0]);
	  console.log(`seed: ${seed}`);
  });
  
  it('should work', async () => {
      await bellyBox.createBellyBox(web3.utils.toWei('25000', 'ether'), 1);
  });

})