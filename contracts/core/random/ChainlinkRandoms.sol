// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../interface/IRandoms.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ChainlinkRandoms is IRandoms, VRFConsumerBaseV2, AccessControlUpgradeable{
    
    uint256 private seed;
    
    //dev: chanlink configure

    VRFCoordinatorV2Interface private COORDINATOR;
    //subscription ID.
    uint64 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit = 100000;
    // The default is 3, but you can set this higher.
    uint16 private requestConfirmations = 3;
    uint32 private numWords =  1;

    bytes32 public constant OPERATER_ROLE = keccak256("OPERATER_ROLE");

    constructor(uint64 _subscriptionId, address _vrfCoordinator,  bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        //init seed
        seed =  uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _keyHash)));
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATER_ROLE, _msgSender());
    }

    function getRandomSeed(address user) external override view returns (uint256){
        return this.getRandomSeedUsingHash(user, blockhash(block.number - 1));
    }
    
    function getRandomSeedUsingHash(address user, bytes32 hash) external override view returns (uint256){
        return uint256(keccak256(abi.encodePacked(user, seed, hash)));
    }

    function updateConfigure(uint64 _subscriptionId, uint32 _callbackGasLimit,uint16 _requestConfirmations, bytes32 _keyHash) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_callbackGasLimit >= 10000 && _requestConfirmations >=3, "error: invalid configure");
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
    }

    /**
     *@dev request random words to VRF Coordinator
     */
    function requestRandomWords() external onlyRole(OPERATER_ROLE){
        // Will revert if subscription is not set and funded.
        COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }

    /**
     *@dev Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        seed = uint256(keccak256(abi.encodePacked(seed, randomWords[0])));
    }

}