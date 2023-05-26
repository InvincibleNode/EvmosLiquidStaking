// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../lib/AddressUtils.sol";

// string constant TOKEN_FULL_NAME = "StEvmos Token";
// string constant TOKEN_NAME = "stEvmos";

contract StEvmos is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    //====== Contracts and Addresses ======//
    address public liquidStakingAddress;
    address[] public stEvmosHolders;


    //====== initializer ======//
    function initialize() initializer public {
        __ERC20_init("Stake Evmos Token", "stEvmos");
        __Ownable_init();
    }

    //====== modifier ======//
    modifier onlyLiquidStaking() {
        require(msg.sender == liquidStakingAddress ,"StEvmos: caller is not the liquid staking contract");
        _;
    }

    //====== getter Functions ======//
    function getStEvmosHolders() public view returns (address[] memory) {
        return stEvmosHolders;
    }

    //====== setter Functions ======//
    function setLiquidStakingAddress (address _liquidStakingAddr) onlyOwner external {
        liquidStakingAddress = _liquidStakingAddr;
    }

    //====== service functions ======//
    function mintToken(address _account, uint _amount) onlyLiquidStaking external {
        _mint(_account, _amount);

        // update StBfcHolderList
        addAddress(stEvmosHolders, _account);
    }

    function burnToken(address _account, uint _amount) onlyLiquidStaking external  {
        _burn(_account, _amount);
    }

    // ====== ERC20 override ====== //
    function transfer(address to, uint256 amount) public override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);

        // update StEvmosHolderList 
        addAddress(stEvmosHolders, to);

        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        // update StEvmosHolderList
        addAddress(stEvmosHolders, to);
        return true;
    }
}
