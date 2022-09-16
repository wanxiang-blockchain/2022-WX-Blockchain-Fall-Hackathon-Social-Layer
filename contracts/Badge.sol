// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./Org.sol";


contract Badge is ERC721Upgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    struct Record {
        address issuer;
        address receiver;
        uint256 template;
        uint256 subject;
        uint256 org;
    }

    address ORG_ADDR;

    mapping(uint256 => Record) internal records;

    function initialize(address orgAddr) public initializer {
        ERC721Upgradeable.__ERC721_init("Badge", "Badge");
        OwnableUpgradeable.__Ownable_init();

        ORG_ADDR = orgAddr;
    }

    function mint(address receiver, address issuer, uint256 template, uint256 subject, uint256 orgId) public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        records[tokenId].issuer = issuer;
        records[tokenId].receiver = receiver;
        records[tokenId].template = template;
        records[tokenId].subject = subject;
        _mint(receiver, tokenId);

        if (orgId != 0x0) {
            require(Org(ORG_ADDR).isApprovedOrOwner(_msgSender(), orgId), "not owner or approved of org");
            records[tokenId].org = orgId;
            // emit org, tokenId
        }
    }
}
