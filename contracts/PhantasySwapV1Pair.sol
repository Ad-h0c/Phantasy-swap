// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";

error NotTheFactoryContract(address);
error InvalidToken(address);
error InvalidAmount(uint);
error INSUFFICIENT_LIQUIDITY();

/// @title phantasy core contract.

contract phantasyCore {
    address public token0;
    address public token1;
    address public factory;

    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

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

    function _safeTransfer(
        address token,
        address to,
        uint value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "phantasySwap: TRANSFER_FAILED"
        );
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

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to
    ) external lock {
        require(
            amount0Out == 0 || amount1Out == 0,
            "PhantasySwapV1: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint _reserve0, uint _reserve1) = getReserves();
        if (amount0Out < _reserve0 && amount1Out < _reserve1) {
            uint balance0;
            uint balance1;
            {
                address _token0 = token0;
                address _token1 = token1;
                require(
                    to != _token0 && to != _token1,
                    "PhantasySwapV1: INVALID_TO"
                );
                if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
                if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
                balance0 = IERC20(_token0).balanceOf(address(this));
                balance1 = IERC20(_token1).balanceOf(address(this));
            }
            uint amount0In = balance0 > _reserve0 - amount0Out
                ? balance0 - (_reserve0 - amount0Out)
                : 0;
            uint amount1In = balance1 > _reserve1 - amount1Out
                ? balance1 - (_reserve1 - amount1Out)
                : 0;
            require(
                amount0In > 0 || amount1In > 0,
                "PhantasySwapV1: INSUFFICIENT_INPUT_AMOUNT"
            );

            {
                {
                    // scope for reserve{0,1}Adjusted, avoids stack too deep errors
                    uint balance0Adjusted = balance0 * 1000 - (amount0In * 3);
                    uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
                    require(
                        balance0Adjusted * balance1Adjusted >=
                            uint(_reserve0) * (_reserve1) * (1000**2),
                        "PhantasySwapV1: K"
                    );
                }
                _update(balance0, balance1);
            }
        } else {
            revert INSUFFICIENT_LIQUIDITY();
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
