// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { ERC721 } from "openzeppelin/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721URIStorage } from "openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Royalty } from "openzeppelin/token/ERC721/extensions/ERC721Royalty.sol";
import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { SignatureChecker } from "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { LibErrors } from "./LibErrors.sol";
import { Signature } from "./Structs.sol";
import { IMintable } from "./IMintable.sol";

contract JigzawNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty, Ownable, IMintable {
  using Strings for uint256;

  /**
   * @dev The pool contract.
   */
  address public pool;

  /**
   * @dev The minter can approve new token mints.
   */
  address public minter;

  /**
   * @dev The revealer can approve token reveals.
   */
  address public revealer;

  /**
   * @dev Default tile image as a data URI.
   */
  string public defaultImage;

  /**
   * @dev Whether tile has been revealed.
   */
  mapping(uint256 => bool) public revealed;

  /**
   * @dev Keep track of used signatures.
   */
  mapping(bytes32 => bool) public usedSignatures;

  // Constructor

  /**
   * @dev Configuration parameters.
   */
  struct Config {
    /** Owner. */
    address owner;
    /** Pool. */
    address pool;
    /** Minter. */
    address minter;
    /** Revealer. */
    address revealer;
    /** Royalty fee */
    uint96 royaltyFeeBips;
    /** Default token image as a data URI. */
    string defaultImage;
  }

  constructor(Config memory _config)
    ERC721("Jigzaw", "JIGZAW") 
    Ownable(_config.owner)
  {
    minter = _config.minter;
    revealer = _config.revealer;
    pool = _config.pool;
    defaultImage = _config.defaultImage;
    _setDefaultRoyalty(_config.owner, _config.royaltyFeeBips);
  }

  // Functions - necessary overrides

  function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
    return ERC721Enumerable._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
    ERC721Enumerable._increaseBalance(account, amount);
  }

  function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override returns (bool) {
    return (spender == pool || super._isAuthorized(owner, spender, tokenId));
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty, ERC721Enumerable, ERC721URIStorage) returns (bool) {
    return ERC721.supportsInterface(interfaceId)
      || ERC721URIStorage.supportsInterface(interfaceId)
      || ERC721Enumerable.supportsInterface(interfaceId)
      || ERC721Royalty.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
      _requireOwned(tokenId);

      if (revealed[tokenId]) {
        return ERC721URIStorage.tokenURI(tokenId);
      } else {
        string memory json = string(
          abi.encodePacked(
            '{',
                '"name": "Tile #', tokenId.toString(), '",',
                '"description": "Jigzaw unrevealed tile - see https://jigsaw.xyz for instructions.",',
                '"image": "', defaultImage, '"',
            '}'
          ) 
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
      }
  }

  // Functions - reveal token

  /**
   * @dev Set the revealer.
   * @param _revealer The address of the new revealer.
   */
  function setRevealer(address _revealer) external onlyOwner {
    revealer = _revealer;
  }

  /**
   * @dev Reveal tokens.
   *
   * @param _tokenIds The token ids.
   * @param _tokenURIs The new token URIs to set.
   * @param _sig The minter authorisation signature.
   */
  function reveal(uint256[] calldata _tokenIds, string[] calldata _tokenURIs, Signature calldata _sig) external {
    _assertValidSignature(revealer, _sig, abi.encodePacked(_tokenIds));

    for (uint i = 0; i < _tokenIds.length; i++) {
      uint256 id = _tokenIds[i];
      string memory uri = _tokenURIs[i];

      _requireOwned(id);

      if (revealed[id]) {
        revert LibErrors.AlreadyRevealed(id);
      }

      _setTokenURI(id, uri);

      revealed[id] = true;
    }
  }

  // Functions - set default tile image

  /**
   * @dev Set the default tile image.
   */
  function setDefaultImage(string calldata _defaultImage) external onlyOwner {
    defaultImage = _defaultImage;
  }

  // Functions - set pool

  /**
   * @dev Set the pool.
   * @param _pool The address of the new pool.
   */
  function setPool(address _pool) external onlyOwner {
    pool = _pool;
  }

  // Functions - set royalty

  /**
   * @dev Set the royalty receiver and fee.
   */
  function setRoyaltyFee(address _receiver, uint96 _feeBips) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeBips);
  }

  // Functions - minting

  /**
   * @dev Set the minter.
   * @param _minter The address of the new minter.
   */
  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }

  /**
   * @dev Mint tokens to the address, called by anyone.
   *
   * @param _to The address which will own the minted tokens.
   * @param _ids token ids to mint.
   * @param _sig minter authorisation signature.
   */
  function mint(address _to, uint[] calldata _ids, Signature calldata _sig) external {
    _assertValidSignature(minter, _sig, abi.encodePacked(_to, _ids));

    for(uint i = 0; i < _ids.length; i++) {
      _safeMint(_to, _ids[i]);
    }
  }

  /**
   * @dev Mint tokens to the address, called by the pool.
   *
   * @param _to The address which will own the minted tokens.
   * @param _startId The id to start mint from.
   * @param _count No. of tokens to mint.
   */
  function mint(address _to, uint _startId, uint _count) external onlyPool {
    uint _endId = _startId + _count;
    
    for(uint i = _startId; i <= _endId; i++) {
      _safeMint(_to, i);
    }
  }

  // Modifiers

  /**
   * @dev Only the pool can call this function.
   */
  modifier onlyPool() {
    if (_msgSender() != pool) {
      revert LibErrors.UnauthorizedMustBePool(_msgSender());
    }
    _;
  }

  // Internal

  /**
   * @dev Assert validity of given signature.
   */
  function _assertValidSignature(address _signer, Signature memory _sig, bytes memory _data) private {
    if(_sig.deadline < block.timestamp) {
      revert LibErrors.SignatureExpired(_msgSender()); 
    }

    bytes32 sigHash = keccak256(abi.encodePacked(_data, _sig.deadline));
    if (!SignatureChecker.isValidSignatureNow(_signer, sigHash, _sig.signature)) {
      revert LibErrors.SignatureInvalid(_msgSender());
    }

    if(usedSignatures[sigHash]) {
      revert LibErrors.SignatureAlreadyUsed(_msgSender());
    }

    usedSignatures[sigHash] = true;
  }
}
