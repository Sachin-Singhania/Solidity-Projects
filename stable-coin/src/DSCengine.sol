// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import {ERC20Burnable, ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./library/OracleLib.sol";
import {console} from "forge-std/console.sol";
contract DSCEngine is ReentrancyGuard {
    ///////////////////
    // ~~~ERRORS~~~
    ///////////////////
    error DSC__NEEDSMORETHANZERO();
    error DSC__TOKENADDRESSLENGTHMUSTBEEQUALTOPRICEFEEDADD();
    error DSC__TOKENNOTALLOWED();
    error DSC__TRANSFERFROMFAILED();
    error DSC__MINTFAILED();
    error DSC__TRANSFERFAILED();
    error DSC__LIQUIDATIONFAILEDASITSNOTOK();
    error DSC__LIQUIDATIONFAILEDASITSOK();
    error DSC__AMOUNTTOSWAPISZERO();
    error DSC__HEALTHFACTORBROKEN(uint256 healthFactor);

    using OracleLib for AggregatorV3Interface;

    ///////////////////
    // ~~~STATE VARIABLES~~~
    ///////////////////
    uint256 public constant ADDITIONAL_FEE_PRECISION = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant LIQUIDATION_PRECISION = 100;
    uint256 public constant LIQUIDATION_BONUS = 10;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    mapping(address token => address priceFeed) private s_priceFeed;
    mapping(address user => mapping(address token => uint256))
        private s_collateralDeposited;
    mapping(address user => uint256 amountMinted) private s_dscMinted;
    DecentralizedStableCoin private immutable i_dsc;
    address[] private s_collateralTokens; //what does this do and why we do this? answer : this is used to store the collateral tokens and it is used to prevent the user from depositing the same token multiple times
    ///////////////////
    // ~~~STATE VARIABLES~~~
    ///////////////////
    event DSC__CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );
    event DSC__CollateralRedeemed(
        address indexed RedeemedFrom,
        address indexed RedeemedTo,
        address indexed token,
        uint256 amount
    );
    ///////////////////
    // ~~~MODIFIERS~~~
    ///////////////////
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) revert DSC__NEEDSMORETHANZERO();
        _;
    }
    modifier IsAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) revert DSC__TOKENNOTALLOWED();
        _;
    }

    ///////////////////
    // ~~~FUNCTIONS~~~
    ///////////////////
    constructor(
        address[] memory _tokenAddress,
        address[] memory _priceFeedAddress,
        address dscAddress
    ) {
        if (_tokenAddress.length != _priceFeedAddress.length)
            revert DSC__TOKENADDRESSLENGTHMUSTBEEQUALTOPRICEFEEDADD();
        uint256 length = _tokenAddress.length;
        for (uint256 index = 0; index < length; index++) {
            s_priceFeed[_tokenAddress[index]] = _priceFeedAddress[index];
            s_collateralTokens.push(_tokenAddress[index]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ///////////////////
    // ~~~EXTERNAL FUNCTIONS~~~
    ///////////////////

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        IsAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit DSC__CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) revert DSC__TRANSFERFROMFAILED();
    }

    function mintDSC(uint256 amtDsctoMinted) public moreThanZero(amtDsctoMinted) nonReentrant {
        s_dscMinted[msg.sender] += amtDsctoMinted;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool Isminted = i_dsc.mint(msg.sender, amtDsctoMinted);
        if (!Isminted) revert DSC__MINTFAILED();
    }

    function depositCollateralandMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amtDsctoMinted
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDSC(amtDsctoMinted);
    }

    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        IsAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
    }

    function burnDSC(uint256 amount) public moreThanZero(amount) {
        _burnDsc(msg.sender, msg.sender, amount);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateralforDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDsctoBurn
    ) external {
        burnDSC(amountDsctoBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function liquidate(
        address collateral,
        address user,
        uint256 debttocover
    ) external moreThanZero(debttocover) nonReentrant {
        uint256 StartingUserHealthFactor = _healthFactor(user);
        if (StartingUserHealthFactor >= MIN_HEALTH_FACTOR)
            revert DSC__LIQUIDATIONFAILEDASITSOK();
        //0.05 ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUSD(
            collateral,
            debttocover
        );
        uint256 bonusCollateral = (tokenAmountFromDebtCovered *
            LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 collateralToRedeem = tokenAmountFromDebtCovered +
            bonusCollateral;
        _redeemCollateral(collateral, collateralToRedeem, user, msg.sender);
        _burnDsc(user, msg.sender, debttocover);
        uint256 EndingHealthFactor = _healthFactor(user);
        if (EndingHealthFactor <= StartingUserHealthFactor)
            revert DSC__LIQUIDATIONFAILEDASITSNOTOK();
        _revertIfHealthFactorIsBroken(msg.sender);
    }
    ///////////////////////////
    // ~~~INTERNAL FUNCTIONS~~~
    //////////////////////////
    function _burnDsc(
        address onBehalfof,
        address dscFrom,
        uint256 amounttoburn
    ) internal {
        s_dscMinted[onBehalfof] -= amounttoburn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amounttoburn);
        if (!success) revert DSC__TRANSFERFROMFAILED();
        i_dsc.burn(amounttoburn);
    }
    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) private {
         if  (s_collateralDeposited[from][tokenCollateralAddress] == 0 || s_collateralDeposited[from][tokenCollateralAddress] <amountCollateral) revert DSC__AMOUNTTOSWAPISZERO();
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit DSC__CollateralRedeemed(
            from,
            to,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transfer(
            to,
            amountCollateral
        );
        if (!success) revert DSC__TRANSFERFAILED();
    }
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR)
            revert DSC__HEALTHFACTORBROKEN(healthFactor);
    }
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted,uint256 totalCollateralValueinUSD) = _getAccountInfo(user);
        return _calculateHealthFactor( totalDscMinted, totalCollateralValueinUSD);
    }
     function calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    )
        external
        pure
        returns (uint256)
    {

        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }
     function _calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    )
        internal
        pure
        returns (uint256)
    {
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }
    function _getAccountInfo (
        address user
    )
        private view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueinUSD)
    {
        totalDscMinted = s_dscMinted[user];
        totalCollateralValueinUSD = _getAccountCollateralInfo(user);
    }

    ///////////////////////////
    // ~~~PUBLIC / PURE FN~~~//
    ///////////////////////////
    function getTokenAmountFromUSD(
        address token,
        uint256 usdAmountinWei
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.stalePriceCheck();
        return
            (usdAmountinWei * PRECISION) /
            (uint256(price) * ADDITIONAL_FEE_PRECISION);
    }
    function _getAccountCollateralInfo(
        address user
    ) public view returns (uint256 totalCollateralValueinUSD) {
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueinUSD += getUSDvalue(token, amount);
        }
        return totalCollateralValueinUSD;
    }
    function getUSDvalue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.stalePriceCheck();
        return
            (uint256(uint256(price) * ADDITIONAL_FEE_PRECISION) * amount) /
            PRECISION;
    }
    function getAccountInfo(address user) public view returns (uint256,uint256 ){
        return _getAccountInfo(user);
    } 
    function getCollateralTokens() public view returns (address[] memory) {
        return s_collateralTokens;
    }
    function getCollateralBalanceUser( address user,address token) public view returns (uint256) {
        return s_collateralDeposited[user][token];
        }
    function getCollateralTokenPriceFeed( address token) public view returns (address) {
        return s_priceFeed[token];
    }
     function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEE_PRECISION;
    }
      function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }
}
