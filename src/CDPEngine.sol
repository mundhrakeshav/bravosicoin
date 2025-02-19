// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ICDPEngine} from "interfaces/ICDPEngine.sol";
import {Math} from "libs/Math.sol";
import {Auth} from "src/Auth.sol";
import {Pausable} from "src/Pausable.sol";

contract CDPEngine is Auth, Pausable {
    error ErrModifierNotAllowed();
    error ErrCollateralAlreadyInit();
    error ErrUnrecognizedParam();
    error ErrCollateralNotInit();
    error ErrCeilingExceeded();
    error ErrNotSafe();
    error ErrNotAllowedCDP();
    error ErrNotAllowedGemSrc();
    error ErrDust();

    mapping(bytes32 => ICDPEngine.Collateral) public collaterals;
    // urns - collateral type => account => position
    mapping(bytes32 => mapping(address => ICDPEngine.Position))
        public positions;
    mapping(bytes32 => mapping(address => uint256)) gem;
    mapping(address => mapping(address => uint256)) can;
    mapping(address => uint256) balance;

    uint256 sysMaxDebt;
    uint256 systemDebt;

    modifier canModify(address usr) {
        require(
            msg.sender == usr || can[usr][msg.sender] == 1,
            ErrModifierNotAllowed()
        );
        _;
    }

    function allowModifier(address usr) external {
        can[msg.sender][usr] = 1;
    }

    function denyModifier(address usr) external {
        can[msg.sender][usr] = 0;
    }

    function init(bytes32 collateralType) external auth {
        require(
            collaterals[collateralType].rateAcc == 0,
            ErrCollateralAlreadyInit()
        );
        collaterals[collateralType].rateAcc = 1e27;
    }

    function modifyCollateralBalance(
        bytes32 _collateralType,
        address _usr,
        int256 _wad
    ) external auth {
        uint256 wad = gem[_collateralType][_usr];
        gem[_collateralType][_usr] = Math.add(wad, _wad);
    }

    function transferCoin(
        address src,
        address dst,
        uint256 rad
    ) external canModify(src) {
        balance[src] = balance[src] - rad;
        balance[dst] = balance[dst] + rad;
    }

    function canModifyAccount(
        address src
    ) internal view canModify(src) returns (bool) {
        return true;
    }

    //
    function modifyCDP(
        bytes32 collateralType,
        address user,
        address gemSrc,
        address coinDst,
        int256 deltaCol,
        int256 deltaDebt
    ) external auth notPaused {
        ICDPEngine.Position memory pos = positions[collateralType][user];
        ICDPEngine.Collateral memory col = collaterals[collateralType];

        require(col.rateAcc != 0, ErrCollateralNotInit());

        pos.collateral = Math.add(pos.collateral, deltaCol);
        pos.normalizedDebt = Math.add(pos.normalizedDebt, deltaDebt);
        col.totalNormalisedDebt = Math.add(col.totalNormalisedDebt, deltaDebt);

        int256 deltaCoin = Math.mul(col.rateAcc, deltaDebt);
        uint256 coinDebt = col.rateAcc * pos.normalizedDebt;

        systemDebt = Math.add(systemDebt, deltaCoin);

        require(
            deltaDebt <= 0 ||
                (col.totalNormalisedDebt * col.rateAcc <= col.maxDebt &&
                    systemDebt <= sysMaxDebt),
            ErrCeilingExceeded()
        );

        require(
            (deltaDebt <= 0 && deltaCol >= 0) ||
                coinDebt <= pos.collateral * col.spot,
            ErrNotSafe()
        );
        require(
            (deltaDebt <= 0 && deltaCol >= 0) || canModifyAccount(user),
            ErrNotAllowedCDP()
        );
        require(
            (deltaCol <= 0) || canModifyAccount(gemSrc),
            ErrNotAllowedGemSrc()
        );
        require(
            (deltaDebt >= 0) || canModifyAccount(coinDst),
            ErrNotAllowedGemSrc()
        );
        require(pos.normalizedDebt == 0 || coinDebt >= col.minDebt, ErrDust());

        gem[collateralType][gemSrc] = Math.sub(
            gem[collateralType][gemSrc],
            deltaCol
        );

        balance[coinDst] = Math.add(balance[coinDst], deltaCoin);

        positions[collateralType][user] = pos;
        collaterals[collateralType] = col;
    }

    function set(bytes32 key, uint256 val) external auth notPaused {
        if (key == "sysMaxDebt") sysMaxDebt = val;
        else revert ErrUnrecognizedParam();
    }

    function set(
        bytes32 key,
        bytes32 what,
        uint256 val
    ) external auth notPaused {
        if (key == "spot") collaterals[what].spot = val;
        else if (key == "maxDebt") collaterals[what].maxDebt = val;
        else if (key == "minDebt") collaterals[what].minDebt = val;
        else revert ErrUnrecognizedParam();
    }

    //
    function updateRateAcc(
        bytes32 _collateralType,
        address _coinDst,
        int256 _deltaRate
    ) external auth notPaused {
        ICDPEngine.Collateral memory col = collaterals[_collateralType];
        col.rateAcc = Math.add(col.rateAcc, _deltaRate);
        int256 deltaCoin = Math.mul(col.totalNormalisedDebt, _deltaRate);
        balance[_coinDst] = Math.add(balance[_coinDst], deltaCoin);
        systemDebt = Math.add(systemDebt, deltaCoin);
    }

    function pause() external auth {
        _pause();
    }

    function unPause() external auth {
        _unPause();
    }
}
