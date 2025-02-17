// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract Pausable {
    error ErrIsPaused();

    event Paused();
    event UnPaused();

    uint256 public isPaused;

    function _pause() internal {
        isPaused = 1;
        emit Paused();
    }

    function _unPause() internal {
        isPaused = 0;
        emit UnPaused();
    }

    modifier notPaused() {
        require(isPaused == 0, ErrIsPaused());
        _;
    }
}
