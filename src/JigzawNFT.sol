// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Auth } from "./Auth.sol";
import { ERC721 } from "./ERC721.sol";
import { IERC165 } from "openzeppelin/interfaces/IERC165.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { ERC2981 } from "openzeppelin/token/common/ERC2981.sol";
import { IERC4906 } from "openzeppelin/interfaces/IERC4906.sol";
import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { LibErrors } from "./LibErrors.sol";
import { IPoolNFT } from "./IPoolNFT.sol";

contract JigzawNFT is Auth, ERC721, ERC2981, IERC4906, Ownable, IPoolNFT {
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
   * @dev Default token image as a data URI.
   */
  string public defaultImage;

  /**
   * @dev Token metadata.
   */
  mapping(uint256 => string) tokenMetadata;

  // Constructor

  /**
   * @dev Configuration parameters for constructor.
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
  
  /**
   * @dev Constructor.
   */
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

  // Approvals

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address spender) public view override(ERC721, IERC721) returns (bool) {
    return (spender == pool || ERC721.isApprovedForAll(owner, spender));
  }

  // Interface

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, IERC165) returns (bool) {
    return ERC721.supportsInterface(interfaceId)
      || ERC2981.supportsInterface(interfaceId);
  }

  // Metadata

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      _requireOwned(tokenId);

      if (bytes(tokenMetadata[tokenId]).length > 0) {
        return tokenMetadata[tokenId];
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
  function reveal(uint256[] calldata _tokenIds, string[] calldata _tokenURIs, Auth.Signature calldata _sig) external {
    _assertValidSignature(msg.sender, revealer, _sig, abi.encodePacked(_tokenIds));

    uint id;
    string memory uri;

    if (_tokenIds.length == 0) {
      revert LibErrors.InvalidTokenList();
    }

    if (_tokenIds.length != _tokenURIs.length) {
      revert LibErrors.InvalidBatchLengths(_tokenIds.length, _tokenURIs.length);
    }

    for (uint i = 0; i < _tokenIds.length; i++) {
      id = _tokenIds[i];
      uri = _tokenURIs[i];

      _requireOwned(id);

      if (bytes(tokenMetadata[id]).length > 0) {
        revert LibErrors.AlreadyRevealed(id);
      }

      tokenMetadata[id] = uri;
    }

    // IERC4906
    emit BatchMetadataUpdate(_tokenIds[0], _tokenIds[_tokenIds.length - 1]);
  }

  // Functions - set default image

  /**
   * @dev Set the default token image.
   */
  function setDefaultImage(string calldata _defaultImage) external onlyOwner {
    defaultImage = _defaultImage;
    
    // IERC4906
    emit BatchMetadataUpdate(1, totalSupply);
  }

  // Functions - set pool

  /**
   * @dev Set the pool.
   * @param _pool The address of the new pool.
   */
  function setPool(address _pool) external onlyOwner {
    pool = _pool;
  }

  // Set royalty

  /**
   * @dev Set the royalty receiver and fee.
   */
  function setRoyaltyFee(address _receiver, uint96 _feeBips) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeBips);
  }

  // Minting

  /**
   * @dev Set the minter.
   * @param _minter The address of the new minter.
   */
  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }

  /**
   * @dev Mint a token, callable by anyone but authorized by the minter.
   *
   * @param _to The address which will own the minted token.
   * @param _id token id to mint.
   * @param _uri token uri.
   * @param _sig minter authorisation signature.
   */
  function mint(address _to, uint256 _id, string calldata _uri, Signature calldata _sig) external {
    _assertValidSignature(msg.sender, minter, _sig, abi.encodePacked(_to, _id, _uri));
    _safeMint(_to, _id, "");
    if (bytes(_uri).length > 0) {
      tokenMetadata[_id] = _uri;
    }
  }


  // Pool functions 

  /**
   * @dev See {IPoolNFT-getRoyaltyInfo}.
   */
  function getRoyaltyInfo() external view override returns (address receiver, uint256 feeBips) {
    /* will cancel out fee denomination divisor so that we get back the bips */
    (receiver, feeBips) = royaltyInfo(1, _feeDenominator());
  }

  /**
   * @dev See {IPoolNFT-batchMint}.
   */
  function batchMint(address _to, uint _startId, uint _count) external override onlyPool {
    _safeBatchMint(_to, _startId, _count, "");
  }

  /**
   * @dev See {IPoolNFT-batchTransferTokenIds}.
   */
  function batchTransferTokenIds(address _from, address _to, uint[] calldata _tokenIds) external override {
    // for (uint i = 0; i < _tokenIds.length; i++) {
    //   _safeTransfer(_from, _to, _tokenIds[i], "");
    // }
  }

  /**
    * @dev See {IPoolNFT-batchTransferNumTokens}.
    */
  function batchTransferNumTokens(address _from, address _to, uint _numTokens) external override {
    // if (balanceOf(_from) < _numTokens) {
    //   revert LibErrors.InsufficientBalance(_from, _numTokens, balanceOf(_from));
    // }

    // for (uint i = 0; i < _numTokens; i++) {
    //   _safeTransfer(_from, _to, tokenOfOwnerByIndex(_from, i), "");
    // }
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
}
