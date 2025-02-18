// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ICDPEngine } from "interfaces/ICDPEngine.sol";
import { ICoin } from "interfaces/ICoin.sol";
import { Math } from "libs/Math.sol";
import { Auth } from "src/Auth.sol";
import { Pausable } from "src/Pausable.sol";

contract CoinJoin is Auth, Pausable {
    event Joined(address, uint256);
    event Exited(address, uint256);

    ICDPEngine public cdpEngine;
    ICoin public coin;

    constructor(ICDPEngine _cdpEngine, ICoin _coin) {
        cdpEngine = _cdpEngine;
        coin = _coin;
    }

    function join(address usr, uint256 wad) external notPaused {
        cdpEngine.transferCoin(address(this), usr, wad * Math.RAY);
        coin.burn(msg.sender, wad);
        emit Joined(usr, wad);
    }

    function exit(address usr, uint256 wad) external notPaused {
        cdpEngine.transferCoin(msg.sender, address(this), wad * Math.RAY);
        coin.mint(msg.sender, wad);
        emit Exited(usr, wad);
    }

    function pause() external auth {
        _pause();
    }

    function unPause() external auth {
        _unPause();
    }
}
