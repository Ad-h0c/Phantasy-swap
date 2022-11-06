# Phantasy Swap 

This project demonstrates the fully functional and tested AMM smart contracts.

## What is AMM?

You could think of an automated market maker as a robot that’s always willing to quote you a price between two assets. Some use a simple formula like Uniswap, while Curve, Balancer and others use more complicated ones.

Not only can you trade trustlessly using an AMM, but you can also become the house by providing liquidity to a liquidity pool. This allows essentially anyone to become a market maker on an exchange and earn fees for providing liquidity.

AMMs have really carved out their niche in the DeFi space due to how simple and easy they are to use. Decentralizing market making this way is intrinsic to the vision of crypto.

[Source](https://academy.binance.com/en/articles/what-is-an-automated-market-maker-amm).

<hr>

Above definition explains what an AMM is and the benefits of it. However, the application is composed of quite sensitive and complex smart contract which went through a lot of real-time checks.

The AMM I have written is based on my understanding of how it works and quite basic.

Why is it basic? Because it is for newbie developers who are trying to understand how AMM works in code wise.

In the code above, mainly there are four contracts.

- ERC20 smart contract
- Pair contract
- Factory contract
- Router contract.

While the first smart contract is commmon crypto token that is unique to the phantasy app, the pair contract is where the core functions of the application resides. Also where the funds stays.

Then the factory contract is to create multiple pairs which can be called by anybody since there is no case such as only developer needs to create token pairs. Which is quite non-productive as well.

As for the Router contract, the main purpose of this contract is to communicate with the front end. And since neither core functions nor functions are resided here, it can be replaced easily in case there are any bugs.

## Getting Started

### Requirements


- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`

- [Nodejs](https://nodejs.org/en/)

  - You'll know you've installed nodejs right if you can run:

    - `node --version` and get an ouput like: `vx.x.x`

- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

  - You'll know you've installed npm right if you can run:

    - `npm --version` and get an output like: `x.x.x`


## Quickstart

### Clone the application to your local machine

Open the terminal and execute the commands below.

```
git clone https://github.com/Ad-h0c/Phantasy-swap.git
cd Phantasy-Swap
npm install
```

### Smart contract deploying order.

You can use the pre-written deploy.js files to deploy smart contracts to the blockchain. However, you may need to follow the order.

- ERC20(Optional)
- Pair(Optional)
- Factory(Mandatory)
- Route(Mandatory)

In the abvoe contracts, you should deploy factory before the route contract because the route contract constructor accepts factory contract address as a parameter.

And there are a lot of interfaces used to call functions, so it is better to deploy all before calling the individual functions in the contracts.
To fork the application to your git hub account click on the fork icon on upper right corner of the repository.

Enjoy!
