// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IPhantasySwapV1Pair.sol";

library PhantasyV1Library {
    function getReserves(address pair)
        internal
        view
        returns (uint reserveA, uint reserveB)
    {
        (reserveA, reserveB) = IPhantasySwapV1Pair(pair).getReserves();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "PhantasyV1Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "PhantasyV1Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * (reserveB)) / reserveA;
    }
}
