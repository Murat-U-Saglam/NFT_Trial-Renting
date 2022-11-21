// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {characterNFT} from "../src/Distributor.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";

contract DistributorTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    event stringAddress(string description, address adr);

    Utilities internal utils;
    address payable[] internal users;
    characterNFT nft;
    address owner;
    address noob;
    address experienced;
    MinimalForwarder forwarder;
    address premium;
    //address public forwarder = 0x7A95fA73250dc53556d264522150A940d4C50238;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(4);
        nft = new characterNFT(forwarder);
        owner = users[0]; // User 0 is the owner of the contract/Distributor
        noob = users[1]; // User 1 is new user
        experienced = users[2]; // User 2 is experienced user
        premium = users[3]; // User 3 is premium user

        vm.label(owner, "Owner");
        vm.label(noob, "Noob User");
        vm.label(experienced, "Experienced User");
        vm.label(premium, "Premium User");

        emit stringAddress("Owner Address", owner);
        vm.prank(owner);
        nft.owner();
    }

    function testFailMintMultipleTrialNFTs() public {
        console.log("owner's adress is: ", owner);
        console.log(nft.owner());
        nft.trialNFTMint(1, "");
        nft.trialNFTMint(1, "");
    }

    function testFailMintAsNonUser(uint256 id, uint256 amount) public {
        for (uint256 i = 1; i < 4; i++) {
            vm.prank(users[i]);
            nft.mint(users[i], id, amount, "0x11");
        }
    }

    function testFailTakeOwnership() public {
        for (uint256 i = 1; i < 4; i++) {
            vm.prank(users[i]);
        }
    }
}
