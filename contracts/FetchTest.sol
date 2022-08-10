// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fetch} from "./Fetch.sol";

contract FetchTest {
    Fetch immutable fetch;
    uint256 immutable value;

    event Fetched(uint32 domain, address target);
    event Received(uint256 value);

    constructor(address _fetch, uint256 _value) {
        fetch = Fetch(_fetch);
        value = _value;
    }

    modifier onlyFetch() {
        require(msg.sender == address(fetch));
        _;
    }

    function sendFetch(uint32 destination, address target) external {
        fetch.fetch(
            destination,
            target,
            bytes4(this.receiveFetch.selector),
            abi.encodeCall(this.getValue, ())
        );
        emit Fetched(destination, target);
    }

    function receiveFetch(bytes calldata result) onlyFetch external {
        emit Received(abi.decode(result, (uint256)));
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}