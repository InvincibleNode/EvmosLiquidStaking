// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStBFC {
    function setLiquidStakingAddress(address _liquidStakingAddr) external;
    function mintToken(address _account, uint256 _amount) external;
    function burnToken(address _account, uint256 _amount) external;
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}