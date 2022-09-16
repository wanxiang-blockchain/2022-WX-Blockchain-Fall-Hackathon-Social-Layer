// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";


contract NameRegistry is ERC721Upgradeable, OwnableUpgradeable {

    event NewKey(string indexed keyIndex, string key);
    event Set(uint256 indexed tokenId, uint256 indexed keyHash, string value);
    event ResetRecords(uint256 indexed tokenId);
    event NameRegistered(address to, uint256 node, string name);
    event NewSubdomain(address to, uint256 tokenId, uint256 subtokenId, string name);

    uint256 public BASE_NODE;
    uint256 public MIN_REGISTRATION_LENGTH;

    function initialize(uint256 _baseNode) initializer public {
        ERC721Upgradeable.__ERC721_init("NameRegistry", "NameRegistry");
        OwnableUpgradeable.__Ownable_init();
        BASE_NODE = _baseNode;
        MIN_REGISTRATION_LENGTH = 3;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function exists(uint256 tokenId) public view virtual returns(bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://sola.day/name/";
    }

    function isApprovedOrOwner(address addr, uint256 tokenId) public view returns(bool) {
        return _isApprovedOrOwner(addr, tokenId);
    }
    
    modifier authorised(uint256 tokenId) {
        require(owner() == _msgSender() || _isApprovedOrOwner(_msgSender(), tokenId), "not owner nor approved");
        _;
    }

    function mint(address to, uint256 newTokenId) public virtual onlyOwner {
        _mint(to, newTokenId);
    }

    function mintSubdomain(address to, uint256 tokenId, string calldata name) public virtual returns (uint256) {
        // parent domain owner only
        bytes32 label = keccak256(bytes(name));
        bytes32 subnode = keccak256(abi.encodePacked(tokenId, label));
        uint256 subtokenId = uint256(subnode);
        _mint(to, subtokenId);

        emit NewSubdomain(to, tokenId, subtokenId, name);
        return subtokenId;
    }

    function burn(uint256 tokenId) public virtual authorised(tokenId) {
        _burn(tokenId);
    }

    function nameRegister(string calldata name, address to) public payable returns(uint256) {
        uint256 len = strlen(name);
        require(len >= MIN_REGISTRATION_LENGTH, "name too short");

        uint256 tokenId = mintSubdomain(to, BASE_NODE, name);

        emit NameRegistered(to, tokenId, name);

        return tokenId;
    }

    // records

    mapping(uint256 => string) private _keys;
    mapping(uint256 => mapping(uint256 => string)) internal _records;
    mapping(address => uint256) private _names;
    mapping(address => mapping(uint256 => uint256)) internal _nft_names;

    function getKey(uint256 keyHash) public view returns (string memory) {
        return _keys[keyHash];
    }

    function _existsKey(uint256 keyHash) internal view returns (bool) {
        return bytes(_keys[keyHash]).length > 0;
    }

    function _addKey(uint256 keyHash, string memory key) internal {
        if (!_existsKey(keyHash)) {
            _keys[keyHash] = key;
            emit NewKey(key, key);
        }
    }

    function addKeys(string[] memory keys) external {
        for (uint256 i = 0; i < keys.length; i++) {
            string memory key = keys[i];
            _addKey(uint256(keccak256(abi.encodePacked(key))), key);
        }
    }

    function get(string calldata key, uint256 tokenId) external view returns (string memory value) {
        value = _get(key, tokenId);
    }

    function _get(string calldata key, uint256 tokenId) private view returns (string memory) {
        return _get(uint256(keccak256(abi.encodePacked(key))), tokenId);
    }

    function _get(uint256 keyHash, uint256 tokenId) private view returns (string memory) {
        return _records[tokenId][keyHash];
    }

    function getMany(string[] calldata keys, uint256 tokenId) external view returns (string[] memory values) {
        values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _get(keys[i], tokenId);
        }
    }

    function getByHash(uint256 keyHash, uint256 tokenId)
        external
        view
       
        returns (string memory value)
    {
        value = _getByHash(keyHash, tokenId);
    }

    function _getByHash(uint256 keyHash, uint256 tokenId)
        private
        view
        returns (string memory value)
    {
        value = _get(keyHash, tokenId);
    }

    function getManyByHash(uint256[] calldata keyHashes, uint256 tokenId)
        external
        view
       
        returns (string[] memory values)
    {
        values = new string[](keyHashes.length);
        for (uint256 i = 0; i < keyHashes.length; i++) {
            values[i] = _getByHash(keyHashes[i], tokenId);
        }
    }

    function _set(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) private {
        _records[tokenId][keyHash] = value;
        emit Set(tokenId, keyHash, value);
    }

    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external authorised(tokenId) {
        require(_existsKey(keyHash), 'key not found');
        _set(keyHash, value, tokenId);
    }

    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external authorised(tokenId) {
        require(keyHashes.length == values.length, "invalid data");

        for (uint256 i = 0; i < keyHashes.length; i++) {
            require(_existsKey(keyHashes[i]), 'key not found');
            _set(keyHashes[i], values[i], tokenId);
        }
    }
}
