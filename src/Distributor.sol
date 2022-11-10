    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract characterNFT is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {
    uint8 public level = 0;

    struct accessLevel {
        bool isExperiencedUser;
        bool isPremiumUser;
    }

    mapping(address => accessLevel) public levelOfAccess;

    event NFTIsMinted(address indexed account, string message);
    event trialNFTIsMinted(address indexed account, string message);
    event Attest(address indexed to, uint256 indexed tokenId);

    constructor() ERC1155("http://127.0.0.1:5500/api/characterNFT/{id}.json") {}

    function mint(address distributorAddress, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        // msg.sender is the caller of the function but the distributor is the owner of the contract
        _mint(distributorAddress, id, amount, data);
        emit NFTIsMinted(msg.sender, "NFT is minted");
    }
    // Group minting

    function resetToNewUser(address accountToReset) public onlyOwner {
        levelOfAccess[accountToReset].isExperiencedUser = false;
    }

    function trialNFTMint(uint256 id, uint256 amount, bytes memory data) public onlyNewUser {
        _mint(msg.sender, id, amount, data);
        emit trialNFTIsMinted(msg.sender, "Trial NFT is minted");
    }

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

    function makePremium(address userToMakePremium) external isExperiencedToPremium onlyOwner {}

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 amount) public onlyOwner {
        _burn(account, id, amount);
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
