// SPDX-License-Identifier: BSD-4-Clause
/*
 * Lib of array operation
 */
pragma solidity ^0.8.0;

library ArrayUtil {
    function removeAt(uint256[] storage self, uint256 index) internal view returns(uint256[] memory _self) {
        _self = new uint256[](self.length - 1);
        for(uint i = 0; i < index; ++i){
            _self[i] = self[i];
        }
        for(uint i = self.length - 1; i > index; --i){
            _self[i - 1] = self[i];
        }
    }
}