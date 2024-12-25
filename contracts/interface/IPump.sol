// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IPump {
    // errors
    error TickHasBeenCreated();
    error CantBeZeroAddress();
    error CantSetSocialDistributionMoreThanTotalSupply();
    error TooMuchFee();
    error InsufficientCreateFee();
    error RefundFail();

    // events
    event NewToken(string indexed tick, address indexed token, address indexed creator);
    event SocialDistributionContractChanged(address indexed oldContract, address indexed newContract);
    event IPShareChanged(address indexed oldIPShare, address indexed newIPShare);
    event CreateFeeChanged(uint256 indexed oldFee, uint256 indexed newFee);
    event FeeAddressChanged(address indexed oldAddress, address indexed newAddress);
    event FeeRatiosChanged(uint256 indexed donutFee, uint256 indexed sellsmanFee);
    event ClaimSignerChanged(address indexed oldSigner, address indexed newSigner);

    function getIPShare() external view returns (address);
    function getFeeReceiver() external view returns (address);
    function getFeeRatio() external view returns (uint256[2] memory);
    function getClaimFee() external view returns (uint256);
    function createToken(string calldata tick) external payable returns (address);
    function getClaimSigner() external view returns (address);
}