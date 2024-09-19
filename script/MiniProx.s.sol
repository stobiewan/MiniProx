// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {MiniProx} from "../src/MiniProx.sol";

contract MiniProxScript is Script {
    MiniProx public prox;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        prox = new MiniProx();

        vm.stopBroadcast();
    }
}
