// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ICoin {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}
