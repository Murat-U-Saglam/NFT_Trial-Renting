    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@chainlink-brownie-contracts/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

contract characterNFT is
    ERC1155,
    ERC1155Burnable,
    Ownable,
    AutomationCompatibleInterface,
    ERC1155Supply,
    ERC2771Context
{
    uint256 public currentDate = block.timestamp;
    uint256 public constant TRIALNFTID = 0;

    struct trialNFTInfo {
        uint256 mintDate4NFT;
        uint256 expireDate;
    }

    struct accessLevel {
        bool isExperiencedUser;
        bool isPremiumUser;
    }

    mapping(address => trialNFTInfo) public trialNFT;
    mapping(address => accessLevel) public levelOfAccess;

    event NFTIsMinted(address indexed account, string message);
    event trialNFTIsMinted(address indexed account, string message);
    event Attest(address indexed to, uint256 indexed tokenId);

    constructor()
        ERC1155("http://127.0.0.1:5500/api/characterNFT/{id}.json")
        ERC2771Context(address(0x7A95fA73250dc53556d264522150A940d4C50238))
    {}

    function trialNFTMint(uint256 amount, bytes memory data) public onlyNewUser {
        uint256 timeTillExpire = 7 days;
        address user = _msgSender();
        trialNFT[user].mintDate4NFT = block.timestamp;
        trialNFT[user].expireDate = trialNFT[user].mintDate4NFT + timeTillExpire;
        _mint(user, TRIALNFTID, amount, data);
        emit trialNFTIsMinted(user, "Trial NFT is minted");
    }

    function mint(address addressToMint, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        // _msgSender() is the caller of the function but the distributor is the owner of the contract
        _mint(addressToMint, id, amount, data);
        address user = _msgSender();
        emit NFTIsMinted(user, "NFT is minted");
    }

    function checkUpkeep(bytes memory) public override returns (bool needsUpkeep, bytes memory) {
        address user = _msgSender();
        bool timePassed = (trialNFT[user].expireDate >= currentDate);
        needsUpkeep = (timePassed);
    }

    //burns token once condition is met
    function performUpkeep(bytes calldata) external override {
        (bool needsUpkeep,) = checkUpkeep("");
        require(needsUpkeep == true, "Upkeep not needed.");
        _burn(_msgSender(), TRIALNFTID, 1);
    }

    //testing purposes
    function resetToNewUser(address accountToReset) public onlyOwner {
        levelOfAccess[accountToReset].isExperiencedUser = false;
    }

    function makePremium(address userToMakePremium) external isExperiencedToPremium(userToMakePremium) onlyOwner {}

    modifier onlyNewUser() {
        require(levelOfAccess[_msgSender()].isExperiencedUser == false, "Not a new user");
        _;
        levelOfAccess[_msgSender()].isExperiencedUser = true;
    }

    modifier isExperiencedToPremium(address userToMakePremium) {
        require(
            levelOfAccess[userToMakePremium].isExperiencedUser == true
                && levelOfAccess[userToMakePremium].isPremiumUser == false,
            "Not an experienced user"
        );
        _;
        levelOfAccess[userToMakePremium].isPremiumUser = true;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (levelOfAccess[_msgSender()].isPremiumUser == false) {
            require(from == address(0), "This token can only be minted, Please upgrade to make it transferable"); // Require it to be minted
        }
    }

    function _afterTokenTransfer(address from, address to, uint256[] memory ids) internal virtual {
        if (from == address(0) && levelOfAccess[_msgSender()].isPremiumUser == false) {
            emit Attest(to, ids[0]);
        }
    }
}
