// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

library LibRandom {
  /**
    * @dev Generate random numbers.
    *
    * @param _seed The seed.
    * @param _count The number of random numbers to generate.
    *
   */
  function generateRandomNumbers(uint256 _seed, uint256 max, uint256 _count) internal view returns (uint256[] memory) {
    uint256[] memory numbers = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      _seed = uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.timestamp,
        _seed
      )));

      numbers[i] = _seed % max;
    }
    return numbers;
  }
}
