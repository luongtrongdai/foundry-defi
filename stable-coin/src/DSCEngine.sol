// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {PriceConverter} from "src/library/PriceConverter.sol";

contract DSCEngine is ReentrancyGuard {
    // Type Declarations
    using PriceConverter for uint256;

    error DSCEngine__NeedsMoreThanZero();
    error DSCEngint__ParamsMustSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant PRECISION = 1e18;
    uint8 private constant MIN_HEALTH_FACTOR = 1;

    DecentralizedStableCoin immutable i_dsc;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 balance)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_amountDSCMinted;
    address[] private s_collateralTokens;

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
            address tokenAddr = _tokenAddresses[i];
            s_priceFeeds[tokenAddr] = _priceFeeds[i];
            s_collateralTokens.push(tokenAddr);
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
        emit CollateralDeposited(msg.sender, tokenAddr, amount);

        bool success = IERC20(tokenAddr).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function mintDSC(uint256 amountDscToMint) external
        moreThanZero(amountDscToMint)
        nonReentrant
    {
        s_amountDSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCEngine__MintFailed();
        }
    }
    function burnDSC() external {}

    function liquidate() external {}

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // Loop from list token, get amount and exchange to USD
        mapping(address token => uint256 amount) storage collateralDeposited = s_collateralDeposited[user];
        address[] memory tokenAddrs = s_collateralTokens;
        uint256 length = tokenAddrs.length;
        for (uint256 i = 0; i < length; ) {
            address tokenAddr = tokenAddrs[i];
            uint256 tokenAmount = collateralDeposited[tokenAddr];
            if (tokenAmount > 0) {
                totalCollateralValueInUsd = 
                    totalCollateralValueInUsd + tokenAmount * getTokenPrice(tokenAddr
                    , tokenAmount);
            }
            i = i + 1;
        }
    }

    function getTokenPrice(address token, uint256 amount) private view returns (uint256) {
        return amount.getConversionRate(s_priceFeeds[token]);
    }

    ////////////////////////////////////
    // Private and Internal functions //
    ////////////////////////////////////
    function _getAccountInfo(address _user) private view returns (uint256 totalDSCMinted, uint256 collateralValueInUSD) {
        totalDSCMinted = s_amountDSCMinted[_user];
        collateralValueInUSD = getAccountCollateralValue(_user);
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDSCMinted, uint256 totalCollateralValueInUsd) = _getAccountInfo(user);
        uint256 collateralAdjustedForThreshold = (totalCollateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDSCMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(healthFactor);
        }
    }
}
