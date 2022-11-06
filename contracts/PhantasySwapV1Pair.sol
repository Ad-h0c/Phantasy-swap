// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";

error NotTheFactoryContract(address);
error InvalidToken(address);
error InvalidAmount(uint);

/// @title phantasy core contract.

contract phantasyCore {
    address public token0;
    address public token1;
    address public factory;

    uint public totalSupply; /// @notice Total number of LP shares.

    mapping(address => uint) balanceOf; /// @notice User address to LP shares mapping.

    uint private reserve0;
    uint private reserve1;

    uint private unlocked = 1;

    constructor() {
        factory = msg.sender;
    }

    modifier lock() {
        require(unlocked == 1, "ERROR: It is locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // Helper functions

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    /**
     *   @notice "INITIALIZE" function will declares the token address and it is called by the factory address once.
     *   @param _token0, address of the first token
     *   @param _token1, address of the second token.
     *   @dev it is an external function as it is called by the factory address.
     */

    function initialize(address _token0, address _token1) external {
        if (msg.sender == factory) {
            revert NotTheFactoryContract(msg.sender);
        } else {
            token0 = _token0;
            token1 = _token1;
        }
    }

    /**
     *   @notice : "GETRESERVES" returns the latest balance of two token reserves.
     *   @dev : It is a view function and the intention is to save gas.
     *   @return _reserve0
     *   @return _reserve1
     */

    function getReserves()
        public
        view
        returns (uint _reserve0, uint _reserve1)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    /**
     *   @notice "_MINT" function will be minting coins.
     *   @param _to is the address which we are going to mint into.
     *   @param _amount is amount of the currency we are minting
     *   @dev Although, it is a internal function,
     *   we will be using private as we do not want imported contracts access this function.
     */

    function _mint(address _to, uint _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    /**
     *   @notice "_BURN" function will be burning coins.
     *   @param _from is the address which we are going to burn from.
     *   @param _amount is amount of the currency we are burning
     *   @dev Although, it is a internal function,
     *   we will be using private as we do not want imported contracts access this function.
     */

    function _burn(address _from, uint _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    /**
     *   @notice "_UPDATE" function will be updating the reserves.
     *   @param _reserve0 is the latest reserve of token0.
     *   @param _reserve1 is the latest reserve of token1,
     *   @dev Similary, the following function will be private.
     */

    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /**
     *   @notice "swap" function will swap one coin to another.
     *   @param _tokenIn, the exchange token.
     *   @param _amountIn, the amount of tokens to swap.
     *   @dev It will be an external function as it is called by the factory contract.
     *   @custom:math Math to swap function will be explained elsewhere. Read the comment below.
     */

    /*
        xy = k
        dx = deposited token,
        dy = withdrawal token.
        (x+dx)(y-dy) = k.
        Since we are depositing dx and withdrawing the dy, hence that equation.
        y - dy = k / (x + dx)
        -dy = k / (x + dx) - y
        dy = y - k / (x + dx)
        Since xy = k, we can replace k.
        dy = y - xy / (x + dx)
        dy = (yx - xy + ydx)/(x + dx)
        dy = ydx / (x + dx)
     */

    /// @dev Final result is the swap formula. dx and dy can interexchangble between token0 and token1.

    function swap(address _tokenIn, uint _amountIn)
        external
        lock
        returns (uint amountOut)
    {
        if (_tokenIn != token0 || _tokenIn != token1) {
            revert InvalidToken(_tokenIn);
        } else if (_amountIn <= 0) {
            revert InvalidAmount(_amountIn);
        } else {
            bool isToken0 = _tokenIn == token0;
            (
                address tokenIn,
                address tokenOut,
                uint reserveIn,
                uint reserveOut
            ) = isToken0
                    ? (token0, token1, reserve0, reserve1)
                    : (token1, token0, reserve1, reserve0);
            IERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);
            uint amountInWithFee = (_amountIn * 997) / 1000;

            // dy =  amountOut
            // y = reserveOut
            // dx = amountInWithFee
            // x = reserveIn

            // dy = (y * dx) / (x + dx)
            amountOut =
                (reserveOut * amountInWithFee) /
                (reserveIn + amountInWithFee);

            _update(
                IERC20(token0).balanceOf(address(this)),
                IERC20(token1).balanceOf(address(this))
            );
            IERC20(tokenOut).transfer(msg.sender, amountOut);
        }
    }

    /**
     * @notice "BURN" lets you remove liquidity from the pool.
     * @param liquidity, amount of shares the user account holds.
     * @custom:visibility external.
     */

    function burn(
        uint balanceA,
        uint balanceB,
        uint amountA,
        uint amountB,
        address to,
        uint liquidity
    ) external lock {
        _burn(to, liquidity);
        _update(balanceA - amountA, balanceB - amountB);
        IERC20(token0).transfer(to, amountA);
        IERC20(token1).transfer(to, amountB);
    }
}
