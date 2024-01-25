# solcraft

**Modern**, **opinionated**, **gas optimized** foundational componentes for **EVM smart contract development**.
Most of the contracts should be upgradable by default.

## Contracts

```ml
└───utils
    │   ECDSA.sol
    │   FixedPointMathLib.sol
    │   Initializable.sol
    │   SafeCastLib.sol
    │   SafeTransferLib.sol
    │
    ├───cryptography
    │       EIP712.sol
    │
    └───proxy
            LibClone.sol
            UUPSUpgradeable.sol
```

## Safety

This is **experimental software** and is provided on an "as is" and "as available" basis.

- There are implicit invariants these contracts expect to hold.
- **You can easily shoot yourself in the foot if you're not careful.**
- You should thoroughly read each contract you plan to use top to bottom.

We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

## Installation

- TODO

## Notice

With the advancement of the EVM, some of these contracts will become obsolete. And we will update and deprecated them accordingly.


## Credits

None of these crates would have been possible without the great work done in:

- [Gnosis](https://github.com/gnosis/gp-v2-contracts)
- [Uniswap](https://github.com/Uniswap/uniswap-lib)
- [Dappsys](https://github.com/dapphub/dappsys)
- [Dappsys V2](https://github.com/dapp-org/dappsys-v2)
- [0xSequence](https://github.com/0xSequence)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [solmate](https://github.com/transmissions11/solmate/)
- [solady](https://github.com/Vectorized/solady)

#### License
This project is licensed under MIT.