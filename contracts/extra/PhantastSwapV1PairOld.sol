// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IERC20.sol";

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
            IERC20(tokenOut).transfer(msg.sender, amountOut);
            _update(
                IERC20(token0).balanceOf(address(this)),
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    /**
     * @notice "ADDLIQUIDITY" lets you add liquidity to the pool.
     * @param _amount0, amount of token0 tokens into the pool.
     * @param _amount1, amount of token1 tokens into the pool.
     * @custom:visibility external.
     * @dev The math to this function has been explained below.
     */

    /// @notice Two math eqs in the addLiquidity - ratio of dy and dx and shares to mint.

    /*
        How many dy and dx to add.      
        xy = k
        (x+dx)(y+dy) = k`
        since the prices won't be changing after adding the liqudity, we get,   
        x / y = (x + dx) / (y + dy)
        solving this equation, we will get,
        x / y = dx / dy
        Therefore, dy = ( y * dx ) / x
        here, x = token0, y = token1, dx = amount0In, dy = amount1In
     */

    /*
        How many shares to mint?
        
        CPAMM: XY = K.
        Totalnumber of shares: T.
        New shares to mint: S.
        L0 = Existing liquidity.
        L1 = New liquidity.

        As CPAMM is a homogeneous and quardatic equation, in case, when a user doubles the liquidity,
        the product will become 4 times.

        So to solve this, we will using sqrt(k) to keep the liqiudity near to the real value.

        f(x,y) = L0 = sqrt(XY).
        f(x+dx, y+dy) = L1 = sqrt(x+dx, y+dy)

        -----

        Since the total shares increase proportionally to the liquidty that add, the ratios would be equal.

        L1 / L0 = ( T + S ) / T

        sqrt(x + dx * y + dy) / sqrt(x * y) = (T + S) / T

        ...

        S / T = sqrt(1 + 2(dx / x) + (dx/x) ^ 2 ) - 1 or sqrt (1 + 2(dy / y) + (dy/y)^2)) - 1

        It is in (a+b) ^ 2 formate. So we can cancel the root with the square and the final result will be.

        S / T = (dx / x) or ( dy / y )

        S = (dx / x) * T or (dy / y) * T
     */

    function addLiquidity(uint _amount0, uint _amount1)
        external
        returns (uint shares)
    {
        IERC20(token0).transferFrom(msg.sender, address(this), _amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), _amount1);

        (reserve0, reserve1) = getReserves(); // Getting reserves from the function to save gas.

        // Checking the liquidity ratio.
        if (reserve0 > 0 || reserve1 > 0) {
            require(
                reserve0 * _amount1 == reserve1 * _amount0,
                "x / y != dx / dy"
            );
        }

        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );
        }

        // Liquidity reserves
        require(shares > 0, "PHANTASYSWAP: SHARES = 0");

        _mint(msg.sender, shares);

        // Updating the reserves.
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    /**
     * @notice "REMOVE LIQUIDITY" lets you add liquidity to the pool.
     * @param _shares, amount of shares the user account holds.
     * @return _amount0Out returns the amount of tokenA deducted
     * @return _amount1Out returns the amount of tokenB deducted
     * @custom:visibility external.
     * @dev The math to this function has been explained below.
     */

    /*
        Let us say, the removing liquidity(a) = sqrt(dxdy)
        The Liquidity(L) = sqrt(xy)
        T =  Total shares.
        s = No.of shares to burn. 
        The ratio of liquidity is proportional to ratio of shares.

        a / L = S / T

        sqrt(dxdy) / sqrt(xy) = S / T

        sqrt(dxdy/xy) = S / T

        since dx/x = dy/y

        case 1,

        replace dy/y = dx/x

        we will get, dx = x(S / T)

        In case 2,

        replace dx/x = dy/y

        in this case we will get, dy = y(S / T)
     */

    function removeLiquidity(uint _shares)
        external
        returns (uint _amount0Out, uint _amount1Out)
    {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        _amount0Out = (_shares * balance0) / totalSupply;
        _amount1Out = (_shares * balance1) / totalSupply;
        require(
            _amount0Out > 0 && _amount1Out > 0,
            "_amount0Out or _amount1Out = 0"
        );

        _burn(msg.sender, _shares);
        _update(balance0 - _amount0Out, balance1 - _amount1Out);

        IERC20(token0).transfer(msg.sender, _amount0Out);
        IERC20(token1).transfer(msg.sender, _amount1Out);
    }
}
