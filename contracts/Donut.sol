// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IIPShare.sol";
import "./interface/IDonut.sol";

// This is the ip-share purchase gate by bonding curve sell
// User can only by someone's ip-share through a content of him by tip
// The whole donut platform maintenance one round of this fomo game for the all users
// This game may be more than one round
// This is the only buyer admin of IPShare
contract Donut is Ownable, Pausable, ReentrancyGuard, IDonut {
    struct RoundInfo {
        uint8 cursor;
        uint256 rewards;
        uint256 endTime;
        uint256 maxEraTime;
        address[6] lastUsers;
    }
    // round => tickets
    mapping(uint256 => RoundInfo) private roundInfo;
    uint256 public currentRound = 1;

    address public IPShare;
    address private immutable BlackHole =
        0x000000000000000000000000000000000000dEaD;

    // set the ticket price to 0.0001 BTC
    uint256 public constant ticketPrice = 100_000_000_000_000;
    uint256 public constant minDonateAmount = 1_000_000_000_00;

    // every 0.00005 BTC rewards will reduce 1 second of max era
    uint256 private constant timeReduceByEth = 0.00005 ether;
    // The hard top waiting time of one round
    uint256 private constant INIT_ROUND_ERA = 1 days;
    // every ticket purchased adds this much to the timer
    uint256 private constant ROUND_INC = 5 minutes;
    // paused time stamp
    uint256 private pausedTime;

    // the donate fund distribution: 97%: ipshare, 3%: reward pool
    uint256[2] public donateDistributionRatios = [9700, 300];
    // reward pool distribution: winner: 77.5%, to the next round: 22.5%
    uint256[2] public rewardDistributionRatios = [7750, 2250];

    bool public gameStarted = false;

    event Donate(
        address indexed subject,
        address indexed donator,
        uint256 indexed ethAmount,
        uint256 recIPShares,
        uint256 tweetId,
        uint256 round
    );

    event Winner(uint256 indexed round, uint256 indexed reward);

    constructor( ///
        address _IPShare
    ) payable Ownable(msg.sender) {
        IPShare = _IPShare;
    }

    /**
     * @dev prevents contracts from interacting with fomo3d
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }
        if (_codeLength != 0) {
            revert OnlyHumanAllowed();
        }
        _;
    }

    // ================================ ownable function =================================
    function adminSetIPShare(address _IPShare) public onlyOwner {
        IPShare = _IPShare;
    }

    function pause() public onlyOwner {
        pausedTime = block.timestamp;
        _pause();
    }

    function unpause() public onlyOwner {
        uint256 waitedTime = block.timestamp - pausedTime;
        if (
            roundInfo[currentRound].endTime + waitedTime >
            roundInfo[currentRound].maxEraTime + block.timestamp
        ) {
            roundInfo[currentRound].endTime =
                block.timestamp +
                roundInfo[currentRound].maxEraTime;
        } else {
            roundInfo[currentRound].endTime += waitedTime;
        }
        _unpause();
    }

    // ratios: winner, next rount
    function adminUpdateRewardDistribution(
        uint256[2] calldata ratios
    ) public onlyOwner {
        // check ratios
        if (ratios[0] + ratios[1] != 10000) {
            revert IllegalRatios();
        }
        rewardDistributionRatios = ratios;
    }

    // set the donate distirubtion
    //  ipshare, reward pool
    function adminUpdateDonateDistributionRatios(
        uint256[2] calldata ratios
    ) public onlyOwner {
        if (ratios[0] + ratios[1] != 10000) {
            revert IllegalRatios();
        }
        donateDistributionRatios = ratios;
    }

    function startGame() public onlyOwner {
        gameStarted = true;
        currentRound = 1;
        roundInfo[currentRound].rewards = 0;
        roundInfo[currentRound].endTime = block.timestamp + INIT_ROUND_ERA;
        roundInfo[currentRound].maxEraTime = INIT_ROUND_ERA;
    }

    // ================================ core function =================================
    function donate(
        address subject,
        uint256 tweetId
    ) public payable isHuman nonReentrant whenNotPaused {
        // The received ETH will be divided into the following parts

        if (!gameStarted) {
            revert GameIsNotStarted();
        }

        // check subject
        if (!IIPShare(IPShare).ipshareCreated(subject)) {
            revert IPShareNotExist();
        }

        uint256 donateAmount = msg.value;
        if (donateAmount <= minDonateAmount) {
            revert InvalidCurrency();
        }

        uint256 rewardFund = (donateAmount * donateDistributionRatios[1]) /
            10000;
        uint256 ipshareFund = donateAmount - rewardFund;

        // check round
        RoundInfo memory _roundInfo = roundInfo[currentRound];
        if (_roundInfo.endTime < block.timestamp) {
            // The round finished
            uint256 totalFund = roundInfo[currentRound].rewards;
            address[6] memory winners = roundInfo[currentRound].lastUsers;

            uint256 winnerFund = (totalFund * rewardDistributionRatios[0]) /
                10000;

            uint256 nextFund = totalFund - winnerFund;

            // The last 6 participants can receive rewards according to this ratio
            uint16[6] memory winnerRewardsRatio = [
                300,
                325,
                625,
                1250,
                2500,
                5000
            ];

            for (uint8 i = 0; i < 6; i++) {
                address winner = winners[
                    (i + roundInfo[currentRound].cursor) % 6
                ];
                uint256 reward = (winnerFund * winnerRewardsRatio[i]) / 10000;
                if (winner != address(0)) {
                    payable(winner).transfer(reward);
                } else {
                    nextFund += reward;
                }
            }

            // new round
            currentRound += 1;
            roundInfo[currentRound].rewards = nextFund;
            roundInfo[currentRound].endTime = block.timestamp + INIT_ROUND_ERA;
            roundInfo[currentRound].maxEraTime = INIT_ROUND_ERA;

            emit Winner(currentRound, winnerFund);
        }

        // update max era time
        // reduce by 1 second for every 0.1 ETH increase to the rewards
        uint256 diff = (roundInfo[currentRound].rewards + rewardFund) /
            timeReduceByEth;
        if (INIT_ROUND_ERA < diff) {
            roundInfo[currentRound].maxEraTime = ROUND_INC;
        }else{
            roundInfo[currentRound].maxEraTime = INIT_ROUND_ERA - diff;
            if (roundInfo[currentRound].maxEraTime < ROUND_INC) {
                roundInfo[currentRound].maxEraTime = ROUND_INC;
            }
        }

        // new donate
        if (donateAmount >= ticketPrice) {
            // set the last 6 users
            roundInfo[currentRound].lastUsers[
                roundInfo[currentRound].cursor
            ] = msg.sender;
            roundInfo[currentRound].cursor =
                (roundInfo[currentRound].cursor + 1) %
                6;

            if (
                roundInfo[currentRound].endTime + ROUND_INC >
                roundInfo[currentRound].maxEraTime + block.timestamp
            ) {
                roundInfo[currentRound].endTime =
                    roundInfo[currentRound].maxEraTime +
                    block.timestamp;
            } else {
                roundInfo[currentRound].endTime += ROUND_INC;
            }
        }

        // add to rewards pool
        roundInfo[currentRound].rewards += rewardFund;

        // buy ipshare
        uint256 recIPShares = IIPShare(IPShare).buyShares{value: ipshareFund}(
            subject,
            msg.sender
        );

        emit Donate(
            subject,
            msg.sender,
            donateAmount,
            recIPShares,
            tweetId,
            currentRound
        );
    }

    /**
     * @dev return the roundinfo
     * @return winners winners sorted from the last one: winners[0] is the last one
     */
    function getRoundInfo(
        uint256 round
    )
        public
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        RoundInfo memory _roundInfo = roundInfo[round];
        address[6] memory winners;
        for (uint8 i = 0; i < 6; i++) {
            winners[5 - i] = _roundInfo.lastUsers[(i + _roundInfo.cursor) % 6];
        }
        return (
            _roundInfo.rewards,
            _roundInfo.endTime,
            winners[0],
            winners[1],
            winners[2],
            winners[3],
            winners[4],
            winners[5]
        );
    }

    function getCurrentRoundInfo()
        public
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        return getRoundInfo(currentRound);
    }
}
