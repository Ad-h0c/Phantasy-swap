// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPhantasySwapV1Factory {
    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address);
}
