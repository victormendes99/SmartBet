// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

enum MatchStatus {
    Upcoming,
    Live,
    Finished
}

enum MatchResult {
    Home,
    Draw,
    Away
}

/**
 * @title MatchBet
 * @dev Struct to hold the betting details for a match, including odds and player bets.
 * This struct includes mappings to track player bets and can only be used in internal or library functions.
 * @param oddHome The betting odds for the home team winning.
 * @param oddDraw The betting odds for the match resulting in a draw.
 * @param oddAway The betting odds for the away team winning.
 * @param amountBetHome The total amount of bets placed on the home team.
 * @param amountBetDraw The total amount of bets placed on a draw.
 * @param amountBetAway The total amount of bets placed on the away team.
 * @param totalBetsHome The number of individual bets placed on the home team.
 * @param totalBetsDraw The number of individual bets placed on a draw.
 * @param totalBetsAway The number of individual bets placed on the away team.
 * @param playersHome A mapping of player addresses to the amounts they have bet on the home team.
 * @param playersDraw A mapping of player addresses to the amounts they have bet on a draw.
 * @param playersAway A mapping of player addresses to the amounts they have bet on the away team.
 */
struct MatchBet {
    uint256 oddHome;
    uint256 oddDraw;
    uint256 oddAway;
    uint256 amountBetHome;
    uint256 amountBetDraw;
    uint256 amountBetAway;
    uint256 totalBetsHome;
    uint256 totalBetsDraw;
    uint256 totalBetsAway;
    mapping(address => uint256[]) playersHome;
    mapping(address => uint256[]) playersDraw;
    mapping(address => uint256[]) playersAway;
}

/**
 * @title Match
 * @dev Struct to hold the comprehensive information about a match, including betting details.
 * This struct includes mappings to track player bets and can only be used in internal or library functions.
 * Match represents now just Football games, but in the future, it can be used for any game like basketball, volleyball, fight, etc.
 * @param hash The unique hash identifier of the match.
 * @param teamHome The name of the home team.
 * @param teamAway The name of the away team.
 * @param stadium The name of the stadium where the match will be held.
 * @param date The date of the match as a Unix timestamp.
 * @param goalsHome The number of goals scored by the home team at the end of the match.
 * @param goalsAway The number of goals scored by the away team at the end of the match.
 * @param status The current status of the match (Upcoming, Live, Finished).
 * @param result The result of the match (Home win, Draw, Away win).
 * @param matchBet The betting details for the match, including odds and player bets.
 */
struct Match {
    bytes32 hash;
    string teamHome;
    string teamAway;
    string stadium;
    uint256 date;
    uint256 goalsHome;
    uint256 goalsAway;
    MatchStatus status;
    MatchResult result;
    MatchBet matchBet;
}

/**
 * @title MatchInfo
 * @dev Struct to hold the essential information about a match, excluding mappings.
 * Used for returning match information in functions where mappings cannot be included.
 * @param hash The unique hash identifier of the match.
 * @param teamHome The name of the home team.
 * @param teamAway The name of the away team.
 * @param date The date of the match as a Unix timestamp.
 * @param stadium The name of the stadium where the match will be held.
 * @param goalsHome The number of goals scored by the home team at the end of the match.
 * @param goalsAway The number of goals scored by the away team at the end of the match.
 * @param status The current status of the match (Upcoming, Live, Finished).
 * @param result The result of the match (Home win, Draw, Away win).
 * @param oddHome The betting odds for the home team winning.
 * @param oddDraw The betting odds for the match resulting in a draw.
 * @param oddAway The betting odds for the away team winning.
 */
struct MatchInfo {
    bytes32 hash;
    string teamHome;
    string teamAway;
    uint256 date;
    string stadium;
    uint256 goalsHome;
    uint256 goalsAway;
    MatchStatus status;
    MatchResult result;
    uint256 oddHome;
    uint256 oddDraw;
    uint256 oddAway;
}

/**
 * @title SmartBet
 * @author victormendes99
 * @dev A smart contract for creating and managing bets on sports matches.
 * Inherits from AccessControl to manage roles and permissions.
 */
