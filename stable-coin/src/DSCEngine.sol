// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract DSCEngine is ReentrancyGuard {
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngint__ParamsMustSameLength();
    error DSCEngine__TokenNotAllowed();

    DecentralizedStableCoin immutable i_dsc;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 balance)) private s_collateralDeposited;

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    constructor(address[] memory _tokenAddresses, address[] memory _priceFeeds, address _dscAddr) {
        uint256 length = _tokenAddresses.length;
        if (length != _priceFeeds.length) {
            revert DSCEngint__ParamsMustSameLength();
        }

        for (uint256 i = 0; i < length;) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeeds[i];
            i = i + 1;
        }
        i_dsc = DecentralizedStableCoin(_dscAddr);
    }

    function depositCollateralAndMintDSC() external payable {}

    function depositCollateral(address tokenAddr, uint256 amount)
        external
        payable
        moreThanZero(amount)
        isAllowedToken(tokenAddr)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenAddr] += amount;
    }

    function redeemCollateralForDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function healthFactor() external view {}
}
