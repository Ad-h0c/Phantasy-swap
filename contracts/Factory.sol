//SPDX-License-Identifier:  MIT

pragma solidity ^0.8.9;

import "./phantasyCore.sol";

error IdenticalTokens(address, address);

contract PhantasyV1Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address _tokenA, address _tokenB) external {
        if (_tokenA != _tokenB) {
            (address token0, address token1) = _tokenA < _tokenB
                ? (_tokenA, _tokenB)
                : (_tokenB, _tokenA);
            require(token0 != address(0), "PhantasySwapV1: ZERO_ADDRESS");
            require(
                getPair[token0][token1] == address(0),
                "PhantasySwapV1: PAIR_EXISTS"
            );
        } else {
            revert IdenticalTokens(_tokenA, _tokenB);
        }
    }
}
