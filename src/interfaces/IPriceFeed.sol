// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IPriceFeed {
    function Peek() external view returns (uint256, bool);
}
