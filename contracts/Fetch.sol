// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "@abacus-network/app/contracts/Router.sol";

contract Fetch is Router {
    enum MessageType {
        None,
        Fetch,
        Callback
    }

    function fetch(
        uint32 _destination,
        address _target,
        bytes memory _data,
        bytes4 _callbackSelector
    ) external {
        bytes memory _message = abi.encode(MessageType.Fetch, msg.sender, _callbackSelector, _target, _data);
        super._dispatch(_destination, _message);
    }

    function _handle(
        uint32 _origin,
        bytes32, // router
        bytes memory _message
    ) internal override {
        (MessageType _messageType, address _caller, bytes memory _payload) = abi.decode(_message, (MessageType, address, bytes));
        if (_messageType == MessageType.Callback) {
            (bool ok, ) = _caller.call(_payload);
            if (!ok) {
                revert();
            }
        } else if (_messageType == MessageType.Fetch) {
            (address _target, bytes4 _callbackSelector, bytes memory _data) = abi.decode(_payload, (address, bytes4, bytes));
            (bool ok, bytes memory _result) = _target.call(_data);
            if (!ok) {
                revert();
            }
            bytes memory _callbackMessage = abi.encode(MessageType.Callback, _caller, _callbackSelector, _result);
            super._dispatch(_origin, _callbackMessage);
        }
    }
}

