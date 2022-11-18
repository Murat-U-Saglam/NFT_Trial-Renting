    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@chainlink-brownie-contracts/AutomationCompatibleInterface.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract characterNFT is ERC1155, ERC1155Burnable, Ownable, AutomationCompatibleInterface, ERC1155Supply {
    uint256 public currentDate = block.timestamp;
    uint256 public mintDate4NFT;
    uint256 public timeTillExpire = 7 days;
    uint256 public expireDate = mintDate4NFT + timeTillExpire;

    uint256 public constant TRIALNFTID = 0;

    struct accessLevel {
        bool isExperiencedUser;
        bool isPremiumUser;
    }

    mapping(address => accessLevel) public levelOfAccess;

    event NFTIsMinted(address indexed account, string message);
    event trialNFTIsMinted(address indexed account, string message);
    event Attest(address indexed to, uint256 indexed tokenId);

    constructor() ERC1155("http://127.0.0.1:5500/api/characterNFT/{id}.json") {}

    function trialNFTMint(uint256 amount, bytes memory data) public onlyNewUser {
        _mint(msg.sender, TRIALNFTID, amount, data);
        mintDate4NFT = block.timestamp;
        emit trialNFTIsMinted(msg.sender, "Trial NFT is minted");
    }

    function mint(address addressToMint, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        // msg.sender is the caller of the function but the distributor is the owner of the contract
        _mint(addressToMint, id, amount, data);
        emit NFTIsMinted(msg.sender, "NFT is minted");
    }

    function checkUpkeep(bytes memory) public override returns (bool needsUpkeep, bytes memory) {
        bool timePassed = (expireDate >= currentDate);
        needsUpkeep = (timePassed);
    }

    //burns token once condition is met
    function performUpkeep(bytes calldata) external override {
        (bool needsUpkeep,) = checkUpkeep("");
        require(needsUpkeep == true, "Upkeep not needed.");
        _burn(msg.sender, TRIALNFTID, 1);
    }

    function GSNSetup(address trustedForwarder) public onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    //testing purposes
    function resetToNewUser(address accountToReset) public onlyOwner {
        levelOfAccess[accountToReset].isExperiencedUser = false;
    }

    function makePremium(address userToMakePremium) external isExperiencedToPremium(userToMakePremium) onlyOwner {}

    modifier onlyNewUser() {
        require(levelOfAccess[msg.sender].isExperiencedUser == false, "Not a new user");
        _;
        levelOfAccess[msg.sender].isExperiencedUser = true;
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
        if (levelOfAccess[msg.sender].isPremiumUser == false) {
            require(from == address(0), "This token can only be minted, Please upgrade to make it transferable"); // Require it to be minted
        }
    }

    function _afterTokenTransfer(address from, address to, uint256[] memory ids) internal virtual {
        if (from == address(0) && levelOfAccess[msg.sender].isPremiumUser == false) {
            emit Attest(to, ids[0]);
        }
    }
}
