// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ICDPEngine } from "interfaces/ICDPEngine.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { Auth } from "src/Auth.sol";
import { Pausable } from "src/Pausable.sol";

contract GemJoin is Auth, Pausable {
    error ErrOverFlow();

    event Join(address, uint256);
    event Exit(address, uint256);

    ICDPEngine public cdpEngine;
    bytes32 public collateralType;
    ERC20 public gem;
    uint8 decimals;

    constructor(address _cdpEngine, bytes32 _collateralType, address _gem) {
        cdpEngine = ICDPEngine(_cdpEngine);
        collateralType = _collateralType;
        gem = ERC20(_gem);
        decimals = ERC20(_gem).decimals();
    }

    // wad = 1e18
    // ray = 1e27
    // rad = 1e45
    function join(address usr, uint256 wad) external notPaused {
        require(int256(wad) >= 0, ErrOverFlow());
        cdpEngine.modifyCollateralBalance(collateralType, usr, int256(wad));
        SafeTransferLib.safeTransferFrom(gem, msg.sender, address(this), wad);
        emit Join(usr, wad);
    }

    function exit(address usr, uint256 wad) external notPaused {
        require(wad <= 2 ** 255, ErrOverFlow());
        cdpEngine.modifyCollateralBalance(collateralType, usr, -int256(wad));
        SafeTransferLib.safeTransfer(gem, msg.sender, wad);
        emit Exit(usr, wad);
    }

    function pause() external auth {
        _pause();
    }

    function unPause() external auth {
        _unPause();
    }
}
