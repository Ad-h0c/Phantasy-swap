//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IPhantasySwapV1Pair.sol";
import "./interfaces/IPhantasySwapV1Factory.sol";
import "./interfaces/IERC20.sol";
import "./PhantasySwapV1Pair.sol";
import "./lib/HelperMath.sol";
import "./lib/TransferHelper.sol";
import "./lib/PhantasyV1Library.sol";

/**
 * @custom:function - AddLiquidity
 * @custom:function - RemoveLiquidity
 * @custom:function - swapTokenstoTokens
 */

contract PhantasySwapRouterV01 {
    address public immutable Factory;

    constructor(address _factory) {
        Factory = _factory;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "PhantasySwapV1Router: EXPIRED");
        _;
    }

    /* ***** ADD LIQUIDITY ***** */

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint maxAmountA,
        uint maxAmountB
    ) internal virtual returns (uint amountA, uint amountB) {
        if (
            IPhantasySwapV1Factory(Factory).getPair(tokenA, tokenB) ==
            address(0)
        ) {
            IPhantasySwapV1Factory(Factory).createPair(tokenA, tokenB);
        }

        address pair = IPhantasySwapV1Factory(Factory).getPair(tokenA, tokenB);

        (uint reserveA, uint reserveB) = PhantasyV1Library.getReserves(pair);

        if (reserveA == 0 && reserveB == 0) {
            amountA = maxAmountA;
            amountB = maxAmountB;
        } else {
            uint amountBOptimal = PhantasyV1Library.quote(
                maxAmountA,
                reserveA,
                reserveB
            );

            if (amountBOptimal <= maxAmountB) {
                (amountA, amountB) = (maxAmountA, amountBOptimal);
            } else {
                uint256 amountAOptimal = PhantasyV1Library.quote(
                    maxAmountB,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= maxAmountA);
                (amountA, amountB) = (amountAOptimal, maxAmountB);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint maxAmountA,
        uint maxAmountB,
        address to, // The one who is adding liquidity or also known as connected wallet.
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            maxAmountA,
            maxAmountB
        );
        address pair = IPhantasySwapV1Factory(Factory).getPair(tokenA, tokenB);

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        (uint reserveA, uint reserveB) = PhantasyV1Library.getReserves(pair);

        uint totalSupply = IPhantasySwapV1Pair(pair).totalSupply();

        if (totalSupply == 0) {
            liquidity = HelperMath.sqrt(amountA * amountB);
        } else {
            liquidity = HelperMath.min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }

        // Liquidity reserves
        require(liquidity > 0, "PHANTASYSWAP: SHARES = 0");

        IPhantasySwapV1Pair(pair)._mint(to, liquidity);
    }

    /* ***** REMOVE LIQUIDITY ***** */

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity
    ) external returns (uint amountA, uint amountB) {
        address pair = IPhantasySwapV1Factory(Factory).getPair(tokenA, tokenB);
        uint balanceA = IERC20(tokenA).balanceOf(pair);
        uint balanceB = IERC20(tokenB).balanceOf(pair);

        uint totalSupply = IPhantasySwapV1Pair(pair).totalSupply();

        amountA = (liquidity * balanceA) / totalSupply;
        amountB = (liquidity * balanceB) / totalSupply;

        require(
            amountA > 0 && amountB > 0,
            "PHANTASYSWAPV1ROUTER: Amount is less than zero"
        );

        IPhantasySwapV1Pair(pair).burn(
            balanceA,
            balanceB,
            amountA,
            amountB,
            msg.sender,
            liquidity
        );
    }

    /** **** SWAP **** */

    function swap() external {}
}
