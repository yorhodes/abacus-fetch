// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "@abacus-network/app/contracts/Router.sol";

contract Fetch is Router {
    event FetchFailed(uint32 domain, address target);
    event CallbackFailed(uint32 domain, address target);

    function fetch(
        uint32 destination,
        address target,
        bytes4 callback,
        bytes calldata data
    ) external {
        super._dispatch(
            destination,
            abi.encodePacked(
                uint8(0), // isCallback
                msg.sender,
                target,
                callback,
                data
            )
        );
    }

    function _handle(
        uint32 _origin,
        bytes32, // router
        bytes calldata _message
    ) internal override {
        uint8 isCallback = uint8(bytes1(_message[0]));
        if (isCallback == 1) {
            address target = address(bytes20(_message[1:21]));
            bytes4 callback = bytes4(_message[21:25]);
            (bool ok,) = target.call(
                abi.encodeWithSelector(
                    callback,
                    _message[25:]
                )
            );
            if (!ok) {
                emit CallbackFailed(_origin, target);
            }
        } else {
            address caller = address(bytes20(_message[1:21]));
            address target = address(bytes20(_message[21:41]));
            bytes4 callback = bytes4(_message[41:45]);
            (bool ok, bytes memory returnData) = target.call(_message[45:]);
            if (ok) {
                super._dispatch(
                    _origin,
                    abi.encodePacked(
                        uint8(1), // isCallback
                        caller,
                        callback,
                        returnData
                    )
                );
            } else {
                emit FetchFailed(_origin, target);
            }
        }
    }
}

