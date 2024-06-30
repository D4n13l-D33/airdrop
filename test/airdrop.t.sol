// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Airdrop, GAU} from "../src/airdrop.sol";

contract AirdropTest is Test {
    Airdrop public airdrop;
    GAU public GAUcoin;

    uint256 ownerPrivateKey = uint256(keccak256("ownerPrivateKey"));
    address owner = vm.addr(ownerPrivateKey);
    uint256 user1privatkey = uint256(keccak256("user1privatkey"));
    address user1 = vm.addr(user1privatkey);
    address user2 = makeAddr("2");
    address user3 = makeAddr("3");
    address user4 = makeAddr("4");
    address attacker = makeAddr("attacker");

    uint256 totalsupply = 10000;
    function setUp() public {
        GAUcoin = new GAU();
        vm.label(address(GAUcoin), "GAUCoin");
        airdrop = new Airdrop(address(GAUcoin), totalsupply, 11011);
        vm.label(address(airdrop), "Airdrop Contract");

        GAUcoin.mint(address(airdrop), totalsupply);

        vm.label(owner, "Owner");
        vm.label(user1, "User1");
    }

    function test_CannotRegisterMoreThanOnce() public {
        vm.prank(user1);
        airdrop.register();

        vm.prank(user1);
        vm.expectRevert();
        airdrop.register();
    }

    function test_claim() public {
        vm.prank(user1);
        airdrop.register();

        vm.prank(user2);
        airdrop.register();

        vm.prank(user3);
        airdrop.register();

        vm.prank(user4);
        airdrop.register();

        vm.startPrank(user1);
        airdrop.claim();
        //User1 should not be able to claim more than once
        vm.expectRevert();
        airdrop.claim();

    }

    function test_claimWithSig() public {
        vm.prank(user1);
        airdrop.register();

        vm.prank(user2);
        airdrop.register();

        vm.prank(user3);
        airdrop.register();

        vm.prank(user4);
        airdrop.register();

        
        bytes32 domainSeparator = airdrop.getDOMAIN_SEPARATOR();
        bytes32 hash = keccak256(abi.encode(keccak256("claimWithSignature(address to)"), user1));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1privatkey, digest);

        vm.prank(owner);
        airdrop.claimWithSignature(user1, v, r, s);

        assertEq(GAUcoin.balanceOf(user1), totalsupply/4);

        //Should not be able to claim twice for same user
        vm.startPrank(owner);
        vm.expectRevert();
        airdrop.claimWithSignature(user1, v, r, s);

        //A signature shouldn't be used to sign for another user

        vm.expectRevert();
        airdrop.claimWithSignature(user2, v, r, s);

    }

    function test_Attack() public {
        vm.prank(user1);
        airdrop.register();

        vm.prank(user2);
        airdrop.register();

        vm.prank(user3);
        airdrop.register();

        vm.prank(user4);
        airdrop.register();

        
        bytes32 domainSeparator = airdrop.getDOMAIN_SEPARATOR();
        bytes32 hash = keccak256(abi.encode(keccak256("claimWithSignature(address to)"), user1));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1privatkey, digest);

        vm.prank(owner);
        airdrop.claimWithSignature(user1, v, r, s);

        assertEq(GAUcoin.balanceOf(user1), totalsupply/4);

        //Should not be able to claim twice for same user
        vm.startPrank(owner);
        vm.expectRevert();
        airdrop.claimWithSignature(user1, v, r, s);

        //A signature shouldn't be used to sign for another user
        (uint8 modV, bytes32 modR, bytes32 modS) = modSig(v,r,s);
        airdrop.claimWithSignature(user1, modV, modR, modS);
        assertEq(GAUcoin.balanceOf(user1), 2*(totalsupply/4));

    }

    

    function modSig(uint8 v, bytes32 r, bytes32 s) public pure returns (uint8 manipulatedV, bytes32 modR, bytes32 manipulatedS) {
        manipulatedV = v % 2 == 0 ? v - 1 : v + 1;
        uint256 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        modR = r;
        manipulatedS =  bytes32(n - uint256(s));       
    }


}
