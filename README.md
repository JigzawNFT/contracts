![Build status](https://github.com/JigzawNFT/contracts/actions/workflows/ci.yml/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/JigzawNFT/contracts/badge.svg?t=wvNXqi)](https://coveralls.io/github/JigzawNFT/contracts)

# JigzawNFT contracts

**NOTE: These contract are still a work-in-progress and subject to change.**

Smart contracts for [JigzawNFT](https://jigzaw.xyz).

Features:

* **Fully on-chain metadata (including images)!**
* `MintSwapPool` pool inspired by [SudoSwap](https://github.com/sudoswap/lssvm).
  * Exponential price curve.
  * Pool mints NFTs on-demand until no more left to mint. Initial buyers thus recieve minted freshly NFTs.
  * Sellers sell NFTs into pool, and subsequent buyers recieve these NFTs until they run out, after which the pool again mints new NFTs.
* To encourage holders to mint and reveal NFTs a lottery ticket system is implemented:
  * _x_% of every NFT trade goes into a lottery pot, accumulating over time.
  * Every permissioned mint will award 3 lottery tickets to the caller.
  * Every permissioned reveal will award 1 lottery ticket to the caller.
  * After all tiles have been minted and revealed the lottery will be drawn and _y_ random tickets will be selected as winners.
    * These winning tickets will then be able to withdraw their share of the lottery pot.
  * Notes:
    * Lottery tickets themselves are a separate ERC721 collection.
    * The lottery has a deadline _(TBD)_, after which the lottery can be drawn even if not all tiles have been minted and revealed. This is to handle the case where for some reason the puzzle can't be finished.

Technicals details:

* Built with Foundry.
* ERC721 (based on [Solmate](https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)) + Enumerability + Custom token URI.
* Batch transfers and mints.
* ERC2981 royalty standard.
* ERC4906 metadata updates.
* ECDSA signature verification to allow for anyone to mint/reveal with authorisation.
* Extensive [test suite](./test/) and [excellent code coverage](https://coveralls.io/github/JigzawNFT/contracts).

## On-chain addresses

Base mainnet:

* `JigzawNFT` - [0x2C98fe404CEb07218eE408E7311895A099550Fb1](https://basescan.org/address/0x2C98fe404CEb07218eE408E7311895A099550Fb1)
* `LotteryNFT` - [0x2afDCA75a879e109715F29965Ff52df90277Dc4D](https://basescan.org/address/0x2afDCA75a879e109715F29965Ff52df90277Dc4D)
* `MintSwapPool` - [0xeB90b427b91cb6235FAfce3CD628164c21EAcbb4](https://basescan.org/address/0xeB90b427b91cb6235FAfce3CD628164c21EAcbb4)

## Development

Install pre-requisites:

* [Foundry](https://book.getfoundry.sh/)
* [Bun](https://bun.sh/)

Then run:

```shell
$ bun i
$ bun prepare
```

To compile the contracts:

```shell
$ bun compile
```

To test:

```shell
$ bun tests
```

With coverage:

```shell
$ bun tests-coverage
```

To view the coverage report from the generated `lcov.info` file you will need to have [genhtml](https://command-not-found.com/genhtml) installed. Once this is done you can run:

```shell
$ bun view-coverage
```


## Deployment

_Notes:_

* _The `owner`, `minter`, `revealer` and `pool` roles are all set to be the deployment wallet's address._
* _[CREATE2](https://book.getfoundry.sh/tutorials/create2-tutorial) is used for deployment, so the address will always be the same as long as the deployment wallet and bytecode are the same, irrespective of chain, nonce, etc._

### Local (anvil)

To deploy locally, first run a local devnet:

```shell
$ bun devnet
```

Then run:

```shell
$ bun deploy-local
```

### Public (testnets, mainnets)

Set the following environment variables:

```shell
$ export PRIVATE_KEY="0x..."
$ export RPC_URL="http://..."
$ export CHAIN_ID="..."
```

Then run:

```shell
$ bun deploy-public
```

To verify contracts on Base:

```shell
$ bun basescan-verify
```

## License

AGPLv3 - see [LICENSE.md](LICENSE.md)

JigzawNFT smart contracts
Copyright (C) 2024  [Ramesh Nair](https://hiddentao.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
