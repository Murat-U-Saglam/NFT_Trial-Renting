// SPDX-License-Identifier: MIT

/// @title NFT contract for easy onboarding SBT
/// @author Murat

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract characterNFT is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {
    uint256 public currentDate;
    uint256 public constant TRIALNFTID = 0;

    //@notice to store information regarding the NFT expiry information
    struct trialNFTInfo {
        uint256 mintDate4NFT;
        uint256 expireDate;
    }

    //@notice Stores access levels for each user
    enum accountPrivellege {
        noob, // Hasn't minted trial NFT yet
        experienced, // Minted trial NFT but is has not purechased a premium NFT
        premium // Has purchased a premium NFT
    }

    //@notice Stores the information regarding account holders
    mapping(address => trialNFTInfo) public trialNFT;
    mapping(address => accountPrivellege) public levelOfAccess;

    //@notice Events for logging
    event trialNFTIsMinted(address indexed account, string message);
    event Attest(address indexed to, uint256 indexed tokenId);

    //@dev Makes the owner also premium
    constructor() ERC1155("http://127.0.0.1:5500/api/characterNFT/{id}.json") {
        levelOfAccess[msg.sender] = accountPrivellege.premium;
    }

    //@notice to mint trial NFTs
    //@dev only for new users who have not minted trial NFTs yet
    function trialNFTMint() public onlyNewUser {
        uint256 timeTillExpire = 7 days;
        trialNFT[msg.sender].mintDate4NFT = block.timestamp;
        trialNFT[msg.sender].expireDate = trialNFT[msg.sender].mintDate4NFT + timeTillExpire;
        _mint(msg.sender, TRIALNFTID, 1, "0x11");
        emit trialNFTIsMinted(msg.sender, "Trial NFT is minted");
    }
    //@notice checks the conditions regarding an upkeeping
    //@dev Checks if the current date is pass the expiry date of the trial NFT

    function checkUpkeep() public returns (bool needsUpkeep) {
        currentDate = block.timestamp;
        bool timePassed = (trialNFT[msg.sender].expireDate <= currentDate);
        needsUpkeep = (timePassed);
    }

    //@notice burns token once condition is met
    function performUpkeep() external {
        (bool needsUpkeep) = checkUpkeep();
        require(needsUpkeep == true, "Upkeep not needed.");
        _burn(msg.sender, TRIALNFTID, 1);
    }

    //@notice Makes a user to an premium user
    //@dev Only for users who have purchased a premium NFT
    function makePremium(address userToMakePremium) external isExperiencedToPremium(userToMakePremium) onlyOwner {}

    //@notice checks if a user is a new user
    //@dev automatically updates the user to an experienced user once the trial NFT is minted
    modifier onlyNewUser() {
        require(
            levelOfAccess[_msgSender()] == accountPrivellege.noob,
            "You're not a new user, only a new user can mint a trial NFT"
        );
        _;
        levelOfAccess[_msgSender()] = accountPrivellege.experienced;
    }

    //@notice checks if a user is an experienced user
    //@dev automatically updates the user to an premium user
    modifier isExperiencedToPremium(address userToMakePremium) {
        require(
            levelOfAccess[userToMakePremium] == accountPrivellege.experienced,
            "Not an experienced user, please mint a trial NFT before continuing"
        );
        _;
        levelOfAccess[userToMakePremium] = accountPrivellege.premium;
    }

    //@dev to check conditions to maintain SBT behaviour
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

    //@dev to enfore the conditions to maintain SBT behaviour
    function _afterTokenTransfer(address from, address to, uint256[] memory ids) internal virtual {
        if (from == address(0) && levelOfAccess[_msgSender()] != accountPrivellege.premium) {
            emit Attest(to, ids[0]);
        } else if (to == address(0) && levelOfAccess[_msgSender()] != accountPrivellege.premium) {
            emit Attest(from, ids[0]);
        }
    }
}