contract SmartBet is AccessControl {
    bytes32[] private s_upcomingMatches; // keep upcoming match hashs
    bytes32[] private s_liveMatches; // keep live match hashs
    bytes32[] private s_finishedMatches; // keep finished match hashs

    mapping(bytes32 => Match) private s_matches; // all matches are stored on that mapping
    mapping(address => uint256[]) private s_playerBets; // all games of a player
    mapping(bytes32 => address[]) private s_betPlayers; // all players in a game

    bytes32 private constant FUNCTIONS_ROLE = keccak256("FUNCTIONS_ROLE"); // role to SmartBetFunctions call some functions on that contract

    // events
    event SmartBet_NewMatchCreated(
        bytes32 hash,
        string teamHome,
        string teamAway,
        string stadium,
        uint256 date,
        uint256 oddHome,
        uint256 oddDraw,
        uint256 oddAway,
        uint256 upComingMatchesLength
    );

    event SmartBet_MatchStatusUpdated(
        string teamHome,
        string teamAway,
        string stadium,
        uint256 date,
        MatchStatus status
    );

    // functions

    /**
     * @dev Initializes the contract by granting the FUNCTIONS_ROLE to the specified address.
     * @param _smartBetFunctionsContract The address of the contract to be granted the FUNCTIONS_ROLE.
     */
    constructor(address _smartBetFunctionsContract) {
        _grantRole(FUNCTIONS_ROLE, _smartBetFunctionsContract);
    }

    /**
     * @dev Retrieves detailed information about a specific match identified by `_hash`.
     * Requirements
     * - The match with the specified `_hash` must exist.
     *
     * @param _hash The unique hash identifier of the match to be retrieved.
     *
     * @return _matchInfo A struct containing detailed information about the match.
     *
     */
    function getMatch(bytes32 _hash) external view returns (MatchInfo memory) {
        require(
            s_matches[_hash].hash !=
                bytes32(
                    0x0000000000000000000000000000000000000000000000000000000000000000
                ),
            "The match does not exist."
        );
        MatchInfo memory _matchInfo = MatchInfo({
            hash: s_matches[_hash].hash,
            teamHome: s_matches[_hash].teamHome,
            teamAway: s_matches[_hash].teamAway,
            date: s_matches[_hash].date,
            stadium: s_matches[_hash].stadium,
            goalsHome: s_matches[_hash].goalsHome,
            goalsAway: s_matches[_hash].goalsAway,
            status: s_matches[_hash].status,
            result: s_matches[_hash].result,
            oddHome: s_matches[_hash].matchBet.oddHome,
            oddDraw: s_matches[_hash].matchBet.oddDraw,
            oddAway: s_matches[_hash].matchBet.oddAway
        });
        return _matchInfo;
    }

    /**
     * @dev Returns an array of all upcoming matches.
     * @return An array of `MatchInfo` structs representing all upcoming matches.
     * Reverts with a message if there are no upcoming matches.
     */
    function getUpcomingMatches() external view returns (MatchInfo[] memory) {
        require(
            s_upcomingMatches.length > 0,
            "No upcoming matches to bet on currently."
        );

        MatchInfo[] memory _upcomingMatches = new MatchInfo[](
            s_upcomingMatches.length
        );
        for (uint256 i = 0; i < s_upcomingMatches.length; i++) {
            Match storage _match = s_matches[s_upcomingMatches[i]];
            MatchInfo memory _matchInfo = MatchInfo({
                hash: _match.hash,
                teamHome: _match.teamHome,
                teamAway: _match.teamAway,
                date: _match.date,
                stadium: _match.stadium,
                goalsHome: _match.goalsHome,
                goalsAway: _match.goalsAway,
                status: _match.status,
                result: _match.result,
                oddHome: _match.matchBet.oddHome,
                oddDraw: _match.matchBet.oddDraw,
                oddAway: _match.matchBet.oddAway
            });
            _upcomingMatches[i] = _matchInfo;
        }

        return _upcomingMatches;
    }

    /**
     * @dev Creates a new match with the given parameters and initializes the betting odds.
     * Only callable by contracts that have FUNCTIONS_ROLE.
     * @param _teamHome The name of the home team.
     * @param _teamAway The name of the away team.
     * @param _date The date of the match.
     * @param _stadium The name of the stadium where the match will be held.
     * @param _oddHome The betting odds for the home team winning.
     * @param _oddDraw The betting odds for the match resulting in a draw.
     * @param _oddAway The betting odds for the away team winning.
     * @return The unique identifier of the newly created match.
     */
    function createNewMatch(
        string memory _teamHome,
        string memory _teamAway,
        string memory _stadium,
        uint256 _date,
        uint16 _oddHome,
        uint16 _oddDraw,
        uint16 _oddAway
    ) external onlyRole(FUNCTIONS_ROLE) returns (bytes32) {
        bytes32 _newHash = _getMatchHash(_teamHome, _teamAway, _date);
        require(
            s_matches[_newHash].hash ==
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "The match already exist."
        );

        Match storage _match = s_matches[_newHash];
        _match.hash = _newHash;
        _match.teamHome = _teamHome;
        _match.teamAway = _teamAway;
        _match.date = _date;
        _match.stadium = _stadium;
        _match.status = MatchStatus.Upcoming;

        _match.matchBet.oddHome = _oddHome;
        _match.matchBet.oddDraw = _oddDraw;
        _match.matchBet.oddAway = _oddAway;

        s_upcomingMatches.push(_newHash);

        emit SmartBet_NewMatchCreated(
            _match.hash,
            _match.teamHome,
            _match.teamAway,
            _match.stadium,
            _match.date,
            _match.matchBet.oddHome,
            _match.matchBet.oddDraw,
            _match.matchBet.oddAway,
            s_upcomingMatches.length
        );
        return _match.hash;
    }

    /**
     * @dev Updates the status of a match identified by `_hash`.
     * Only callable by contracts that have the `FUNCTIONS_ROLE`.
     * Requirements
     * - The match must exist (`_hash` should refer to an existing match).
     * - The `_status` cannot be `Upcoming` if the match is already created.
     * - If `_status` is `Live`, the match must be in the `Upcoming` list.
     * - If `_status` is `Finished`, the match must be in the `Live` list.
     *
     * @param _hash The unique hash identifier of the match to be updated.
     * @param _status The new status to set for the match.
     *
     * @return MatchStatus The updated status of the match.
     *
     */
    function updateMatchStatus(
        bytes32 _hash,
        MatchStatus _status
    ) external onlyRole(FUNCTIONS_ROLE) returns (MatchStatus) {
        require(
            s_matches[_hash].hash !=
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "The match does not exist."
        );
        require(
            MatchStatus.Upcoming != _status,
            "Match cannot be updated to Upcoming status."
        );
        if (MatchStatus.Live == _status) {
            (bool exists, uint256 index) = _contains(_hash, s_upcomingMatches);
            require(
                exists,
                "Match must be in the Upcoming list to be updated to Live."
            );
            s_upcomingMatches[index] = s_upcomingMatches[
                s_upcomingMatches.length - 1
            ];
            s_matches[_hash].status = MatchStatus.Live;
            s_upcomingMatches.pop();
            s_liveMatches.push(_hash);
        }
        if (MatchStatus.Finished == _status) {
            (bool exists, uint256 index) = _contains(_hash, s_liveMatches);
            require(
                exists,
                "Match must be in the Live list to be updated to Finished."
            );
            s_matches[_hash].status = MatchStatus.Finished;
            s_liveMatches[index] = s_liveMatches[s_liveMatches.length - 1];
            s_liveMatches.pop();
            s_finishedMatches.push(_hash);
        }

        emit SmartBet_MatchStatusUpdated(
            s_matches[_hash].teamHome,
            s_matches[_hash].teamAway,
            s_matches[_hash].stadium,
            s_matches[_hash].date,
            s_matches[_hash].status
        );

        return s_matches[_hash].status;
    }

    // function _resolveMatch(bytes32 _hash) private returns (bytes32) {
    //     Match storage _match = s_matches[_hash];
    //     require(
    //         _match.status == MatchStatus.Live,
    //         "Match must be in the Live state."
    //     );
    //     address[] memory players = s_betPlayers[_match.hash];
    //     for (uint256 i = 0; i < players.length; i++) {}
    // }

    /**
     * @dev Checks if a given `_hash` exists within the provided `list`.
     *
     * @param _hash The hash identifier to search for within the list.
     * @param list The array of hash identifiers to search through.
     *
     * @return (bool, uint256) A tuple where the first value is `true` if the `_hash` is found in the list,
     *         and `false` otherwise. The second value is the index of the found element, or `0` if not found.
     */
    function _contains(
        bytes32 _hash,
        bytes32[] memory list
    ) private pure returns (bool, uint256) {
        for (uint256 i = 0; i < list.length; i++) {
            if (_hash == list[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Generates a unique hash for a match based on the home team name, away team name, and date.
     * This function is used to create a unique identifier for each match.
     *
     * @param _teamHome The name of the home team.
     * @param _teamAway The name of the away team.
     * @param _date The date of the match as a Unix timestamp.
     *
     * @return A unique hash identifier for the match.
     */
    function _getMatchHash(
        string memory _teamHome,
        string memory _teamAway,
        uint256 _date
    ) private pure returns (bytes32) {
        string memory _concatNames = string.concat(_teamHome, _teamAway);
        return keccak256(abi.encodePacked(_concatNames, _date));
    }
}
