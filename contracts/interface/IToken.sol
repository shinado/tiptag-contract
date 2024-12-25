// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IToken {
    error TokenNotListed();
    error TokenListed();
    error IPShareNotCreated();
    error TokenInitialized();
    error ClaimOrderExist();
    error InvalidSignature();
    error InvalidClaimAmount();
    error InvalidClaimer();
    error OutOfSlippage();
    error InsufficientFund();
    error RefundFail();
    error CostFeeFail();
    error CreateDexPoolFail();

    event ClaimDistributedReward(uint256 indexed timestamp, uint256 indexed amount);
    event UserClaimReward(uint256 indexed orderId, address indexed user, uint256 indexed amount);
    event Trade(
        address indexed buyer,
        bool isBuy,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 tiptagFee,
        uint256 sellsmanFee
    );
    event TokenListedToDex(address indexed pair);

    function initialize(
        address manager_,
        address ipshareSubject_,
        string memory tick_
    ) external;
    
}
