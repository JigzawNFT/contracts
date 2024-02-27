// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC2309 } from "openzeppelin/interfaces/IERC2309.sol";
import { IERC721Enumerable } from "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import { IERC721Errors } from "./IERC721Errors.sol";

/*
  Custom ERC721 contract for Jigzaw NFT.

  Based on ERC721.sol from https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol
  @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)

  Improvements:
  - `isApprovedForAll` can be overridden.
  - Batch minting and transfers.
*/
abstract contract ERC721 is IERC721, IERC721Errors, IERC721Enumerable {  
  // constructor

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  // metadata

  string public name;
  string public symbol;
  function tokenURI(uint256 id) public view virtual returns (string memory);

  // balance/owner

  mapping(uint256 => address) internal _ownerOf;
  mapping(address => uint256) internal _balanceOf;

  function ownerOf(uint256 id) public view virtual returns (address owner) {
    owner = _ownerOf[id];
    if (owner == address(0)) {
      revert ERC721TokenNotMinted(id);
    }
  }

  function _requireOwned(uint256 id) internal view virtual {
    ownerOf(id);
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    if (owner == address(0)) {
      revert ERC721ZeroAddress();
    }
    return _balanceOf[owner];
  }

  // approvals

  mapping(uint256 => address) public getApproved;
  mapping(address => mapping(address => bool)) internal approvedForAll;

  function isApprovedForAll(address owner, address spender) public view virtual returns (bool) {
    return approvedForAll[owner][spender];
  }

  function approve(address spender, uint256 id) public virtual {
    address owner = _ownerOf[id];

    if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) {
      revert ERC721NotAuthorized(owner, msg.sender, id);
    }

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    approvedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  // IERC721Enumerable

  uint256 public totalSupply;
  mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
  mapping(uint256 => uint256) public tokenByIndex;
  /** The index at which a token is is stored in the `tokenOfOwnerByIndex` mapping. */
  mapping(uint256 => uint256) internal _ownedTokenIndex;
  /** The index at which a token is stored in the `tokenByIndex` mapping. */
  mapping(uint256 => uint256) internal _tokenIndex;

  // single transfers

  function transferFrom(address from, address to, uint256 id) public virtual {
    if (from != _ownerOf[id]) {
      revert ERC721InvalidOwner(from, id);
    }

    if (to == address(0)) {
      revert ERC721ZeroAddress();
    }

    bool approved = (
      msg.sender == from ||
        isApprovedForAll(from, msg.sender) ||
        msg.sender == getApproved[id]
    );
    if (!approved) {
      revert ERC721NotAuthorized(from, msg.sender, id);
    }
    
    // update enumeration
    {
      // remove from source
      uint256 index = _ownedTokenIndex[id];
      // if not the last one then we need to replace it with last one
      if (index < _balanceOf[from] - 1) {
        uint256 lastToken = tokenOfOwnerByIndex[from][_balanceOf[from] - 1];
        tokenOfOwnerByIndex[from][index] = lastToken;
        _ownedTokenIndex[lastToken] = index;
        delete tokenOfOwnerByIndex[from][_balanceOf[from] - 1];
      } else {
        // else we can just delete it
        delete tokenOfOwnerByIndex[from][index];
      }

      // add to destination
      tokenOfOwnerByIndex[to][_balanceOf[to]] = id;
      _ownedTokenIndex[id] = _balanceOf[to];
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      _balanceOf[from]--;

      _balanceOf[to]++;
    }

    _ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    transferFrom(from, to, id);
    _informRecipient(msg.sender, from, to, id, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) public virtual {
    transferFrom(from, to, id);
    _informRecipient(msg.sender, from, to, id, data);
  }

  // erc165

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
      interfaceId == type(IERC721Enumerable).interfaceId;
  }

  // mint/burn

  /**
    * @dev Batch mint a range of tokens to the address.
    */
  function _safeBatchMintRange(address _to, uint256 _startId, uint256 _count) internal virtual {
    if (_to == address(0)) {
      revert ERC721ZeroAddress();
    }

    if (_count == 0) {
      revert ERC721InvalidBatchSize(0);
    }

    while (_count > 0) {
      _mint(_to, _startId);
      _informRecipient(msg.sender, address(0), _to, _startId, "");
      _startId++;
      _count--;
    }
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    if (to == address(0)) {
      revert ERC721ZeroAddress();
    }

    _mint(to, id);
    _informRecipient(msg.sender, address(0), to, id, data);
  }

  function _mint(address to, uint256 id) internal virtual {
    if (_ownerOf[id] != address(0)) {
      revert ERC721TokenAlreadyMinted(id);
    }

    // update enumeration
    {
      tokenByIndex[totalSupply] = id;
      _tokenIndex[id] = totalSupply;

      tokenOfOwnerByIndex[to][_balanceOf[to]] = id;
      _ownedTokenIndex[id] = _balanceOf[to];

      totalSupply++;
    }

    // Counter overflow is incredibly unrealistic.
    unchecked {
      _balanceOf[to]++;
    }

    _ownerOf[id] = to;
    
    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = _ownerOf[id];

    if (owner == address(0)) {
      revert ERC721TokenNotMinted(id);
    }

    // update enumeration
    {
      uint256 index = _tokenIndex[id];
      // if not the last one then we need to replace it with last one
      if (index < totalSupply - 1) {
        uint256 lastToken = tokenByIndex[totalSupply - 1];
        tokenByIndex[index] = lastToken;
        _tokenIndex[lastToken] = index;
        delete tokenByIndex[totalSupply - 1];
      } else {
        // else we can just delete it
        delete tokenByIndex[index];
      }

      index = _ownedTokenIndex[id];
      // if not the last one then we need to replace it with last one
      if (index < _balanceOf[owner] - 1) {
        uint256 lastToken = tokenOfOwnerByIndex[owner][_balanceOf[owner] - 1];
        tokenOfOwnerByIndex[owner][index] = lastToken;
        _ownedTokenIndex[lastToken] = index;
        delete tokenOfOwnerByIndex[owner][_balanceOf[owner] - 1];
      } else {
        // else we can just delete it
        delete tokenOfOwnerByIndex[owner][index];
      }

      totalSupply--;
    }

    // Ownership check above ensures no underflow.
    unchecked {
      _balanceOf[owner]--;
    }

    delete _ownerOf[id];

    delete getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  // recipient notification

  function _informRecipient(
    address sender,
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    if (to.code.length > 0) {
      if (ERC721TokenReceiver(to).onERC721Received(
        sender, from, id, data
      ) != ERC721TokenReceiver.onERC721Received.selector) {
        revert ERC721UnsafeTokenReceiver(to, id);
      }
    }
  }  
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }
}


