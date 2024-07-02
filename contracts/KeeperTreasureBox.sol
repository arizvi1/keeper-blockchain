// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721.sol";
import "./IGlobals.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract KeeperTreasureBox {
    
    IGlobals public GlobalsInstance;
    
    /* ============== Constructor ============= */
    constructor(address _keeperContractAddress, address _MYTNFTAddress, address _keeperistPlatformAddress)
    {
        GlobalsInstance = IGlobals(_keeperContractAddress);
        NftAddress = IERC721(_MYTNFTAddress);

        keeperistPlatformAddress = _keeperistPlatformAddress;
    }

    /* ============== State Variables ============= */
    uint256 public constant MAX_DEPOSIT = 100 ether; 
    uint256 public constant EXCHANGE_RATE = 1 ether; // For Test
    address public keeperistPlatformAddress;
    IERC721 public NftAddress;
    uint256 public nonFlushableAmount;

    /* ================== Structs ================= */
    struct TreasureBox {
        address creator;
        uint256 depositAmount;
        uint256 totalKeeperReward;
        uint256 claimDate;
        uint256 createdAt;
        mapping(uint256 => uint256) rewards;
        mapping(uint256 => NftInfo) nftInfoMap;
        uint256 remainingNfts; 
        bool ethDistribution;
    }

    struct NftInfo {
        uint256 nftId;
        uint256 nftValue;
    }

    /* ================== Modifiers =============== */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == GlobalsInstance.contractOwner());
    } 

    /* ================== Mappings =============== */
    mapping(address => TreasureBox[]) public treasureBoxes;

    /* ================== Events ================= */
    event TreasureBoxCreated(
        address indexed creator,
        uint256 claimDate,
        NftInfo[] nftInfo,
        uint256 depositAmount,
        uint256 totalReward
    );
    
    event RewardClaimed(
        address indexed claimer,
        uint256 indexed boxId,
        uint256 indexed nftId,
        uint256 rewardAmount
    );
    
    event TreasureBoxFunded(
        address indexed funder,
        address creator,
        uint256 amount,
        uint256 fundedAt
    );

    event FundsReceived(
        address indexed funder,
        uint256 amount,
        uint256 fundedAt
    );
    
    event CoinsDistributed(
        address indexed treasureBoxOwner,
        uint256 indexed boxId,
        uint256 indexed _nftId,
        uint256 distributionAmount
    );

    /* ================== Functions =============== */
    function checkOwnership(uint256 tokenId) internal view returns (address) {
        return IERC721(NftAddress).ownerOf(tokenId);
    }

    function createTreasureBox(uint256 _claimDate, NftInfo[] calldata _nftInfos) external payable {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_nftInfos.length > 0, "Must link at least one NFT");
        require(msg.value > 0 && msg.value <= MAX_DEPOSIT, "Invalid deposit or out of range.");

        uint256 keeperTokens = 10000000000; // ethToKeeper(msg.value);       

        // Push an empty struct
        TreasureBox storage newBox = treasureBoxes[msg.sender].push();

        // Insert The values
        newBox.creator = msg.sender;
        newBox.depositAmount = msg.value;
        newBox.claimDate = _claimDate;
        newBox.createdAt = block.timestamp;
        newBox.ethDistribution = false;
        newBox.remainingNfts = _nftInfos.length;
        newBox.totalKeeperReward = keeperTokens;

        // Calculate the rewards are distributed to the NFT owner based on the value of their NFTs.
        uint256[] memory rewards = distributeRewardToNFTOwner(_nftInfos, keeperTokens);

        for (uint256 i = 0; i < _nftInfos.length; ++i) {
            require(_nftInfos[i].nftId > 0 && _nftInfos[i].nftValue > 0, "NFT ID and value must be greater than zero.");
            require(msg.sender == checkOwnership(_nftInfos[i].nftId), "Caller does not own the NFTs");
            
            // Store NftInfo and rewards
            newBox.rewards[_nftInfos[i].nftId] = rewards[i];
            newBox.nftInfoMap[_nftInfos[i].nftId] = NftInfo(_nftInfos[i].nftId, _nftInfos[i].nftValue);
        }

        // Update the Information
        nonFlushableAmount += msg.value;

        emit TreasureBoxCreated(msg.sender, _claimDate, _nftInfos, msg.value, keeperTokens);
    }

    function claimTreasureBox(address _creator, uint256 _boxId, uint256 _nftId) external {
        require(treasureBoxes[_creator].length > 0, "Invalid Creator Address");
        require(_boxId > 0 && _boxId <= treasureBoxes[_creator].length, "Invalid box ID");
        require(msg.sender == checkOwnership(_nftId), "Caller does not own the NFTs");
        
        TreasureBox storage box = treasureBoxes[_creator][_boxId - 1];
        // require(block.timestamp >= box.claimDate, "Reward cannot claim before the Claim Date");

        NftInfo storage nftInfo = box.nftInfoMap[_nftId];
        require(nftInfo.nftId != 0, "NFT ID Not found in Treasure Box");

        uint256 rewardAmount = box.rewards[_nftId];

        GlobalsInstance.mint(msg.sender, rewardAmount, GlobalsInstance.getTreasureBoxAddress());

        if (box.depositAmount > 0){
            distributeRaisedCoins(box.creator, _boxId, _nftId);
        }

        delete box.nftInfoMap[_nftId];
        delete box.rewards[_nftId];

        box.remainingNfts -= 1; // Decrement the count of remaining NFTs

        if (box.remainingNfts == 0) {
            delete treasureBoxes[_creator][_boxId - 1];
        }

        emit RewardClaimed(msg.sender, _boxId, _nftId, rewardAmount);
    }

    function distributeRewardToNFTOwner(NftInfo[] calldata _nftInfo, uint256 _totalKeeperReward) internal pure returns (uint256[] memory) {
        uint256 totalValues = 0;
        uint256[] memory rewards = new uint256[](_nftInfo.length);

        for (uint256 i = 0; i < _nftInfo.length; ++i) {
            // Total sum of values
            totalValues += _nftInfo[i].nftValue;
        }

        for (uint256 i = 0; i < _nftInfo.length; ++i) {
            // The Percentage for each NFT value
            rewards[i] = (_totalKeeperReward * _nftInfo[i].nftValue) / totalValues;
        }
        return rewards;
    }

    function keeperToEth(uint256 _amountInTokens) public pure returns (uint256)
    {
        return _amountInTokens * EXCHANGE_RATE;
    }

    function ethToKeeper(uint256 _depositAmount) public pure returns (uint256) {
        return _depositAmount / EXCHANGE_RATE;
    }

    function distributeRaisedCoins(address _creator, uint256 _boxId, uint256 _nftId) internal {
        TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId - 1];

        // Calculate how much to distribute to each party
        uint256 distributionAmount = treasureBox.depositAmount / 3;
        // console.log("distributionAmount: ", distributionAmount);

        // Transfer to Platform
        transferFunds(keeperistPlatformAddress, distributionAmount);

        // Transfer to TreasureBox Owner
        transferFunds(_creator, distributionAmount);

        // Effects
        treasureBox.depositAmount -= distributionAmount * 3;
        nonFlushableAmount -= distributionAmount * 3 + treasureBox.depositAmount; // Decrement nonFlushableAmount with remainder

        treasureBox.depositAmount = 0; // Reset
        treasureBox.ethDistribution = true;

        emit CoinsDistributed(_creator, _boxId, _nftId, distributionAmount);
    }

    function fundEthToTreasureBox(address _creator, uint256 _boxId) external payable
    {
        TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId - 1];

        require(msg.value > 0, "Insufficient ETH/BNB");
        require(treasureBoxes[_creator].length > 0, "Invalid Creator Address");
        require(_boxId > 0 && _boxId <= treasureBoxes[_creator].length, "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        // Add the new deposit to the total deposit.
        treasureBox.depositAmount += msg.value;

        nonFlushableAmount += msg.value; // Increment nonFlushableAmount

        emit TreasureBoxFunded(msg.sender, _creator, msg.value, block.timestamp);
    }

    function fundTokensToTreasureBox(address _creator, uint256 _boxId, uint256 _keeperTokens) external 
    {
        TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId -1 ];

        require(_keeperTokens > 0, "Insufficient KEEPER Tokens" );
        require(treasureBoxes[_creator].length > 0, "Invalid Creator Address");
        require(_boxId > 0 && _boxId <= treasureBoxes[_creator].length, "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        // Transfer KEEPER tokens to the treasure box
        // GlobalsAndUtilityInstance.transferTokens( _creator, _keeperTokens); // _transfer(msg.sender, _creator, _keeperTokens);
        
        // treasureBox.totalKeeperReward += _keeperTokens; // TBD
 
        emit TreasureBoxFunded(msg.sender, _creator, _keeperTokens, block.timestamp);
    }

    // Owner of the contract recieve ETH
    function flushContractBalanceToOwner() external onlyOwner {
        uint256 flushableAmount = address(this).balance - nonFlushableAmount;
        require(address(this).balance != 0 && flushableAmount != 0, "KEEPER: No Value to flush");
        transferFunds(GlobalsInstance.FLUSH_ADDR(), flushableAmount);
    }

    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transfer fee failed");
    }

}

// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]

// 1731249873 // 1699866621 30
// [[1,2],[2,4],[3,6]]   [[4,2],[5,4],[6,6]]  [[7,2],[8,4],[9,6]]
// 500000000000000000
