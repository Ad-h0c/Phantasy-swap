// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPhantasyV1Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function factory() external view returns (address);

    function totalSupply() external view returns (uint);

    function initialize(address, address) external;

    function getReserves() external view returns (uint, uint);
}
