// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoundersPass is ERC1155, Ownable {
    using SafeMath for uint256;

    IERC20 USDT;

    mapping(uint256 => string) tokenUri;
    uint256 private constant TIER1_PRICE = 250 * (10 ** 18);
    uint256 private constant TIER2_PRICE = 4500 * (10 ** 18);

    constructor(
        address usdt,
        string memory tier1Uri,
        string memory tier2Uri
    ) ERC1155("Founders Pass") Ownable() {
        USDT = IERC20(usdt);
        _mint(address(this), 1, 2222, "");
        _mint(address(this), 2, 500, "");
        tokenUri[1] = tier1Uri;
        tokenUri[2] = tier2Uri;
    }

    function buyTier1Pass(uint _amount) public {
        require(_amount > 0, "Invalid amount entered.");
        require(
            balanceOf(address(this), 1) >= _amount,
            "Not enough passes left."
        );
        require(
            USDT.allowance(msg.sender, address(this)) >=
                (TIER1_PRICE.mul(_amount)),
            "Insufficient Allowence"
        );
        USDT.transferFrom(
            msg.sender,
            address(this),
            (TIER1_PRICE.mul(_amount))
        );
        _safeTransferFrom(address(this), msg.sender, 1, _amount, "");
    }

    function buyTier2Pass(uint _amount) public {
        require(_amount > 0, "Invalid amount entered.");
        require(
            balanceOf(address(this), 2) >= _amount,
            "Not enough passes left."
        );
        require(
            USDT.allowance(msg.sender, address(this)) >=
                (TIER2_PRICE.mul(_amount)),
            "Insufficient Allowence"
        );
        USDT.transferFrom(
            msg.sender,
            address(this),
            (TIER2_PRICE.mul(_amount))
        );
        _safeTransferFrom(address(this), msg.sender, 2, _amount, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenUri[tokenId];
    }

    function flushTokens() public onlyOwner {
        require(USDT.balanceOf(address(this)) > 0, "Not enough USDT to flush");
        USDT.transfer(owner(), USDT.balanceOf(address(this)));
    }
}
