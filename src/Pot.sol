// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { ICDPEngine } from "interfaces/ICDPEngine.sol";
import { Math } from "libs/Math.sol";
import { Auth } from "src/Auth.sol";
import { Pausable } from "src/Pausable.sol";

contract Pot is Auth, Pausable {
    error ErrNotUpdated();
    error ErrUnrecognizedParam();

    mapping(address => uint256) public pie;
    uint256 public totalPie;
    uint256 public savingsRate;
    uint256 public rateAcc;
    ICDPEngine public cdpEngine;
    address public debtSurplusEngine;
    uint256 public updatedAt;

    constructor(ICDPEngine _cdpEngine) {
        savingsRate = Math.RAY;
        rateAcc = Math.RAY;
        updatedAt = block.timestamp;
        cdpEngine = _cdpEngine;
    }

    function set(bytes32 _key, uint256 _data) external auth notPaused {
        require(updatedAt == block.timestamp, ErrNotUpdated());
        if (_key == "savingsRate") savingsRate = _data;
        else revert ErrUnrecognizedParam();
    }

    function set(bytes32 _key, address addr) external auth notPaused {
        if (_key == "debtSurplusEngine") debtSurplusEngine = addr;
        else revert ErrUnrecognizedParam();
    }

    function collectStabilityFee() external returns (uint256) {
        require(updatedAt <= block.timestamp, ErrNotUpdated());

        uint256 acc = Math.rmul(Math.rpow(savingsRate, block.timestamp - updatedAt, Math.RAY), rateAcc);
        uint256 deltaRateAcc = acc - rateAcc;
        rateAcc = acc;
        updatedAt = block.timestamp;

        cdpEngine.mint(debtSurplusEngine, address(this), totalPie * deltaRateAcc);
        return acc;
    }

    function join(uint256 wad) external {
        require(updatedAt == block.timestamp, ErrNotUpdated());
        pie[msg.sender] += wad;
        totalPie += wad;
        cdpEngine.transferCoin(msg.sender, address(this), rateAcc * wad);
    }

    function exit(uint256 wad) external {
        require(updatedAt == block.timestamp, ErrNotUpdated());
        pie[msg.sender] -= wad;
        totalPie -= wad;
        cdpEngine.transferCoin(address(this), msg.sender, rateAcc * wad);
    }

    function pause() external auth {
        _pause();
        savingsRate = Math.RAY;
    }

    function unPause() external auth {
        _unPause();
    }
}
