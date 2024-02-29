![Build status](https://github.com/JigzawNFT/contracts/actions/workflows/ci.yml/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/JigzawNFT/contracts/badge.svg?t=wvNXqi)](https://coveralls.io/github/JigzawNFT/contracts)

# JigzawNFT contracts

Smart contracts for [JigzawNFT](https://jigzaw.xyz).

Features:

* **Fully on-chain metadata (including images)!**
* Minter, owner and revealer roles

Technicals:

* Built with Foundry
* OpenZepellin ERC721 + Enumerability + Storage
* ERC2981 royalty standard
* ERC4906 metadata updates
* ECDSA signature verification to allow for anyone to mint/reveal with authorisation

## On-chain addresses

_TODO: Live deployed addresses here_

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
