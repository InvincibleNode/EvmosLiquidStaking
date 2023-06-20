// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC20.sol";

import "./lib/AddressUtils.sol";
import "./lib/Structs.sol";
import "./lib/ArrayUtils.sol";

// evmos staking related
import "./staking/stateful/Staking.sol";
import "./staking/stateful/Distribution.sol";
import "./staking/common/Types.sol";


import "hardhat/console.sol";


contract EvmosLiquidStaking is Initializable, OwnableUpgradeable {
    //====== Contracts and Addresses ======//
    IERC20 private stEvmos;
    string public validatorAddress;
    string[] public stakingMethods;
    string[] public distributionMethods;


    //====== variables ======//
    // stake
    uint256 public totalStaked;

    // unstake
    uint public totalUnstakeRequestAmount;
    uint public unstakeRequestsFront;
    uint public unstakeRequestsRear;
    int64 public unstakeCompleteTime;

    // rewards
    uint256 public rewardAmount;
    uint256 public totalDistributedRewards;
    uint public rewardPeriod;
    uint public lastRewardedTime;
    uint public withdrawPeriod;
    uint public lastWithdrawTime;

    //------ Array and Mapping ------//
    UnstakeRequest[] public unstakeRequests;
    mapping (address => uint256) public claimable;

    //------ Events ------//
    event Stake(uint256 indexed _amount);
    event UnstakeRequestEvent (address indexed _userAddr, uint256 indexed _amount);
    event Unstake(uint256 indexed _amount);
    event Claim (address indexed _userAddr, uint256 indexed _amount);

    // ====== Modifiers ====== //
    bool internal locked;
    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
   
    //====== Initializer ======//
    function initialize(address _stEvmosAddr, string memory _validatorAddr) initializer public {
        __Ownable_init();
        stEvmos = IERC20(_stEvmosAddr);

        // unstake
        unstakeRequestsFront = 0;
        unstakeRequestsRear = 0;
        totalUnstakeRequestAmount = 0;

        // validator
        validatorAddress = _validatorAddr;

        // rewards
        rewardAmount = 0;
        totalDistributedRewards = 0;

        // periods
        lastRewardedTime = block.timestamp;
        rewardPeriod = 1 hours;
        withdrawPeriod = 5 minutes;

        stakingMethods = [MSG_DELEGATE, MSG_UNDELEGATE, MSG_REDELEGATE, MSG_CANCEL_UNDELEGATION];
        distributionMethods = [MSG_WITHDRAW_DELEGATOR_REWARD];

        locked = false;
    }

    //====== Getter Functions ======//
    function getUnstakeRequestsLength() public view returns (uint) {
        return unstakeRequestsRear - unstakeRequestsFront;
    }

    function getAllowance() public view returns (uint256 remaining) {
        return STAKING_CONTRACT.allowance(address(this), msg.sender, MSG_DELEGATE);
    }

    function getDelegatorReward() public view returns (DecCoin[] memory) {
        return DISTRIBUTION_CONTRACT.delegationRewards(address(this), validatorAddress);
    }
    //====== Setter Functions ======// 
    //====== Service Functions ======//
    //------user Service Functions------//
    function stake() external payable {
        uint _amount = msg.value;

        // update values
        totalStaked += _amount;

        bool successStk = STAKING_CONTRACT.approve(address(this), _amount, stakingMethods);
        require(successStk, "Staking Approve failed");     

        // check if this contract has enough ether
        require(address(this).balance >= _amount, "EvmosLiquidStaking: contract has not enough ether");
        bool successDelegate = STAKING_CONTRACT.delegate(address(this), validatorAddress, _amount);
        require(successDelegate, "Staking Delegate failed");

        // mint stEvmos token to msg.sender
        stEvmos.mintToken(msg.sender, _amount);
    
        // emit Stake event
        emit Stake(_amount);
    }

    function createUnstakeRequest (uint256 _amount) external {
        // check msg.sender's balance
        require(stEvmos.balanceOf(msg.sender) >= _amount, "EvmosLiquidStaking: unstake amount is more than stEvmos balance");
        // burn stEvmos token from msg.sender
        stEvmos.burnToken(msg.sender, _amount);

        // update totalStaked
        totalStaked -= _amount;

        // create unstake request
        UnstakeRequest memory request = UnstakeRequest(msg.sender, _amount, block.timestamp, false);

        // add unstake request to unstakeRequests
        unstakeRequestsRear = enqueueUnstakeRequests(unstakeRequests, request, unstakeRequestsRear);

        // emit Unstake event
        emit UnstakeRequestEvent(msg.sender, _amount);
    }

    function claim() external {
        require(claimable[msg.sender] > 0, "EvmosLiquidStaking: no claimable amount");
        uint amount = claimable[msg.sender];
        claimable[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value : amount}("");
        require(sent, "EvmosLiquidStaking: failed to send unstaked amount");

        emit Claim(msg.sender, amount);
    }


    //------other Service Functions------//
    function unstake() external {
        require(int256(block.timestamp) >= int256(unstakeCompleteTime), "EvmosLiquidStaking: not unstaked yet");
        setClaimableState();
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        uint totalAmount = 0;
        for (uint i = front; i < rear; i++) {
            if (!unstakeRequests[i].requested) {
                totalAmount += unstakeRequests[i].amount;
                unstakeRequests[i].requested = true;
            }
        }

        // undelegate
        STAKING_CONTRACT.approve(STAKING_PRECOMPILE_ADDRESS, totalAmount, stakingMethods);
        STAKING_CONTRACT.approve(address(this), totalAmount, stakingMethods);
        int64 completeTime = STAKING_CONTRACT.undelegate(address(this), validatorAddress, totalAmount);
        totalUnstakeRequestAmount += totalAmount;

        // update unstakeCompleteTime
        unstakeCompleteTime = completeTime;
    }

    function withdrawRewards () external {
        //require(lastRewardedTime + rewardPeriod < block.timestamp, "EvmosLiquidStaking: reward period is not passed yet");
        string[] memory allowedLists = new string[](1);
        allowedLists[0] = addressToString(address(this));
        // bool approved = DISTRIBUTION_CONTRACT.approve(msg.sender, distributionMethods, allowedLists);
        // require(approved, "EvmosLiquidStaking: approve failed");
        DISTRIBUTION_CONTRACT.approve(address(this), distributionMethods, allowedLists);
        //DISTRIBUTION_CONTRACT.approve(DISTRIBUTION_PRECOMPILE_ADDRESS, distributionMethods, allowedLists);
        Coin[] memory amount = DISTRIBUTION_CONTRACT.withdrawDelegatorRewards(address(this), validatorAddress);
        rewardAmount += amount[0].amount;

        // update time
        lastRewardedTime = block.timestamp;
        lastWithdrawTime = block.timestamp;
    }

    function spreadRewards() external  {
        require(rewardAmount > 0, "EvmosLiquidStaking: reward amount is 0");
        
        // get address list 
        address[] memory holders = stEvmos.getStEvmosHolders();
        require(holders.length > 0, "EvmosLiquidStaking: no stEvmos holders");

         // update totalDistributedRewards
        totalDistributedRewards += rewardAmount;
        uint rewards = rewardAmount;
        rewardAmount = 0;

        for (uint i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint amount = rewards * stEvmos.balanceOf(holders[i]) / totalStaked;
          
            stEvmos.mintToken(account, amount);
        }
    }

    function setClaimableState() internal {
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        for (uint i = front; i< rear; i++) {
            if (unstakeRequests[i].requested && unstakeRequests[i].amount > address(this).balance - rewardAmount) {
                break;
            }
            claimable[unstakeRequests[i].recipient] += unstakeRequests[i].amount;
            // remove first element of unstakeRequests
            unstakeRequestsFront = dequeueUnstakeRequests(unstakeRequests, unstakeRequestsFront, unstakeRequestsRear);
        }
    }

    //====== utils Functions ======//

}
