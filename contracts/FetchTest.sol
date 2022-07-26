// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fetch} from "./Fetch.sol";

contract FetchTest {
    Fetch immutable fetch;
    uint256 immutable value;

    event Fetched(uint32 domain, address target, bytes extra);
    event Received(uint32 domain, uint256 value, bytes extra);

    constructor(address _fetch, uint256 _value) {
        fetch = Fetch(_fetch);
        value = _value;
    }

    modifier onlyFetch() {
        require(msg.sender == address(fetch));
        _;
    }

    function send(uint32 destination, address target, bytes memory extra) external {
        bytes memory data = abi.encodeCall(this.value);
        fetch.fetch(destination, target, data, this.receive.selector, extra);
        emit Fetched(destination, target, extra);
    }

    function receive(uint32 origin, bytes memory result, bytes memory extra) onlyFetch external {
        uint256 value = abi.decode(result, (uint256));
        emit Received(origin, value, extra);
    }

    function value() external returns (uint256) {
        return this.value;
    }
}