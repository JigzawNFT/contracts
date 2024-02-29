// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { SignatureChecker } from "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { LibErrors } from "./LibErrors.sol";

/**
 * @dev Auth contract.
 *
 * This contract provides ECDSA signature validation. Signatures have expiry deadlines and can only be used once.
 */
abstract contract Auth {
  struct Signature {
    /** Signature bytes. */
    bytes signature;
    /** Deadline (block timestamp) */
    uint256 deadline;
  }

  /**
   * @dev Keep track of used signatures.
   */
  mapping(bytes32 => bool) public usedSignatures;

  /**
   * @dev Assert validity of given signature.
   */
  function _assertValidSignature(address _caller, address _signer, Signature memory _sig, bytes memory _data) internal {
    if(_sig.deadline < block.timestamp) {
      revert LibErrors.SignatureExpired(_caller); 
    }

    bytes32 sigHash = keccak256(abi.encodePacked(_data, _sig.deadline));
    if (!SignatureChecker.isValidSignatureNow(_signer, sigHash, _sig.signature)) {
      revert LibErrors.SignatureInvalid(_caller);
    }

    if(usedSignatures[sigHash]) {
      revert LibErrors.SignatureAlreadyUsed(_caller);
    }

    usedSignatures[sigHash] = true;
  }
}