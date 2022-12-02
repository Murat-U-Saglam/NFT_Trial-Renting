    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract characterNFT is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {
    uint256 public currentDate;
    uint256 public constant TRIALNFTID = 0;

    struct trialNFTInfo {
        uint256 mintDate4NFT;
        uint256 expireDate;
    }

    enum accountPrivellege {
        noob, // 0 default value
        experienced, // 1
        premium // 2
    }

    mapping(address => trialNFTInfo) public trialNFT;
    mapping(address => accountPrivellege) public levelOfAccess;

    event NFTIsMinted(address indexed account, string message);
    event trialNFTIsMinted(address indexed account, string message);
    event Attest(address indexed to, uint256 indexed tokenId);

    constructor() ERC1155("http://127.0.0.1:5500/api/characterNFT/{id}.json") {
        levelOfAccess[msg.sender] = accountPrivellege.premium;
    }

    function trialNFTMint() public onlyNewUser {
        uint256 timeTillExpire = 7 days;
        trialNFT[msg.sender].mintDate4NFT = block.timestamp;
        trialNFT[msg.sender].expireDate = trialNFT[msg.sender].mintDate4NFT + timeTillExpire;
        _mint(msg.sender, TRIALNFTID, 1, "0x11");
        emit trialNFTIsMinted(msg.sender, "Trial NFT is minted");
    }

    function checkUpkeep() public returns (bool needsUpkeep) {
        currentDate = block.timestamp;
        bool timePassed = (trialNFT[msg.sender].expireDate <= currentDate);
        needsUpkeep = (timePassed);
    }

    //burns token once condition is met
    function performUpkeep() external {
        (bool needsUpkeep) = checkUpkeep();
        require(needsUpkeep == true, "Upkeep not needed.");
        _burn(msg.sender, TRIALNFTID, 1);
    }

    //testing purposes
    function resetToNewUser(address accountToReset) public onlyOwner {
        levelOfAccess[accountToReset] = accountPrivellege.noob;
    }

    function makePremium(address userToMakePremium) external isExperiencedToPremium(userToMakePremium) onlyOwner {}

    modifier onlyNewUser() {
        require(
            levelOfAccess[_msgSender()] == accountPrivellege.noob,
            "You're not a new user, only a new user can mint a trial NFT"
        );
        _;
        levelOfAccess[_msgSender()] = accountPrivellege.experienced;
    }

    modifier isExperiencedToPremium(address userToMakePremium) {
        require(
            levelOfAccess[userToMakePremium] == accountPrivellege.experienced,
            "Not an experienced user, please mint a trial NFT before continuing"
        );
        _;
        levelOfAccess[userToMakePremium] = accountPrivellege.premium;
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
        if (levelOfAccess[_msgSender()] != accountPrivellege.premium) {
            require(
                from == address(0) || to == address(0),
                "This token can not be transferred, Please upgrade to make it transferable"
            ); // Require it to be minted
        }
    }

    function _afterTokenTransfer(address from, address to, uint256[] memory ids) internal virtual {
        if (from == address(0) && levelOfAccess[_msgSender()] != accountPrivellege.premium) {
            emit Attest(to, ids[0]);
        } else if (to == address(0) && levelOfAccess[_msgSender()] != accountPrivellege.premium) {
            emit Attest(from, ids[0]);
        }
    }
}
