// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandoms {
    /**
     * @dev return a uint256 length seed.
     */
    function getRandomSeed(address user) external view returns (uint256 seed);
    
    /**
     * @dev return a uint256 length seed, result will encode with input hash.
     */
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);
}
