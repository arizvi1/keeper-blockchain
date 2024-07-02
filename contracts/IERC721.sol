// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Interfaces ============
interface IERC721  {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}