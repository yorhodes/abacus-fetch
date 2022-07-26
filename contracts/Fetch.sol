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
        bytes4 _callbackSelector,
        bytes memory _extraCallbackData
    ) external {
        bytes memory _payload = abi.encode(msg.sender, _callbackSelector, _target, _data, _extraCallbackData);
        bytes memory _message = abi.encodePacked(MessageType.Fetch, _payload);
        super._dispatch(_destination, _message);
    }

    function _handle(
        uint32 _origin,
        bytes32, // router
        bytes memory _message
    ) internal override {
        (MessageType _messageType, bytes memory _payload) = abi.decode(_message, (MessageType, bytes));
        if (_messageType == MessageType.Callback) {
            (address _caller, bytes4 _callbackSelector, bytes memory _result, bytes memory _extra) = abi.decode(_payload, (address, bytes4, bytes, bytes));
            (bool ok, ) = _caller.call(_payload);
            if (!ok) {
                revert();
            }
        } else if (_messageType == MessageType.Fetch) {
            (address _caller, _callbackSelector, _target, _data, _extra) = abi.decode(_payload, (address, bytes4, address, bytes, bytes));
            (bool ok, bytes memory _result) = _target.call(_data);
            if (!ok) {
                revert();
            }
            bytes memory _payload = abi.encode(_caller, _callbackSelector, _result, _extra)
            bytes memory _callbackMessage = abi.encodePacked(MessageType.Callback, _payload);
            super._dispatch(_origin, _callbackMessage);
        }
    }
}

