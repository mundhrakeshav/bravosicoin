// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ICDPEngine } from "interfaces/ICDPEngine.sol";
import { Math } from "libs/Math.sol";
import { Auth } from "src/Auth.sol";
import { Pausable } from "src/Pausable.sol";

contract Jug is Auth, Pausable {
    error ErrUnrecognizedParam();
    error ErrCollateralNotInit();
    error ErrCollateralInit();
    error ErrRhoNotUpdated();
    error ErrInvalidNow();

    struct Collateral {
        // Collateral stability fee
        uint256 fee;
        uint256 updatedAt;
    }

    event File(bytes32 what, uint256 data);
    event Init(bytes32 indexed collateralType);
    event Ilk(bytes32 indexed collateralType, uint256 duty, uint256 rho);

    mapping(bytes32 => Collateral) public collaterals;
    ICDPEngine public cdpEngine;
    uint256 public baseFee; // Global, per second stability fee contribution [ray ]
    address public dsEngine; //Debt Engine

    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
    }

    function init(bytes32 _collateralType) external auth {
        Collateral storage col = collaterals[_collateralType];
        require(col.fee == 0, ErrCollateralInit());
        col.fee = Math.RAY;
        col.updatedAt = block.timestamp;
        emit Init(_collateralType);
    }

    function set(bytes32 key, uint256 data) external auth notPaused {
        if (key == "baseFee") baseFee = data;
        else revert ErrUnrecognizedParam();
    }

    function set(bytes32 key, address data) external auth notPaused {
        if (key == "dsEngine") dsEngine = data;
        else revert ErrUnrecognizedParam();
    }

    function set(bytes32 _collateralType, bytes32 _what, uint256 _data) external auth notPaused {
        require(collaterals[_collateralType].fee != 0, ErrCollateralNotInit());
        require(collaterals[_collateralType].updatedAt == block.timestamp, ErrRhoNotUpdated());
        if (_what == "fee") collaterals[_collateralType].fee = _data;
        else revert ErrUnrecognizedParam();
    }

    function drip(bytes32 collateralType) external returns (uint256 rate) {
        require(collaterals[collateralType].fee != 0, ErrCollateralNotInit());
        require(collaterals[collateralType].updatedAt == block.timestamp, ErrRhoNotUpdated());

        ICDPEngine.Collateral memory col = cdpEngine.collaterals(collateralType);

        rate = Math.rmul(
            Math.rpow(
                baseFee + collaterals[collateralType].fee,
                block.timestamp - collaterals[collateralType].updatedAt,
                Math.RAY
            ),
            col.rateAcc
        );

        cdpEngine.updateRateAcc(collateralType, dsEngine, Math.diff(rate, col.rateAcc));
        collaterals[collateralType].updatedAt = block.timestamp;
        // emit Ilk(collateralType, duty, block.timestamp);
    }
}
