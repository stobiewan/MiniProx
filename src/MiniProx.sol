// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract MiniProx {
    address internal immutable auth;

    constructor() {
        auth = msg.sender;
    }

    receive() external payable {}

    function execute(address _target, bytes calldata _data) external payable {
        require(msg.sender == auth);
        (bool success,) = _target.delegatecall(_data);
        require(success);
    }
}
