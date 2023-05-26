// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC20.sol";

import "./lib/AddressUtils.sol";
import "./lib/Structs.sol";
import "./lib/ArrayUtils.sol";
import "./staking/stateful/Staking.sol";
import "./staking/stateful/Distribution.sol";

import "hardhat/console.sol";


contract EvmosLiquidStaking is Initializable, OwnableUpgradeable {
    //====== Contracts and Addresses ======//
    IERC20 private stEvmos;
    address public stakeManager;
    string public validatorAddress;


    //====== variables ======//
    uint256 public totalStaked;
    uint256 public totalDistributedRewards;

    uint public unstakeRequestsFront;
    uint public unstakeRequestsRear;

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
    function initialize(address _stEvmosAddr, address _stakeManagerAddr, string memory _validatorAddr) initializer public {
        __Ownable_init();

        stEvmos = IERC20(_stEvmosAddr);
        stakeManager = _stakeManagerAddr;
        unstakeRequestsFront = 0;
        unstakeRequestsRear = 0;

            // validator
        validatorAddress = _validatorAddr;
    }

    //====== Getter Functions ======//
    function getUnstakeRequestsLength() public view returns (uint) {
        return unstakeRequestsRear - unstakeRequestsFront;
    }
    //====== Setter Functions ======// 
    //====== Service Functions ======//
    //------user Service Functions------//
    function stake() external payable nonReentrant{
        uint _amount = msg.value;

        // update totalStaked
        totalStaked += _amount;

        // // send msg.value to stakeManager
        // (bool success, ) = stakeManager.call{value: _amount}("");
        // require(success, "EvmosLiquidStaking: stakeManager transfer failed");

        STAKING_CONTRACT.delegate(address(this), validatorAddress, _amount);
        // mint stEvmos token to msg.sender
        stEvmos.mintToken(msg.sender, _amount);
    
        // emit Stake event
        emit Stake(_amount);
    }

    function createUnstakeRequest (uint256 _amount) external  nonReentrant {
        // check msg.sender's balance
        require(stEvmos.balanceOf(msg.sender) >= _amount, "EvmosLiquidStaking: unstake amount is more than stEvmos balance");
        // burn stEvmos token from msg.sender
        stEvmos.burnToken(msg.sender, _amount);

        // undelegate
        STAKING_CONTRACT.undelegate(address(this), validatorAddress, _amount);

        // update totalStaked
        totalStaked -= _amount;

        // create unstake request
        UnstakeRequest memory request = UnstakeRequest(msg.sender, _amount, block.timestamp, false);

        // add unstake request to unstakeRequests
        unstakeRequestsRear = enqueueUnstakeRequests(unstakeRequests, request, unstakeRequestsRear);

        // emit Unstake event
        emit UnstakeRequestEvent(msg.sender, _amount);
    }

    function withdrawRewards () external onlyOwner {
        DISTRIBUTION_CONTRACT.withdrawDelegatorRewards(address(this), validatorAddress);
    }

      function claim() external nonReentrant {
        require(claimable[msg.sender] > 0, "EvmosLiquidStaking: no claimable amount");
        uint amount = claimable[msg.sender];
        claimable[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value : amount}("");
        require(sent, "EvmosLiquidStaking: failed to send unstaked amount");

        emit Claim(msg.sender, amount);
    }

    //------stakeManager Service Functions------//
    function spreadRewards() external onlyOwner  {
        uint rewardAmount = address(this).balance;
        // get address list 
        address[] memory holders = stEvmos.getStEvmosHolders();

        require(holders.length > 0, "EvmosLiquidStaking: no stEvmos holders");
        require(rewardAmount > 0, "EvmosLiquidStaking: reward amount is 0");
        require(totalStaked > 0, "EvmosLiquidStaking: totalStaked is 0");

        for (uint i = 0; i < holders.length; i++) {
            address account = holders[i];
            uint rewardAmount = rewardAmount * stEvmos.balanceOf(holders[i]) / totalStaked;
          
            stEvmos.mintToken(account, rewardAmount);
        }
        // update totalDistributedRewards
        totalDistributedRewards += rewardAmount;
    }

    function unstake() external onlyOwner {
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        uint totalAmount = 0;
        for (uint i = front; i < rear; i++) {
            if (!unstakeRequests[i].requested) {
                totalAmount += unstakeRequests[i].amount;
                unstakeRequests[i].requested = true;
            }
        }

        emit Unstake(totalAmount);
    }

    function setClaimableState() external onlyOwner {
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        for (uint i = front; i< rear; i++) {
            if (unstakeRequests[i].amount > address(this).balance) {
                break;
            }
            claimable[unstakeRequests[i].recipient] += unstakeRequests[i].amount;
            // remove first element of unstakeRequests
            unstakeRequestsFront = dequeueUnstakeRequests(unstakeRequests, unstakeRequestsFront, unstakeRequestsRear);
        }
    }

    //====== utils Functions ======//

}
