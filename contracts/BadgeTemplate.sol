// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";


contract BadgeTemplate is ERC721Upgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    function initialize() public initializer {
        ERC721Upgradeable.__ERC721_init("BadgeTemplate", "BadgeTemplate");
        OwnableUpgradeable.__Ownable_init();
    }

    function mint() public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(_msgSender(), tokenId);
    }
}
