// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ICDPEngine} from "interfaces/ICDPEngine.sol";
import {IPriceFeed} from "interfaces/IPriceFeed.sol";
import {Math} from "libs/Math.sol";
import {Auth} from "src/Auth.sol";
import {Pausable} from "src/Pausable.sol";

contract Spotter is Pausable, Auth {
    error ErrUnrecognizedParam();

    struct Collateral {
        IPriceFeed priceFeed;
        uint256 liquidationRatio;
    }
    // spot = val / liquidationRatio;

    event Poke(bytes32 collateralType, uint256 val, uint256 spot);

    mapping(bytes32 => Collateral) public collaterals;
    ICDPEngine public cdpEngine;
    uint256 public par;

    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
        par = Math.RAY;
    }

    function set(
        bytes32 _collateralType,
        bytes32 _what,
        address _feed
    ) external auth notPaused {
        if (_what == "priceFeed")
            collaterals[_collateralType].priceFeed = IPriceFeed(_feed);
        else revert ErrUnrecognizedParam();
    }

    function set(bytes32 _what, uint256 _val) external auth notPaused {
        if (_what == "par") par = _val;
        else revert ErrUnrecognizedParam();
    }

    function set(
        bytes32 _collateralType,
        bytes32 _what,
        uint256 _val
    ) external auth notPaused {
        if (_what == "liquidationRatio")
            collaterals[_collateralType].liquidationRatio = _val;
        else revert ErrUnrecognizedParam();
    }

    function poke(bytes32 _collateralType) external notPaused {
        (uint256 val, bool has) = collaterals[_collateralType].priceFeed.Peek();
        // spot = (val * 1e9 / par) / liquidationRatio
        //         wad         ray
        // liquidationRatio provides a safety margin for the price feed

        uint256 spot = has
            ? Math.rdiv(
                Math.rdiv(val * 1e9, par),
                collaterals[_collateralType].liquidationRatio
            )
            : 0;
        cdpEngine.set(_collateralType, "spot", spot);
        emit Poke(_collateralType, val, spot);
    }

    function pause() external auth {
        _pause();
    }

    function unPause() external auth {
        _unPause();
    }
}
