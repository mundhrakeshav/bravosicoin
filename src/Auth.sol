// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract Auth {
    error ErrUnAuthorized();

    event GrantedAuth(address);
    event DeniedAuth(address);

    mapping(address => uint256) public authorized;

    modifier auth() {
        require(authorized[msg.sender] == 1, ErrUnAuthorized());
        _;
    }

    constructor() {
        authorized[msg.sender] = 1;
    }

    function grantAuth(address usr) external auth {
        authorized[usr] = 1;
        emit GrantedAuth(usr);
    }

    function denyAuth(address usr) external auth {
        authorized[usr] = 0;
        emit DeniedAuth(usr);
    }
}
