//SPDX-License-Identifier:  MIT

pragma solidity ^0.8.9;

import "./PhantasyV1Pair.sol";

error IdenticalTokens(address, address);

contract PhantasyV1Factory {
    mapping(address => mapping(address => address)) public getPair;

    phantasyCore[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    /// Tells how many accounts are there.
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /**
     * @notice "CREATE PAIR" function creates token pair.
     * @param _tokenA, an address of the first token.
     * @param _tokenB, an address of the second token.
     * @return pair, token pair address.
     */

    function createPair(address _tokenA, address _tokenB)
        external
        returns (address)
    {
        if (_tokenA != _tokenB) {
            (address token0, address token1) = _tokenA < _tokenB
                ? (_tokenA, _tokenB)
                : (_tokenB, _tokenA);
            require(token0 != address(0), "PhantasySwapV1: ZERO_ADDRESS");
            require(
                getPair[token0][token1] == address(0),
                "PhantasySwapV1: PAIR_EXISTS"
            );
            phantasyCore pair = new phantasyCore();
            pair.initialize(token0, token1);
            allPairs.push(pair);
            // Populate mapping in bi-direction.
            getPair[token0][token1] = address(pair);
            getPair[token1][token0] = address(pair);
            emit PairCreated(token0, token1, address(pair), allPairs.length);
            return address(pair);
        } else {
            revert IdenticalTokens(_tokenA, _tokenB);
        }
    }
}
