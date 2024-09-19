// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/MiniProx.sol";

contract Creds {
    mapping(address => uint256) public creds;

    constructor (address sir) {
        creds[sir] = 1e6;
    }

    function give(address friend, uint256 size) external {
        creds[msg.sender] -= size;
        creds[friend]     += size;
    }
}

contract Script {
    function withdraw(uint256 amount) external {
        payable(msg.sender).transfer(amount);
    }

    function giveCreds(Creds creds, address friend, uint256 size) external {
        creds.give(friend, size);
    }
}

contract MiniProxTest is Test {
    MiniProx public prox;
    Creds    public creds;
    Script   public script;
    address  public owner;
    address  public cheat;

    function setUp() public {
        owner = vm.addr(1);
        cheat = vm.addr(2);
        creds = new Creds(owner);
        script = new Script();

        vm.startPrank(owner);
        prox = new MiniProx();

        vm.deal(owner, 10 ether);
        payable(prox).transfer(1 ether);
        assertEq(address(prox).balance, 1 ether);

        creds.give(address(prox), 500_000);
        vm.stopPrank();
    }

    function test_ownerCanFundAndRetrieveCreds() public {
        vm.startPrank(owner);
        bytes memory data = abi.encodeWithSelector(Script.giveCreds.selector, creds, owner, 500_000);
        prox.execute(address(script), data);

        assertEq(creds.creds(address(prox)), 0);
        assertEq(creds.creds(owner), 1e6);
        vm.stopPrank();
    }

    function testCheatCanNotStealCreds() public {
        vm.startPrank(cheat);
        bytes memory data = abi.encodeWithSelector(Script.giveCreds.selector, creds, cheat, 500_000);
        vm.expectRevert();
        prox.execute(address(script), data);

        assertEq(creds.creds(address(prox)), 500_000);
        assertEq(creds.creds(cheat), 0);
        vm.stopPrank();
    }

    function test_ownerCanFundAndRetrieveEther() public {
        vm.startPrank(owner);
        uint256 initialBalance = owner.balance;
        bytes memory data = abi.encodeWithSelector(Script.withdraw.selector, 1 ether);
        prox.execute(address(script), data);

        assertEq(address(prox).balance, 0);
        assertEq(owner.balance, initialBalance + 1 ether);
        vm.stopPrank();
    }

    function testCheatCanNotStealEther() public {
        vm.startPrank(cheat);
        uint cb0 = cheat.balance;
        bytes memory data = abi.encodeWithSelector(Script.withdraw.selector, 1 ether);
        vm.expectRevert();
        prox.execute(address(script), data);

        assertEq(address(prox).balance, 1 ether);
        uint cb1 = cheat.balance;
        assertEq(cb0, cb1);
        vm.stopPrank();
    }
}