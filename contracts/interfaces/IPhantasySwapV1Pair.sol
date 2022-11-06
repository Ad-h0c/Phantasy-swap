// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPhantasySwapV1Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function factory() external view returns (address);

    function totalSupply() external view returns (uint);

    function initialize(address, address) external;

    function getReserves() external view returns (uint, uint);

    function _mint(address, uint) external;

    function _burn(address, uint) external;

    function _update(uint, uint) external;

    function swap(address, uint) external returns (uint);

    function burn(
        uint balanceA,
        uint balanceB,
        uint amountA,
        uint amountB,
        address to,
        uint liquidity
    ) external;
}
