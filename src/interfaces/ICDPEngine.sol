// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ICDPEngine {
    struct Collateral {
        // totalNormalisedDebt: debt that was borrow divided by value of rate accumulation function when debt changed
        // di = delta debt at time i
        // ri = rateAcc at time i
        // totalNormalisedDebt = d0 / r0 + d1 / r1 ... di / ri
        // d0 and d1 created by different users
        uint256 totalNormalisedDebt; // [wad]
        uint256 rateAcc; // [ray]
        uint256 spot; // price * (1 - safetyMargin) // [ray]
        uint256 maxDebt; // [rad]
        uint256 minDebt; // [rad]
    }

    struct Position {
        uint256 collateral; // [wad]
        uint256 normalizedDebt; // [wad]
    }

    function modifyCollateralBalance(bytes32 collateralType, address src, int256 wad) external;

    function set(bytes32 key, bytes32 what, uint256 val) external;

    function transferCoin(address src, address dst, uint256 amt) external;
}
