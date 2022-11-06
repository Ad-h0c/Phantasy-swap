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

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PhantasyV1Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? IPhantasySwapV1Factory(Factory).getPair(output, path[i + 2])
                : _to;

            address pair = IPhantasySwapV1Factory(Factory).getPair(
                input,
                output
            );
            IPhantasySwapV1Pair(pair).swap(amount0Out, amount1Out, to);
        }
    }

    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = PhantasyV1Library.getAmountsOut(Factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PhantasySwapV1: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IPhantasySwapV1Factory(Factory).getPair(path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }
}
