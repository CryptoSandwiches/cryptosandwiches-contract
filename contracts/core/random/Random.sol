// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Random {
    
    /**
     * @dev Create a random number.
     */
    function createRandom(uint256 min, uint256 max, uint256 seed) internal pure returns (uint8)
    { 
         // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max - min + 1;
        uint randomVar = uint(keccak256(abi.encodePacked(seed))) % diff;
        randomVar = randomVar + min;
        return uint8(randomVar);
    }

    /**
     * @dev Create a random number.
     */
    function createRandom(uint256 min, uint256 max, uint256 seed1, uint256 seed2) internal pure returns (uint8)
    { 
        return createRandom(min, max, combineSeeds(seed1, seed2));
    }

    /**
     * @dev combine and refresh seed.
     */
    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }
}
