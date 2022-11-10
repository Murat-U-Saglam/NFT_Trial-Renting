// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {characterNFT} from "../src/Distributor.sol";
import {Utilities} from "./utils/Utilities.sol";

contract DistributorTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    function setUp() public {
        // User 0 is the owner of the contract/Distributor
        // User 1 is new user
        // User 2 is experienced user
        // User 3 is premium user
        utils = new Utilities();
        users = utils.createUsers(4);
        owner = users[0];
        noob = users[1];
        experienced = users[2];
        premium = users[3];
        vm.label(owner, "Owner");
        vm.label(noob, "Noob User");
        vm.label(experienced, "Experienced User");
        vm.label(premium, "Premium User");
    }

    function testFailMintMultipleTrialNFTs() public {
        characterNFT nft = new characterNFT();
        nft.trialNFTMint(1, 1, "");
        nft.trialNFTMint(1, 1, "");
    }
}
