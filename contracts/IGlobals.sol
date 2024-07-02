// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Interfaces ============
interface IGlobals  {

   /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        // 1
        uint256 _lockedGeosTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
        uint256 _stakePenaltyTotal;
        // 2
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;
        uint256 _unclaimedSatoshisTotal;
        uint256 _claimedSatoshisTotal;
        uint256 _claimedBtcAddrCount;
        //
        uint256 _currentDay;
    }

    function getGlobalsLoad(GlobalsCache memory, GlobalsCache memory) external view ;
    function FLUSH_ADDR() external view returns (address payable);
    function contractOwner() external view returns (address);

    function mint(address _receiver, uint256 _amount, address _contractAddress) external;
    function getTreasureBoxAddress() external view returns (address);
}