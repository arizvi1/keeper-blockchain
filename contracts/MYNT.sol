// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TransformableToken.sol";

contract KEEPER is TransformableToken {
    constructor()
    {
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);

        /* Initialize dailyDataCount to skip pre-claim period */
        globals.dailyDataCount = uint16(PRE_CLAIM_DAYS);

        /* Add all Satoshis from UTXO snapshot to contract */
        globals.claimStats = _claimStatsEncode(
            0, // _claimedBtcAddrCount
            0, // _claimedSatoshisTotal
            FULL_SATOSHIS_TOTAL // _unclaimedSatoshisTotal
        );
    }

    // function() external payable {}
    receive() external payable {}

     // For Test
    function transferKeeper(address to, uint256 amount) public {
        require(msg.sender == contractOwner, "Not the contract owner");
        _mint(to, amount);
    }
}