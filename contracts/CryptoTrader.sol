pragma solidity >=0.4.21 <0.7.0;

import "./CryptoTraderInternal.sol";

/// @title Contract to challenge your trader friends with virtual coin. Real ether is needed to join competition.
/// @author Quentin Brunet, Pierre Piron, Léo Legron, Prescilla Lecurieux
/// @notice Student project, may contain bugs and security issues.
contract CryptoTrader is CryptoTraderInternal {
    /// @notice Allow trader to join a competition with a small participation fee.
    function joinCompetition(
        uint _competitionId
    ) external payable isFutureCompetition(_competitionId) isNotParticipant(msg.sender, _competitionId) {
        require(participationFee == msg.value, "Please send the required participation fee");
        competitionToTraders[_competitionId].push(msg.sender);
    }

    /// @notice Allow trader to leave a competition (refund the participation fee).
    function leaveCompetition(
        uint _competitionId
    ) external isFutureCompetition(_competitionId) isParticipant(msg.sender, _competitionId) {
        uint index = _findIndexOf(competitionToTraders[_competitionId], msg.sender);
        _removeAtIndex(competitionToTraders[_competitionId], index);
        msg.sender.transfer(participationFee);
    }

    /// @notice Allow trader to make a trader (buy or sell).
    /// @param _buy (true => buy / false => sell)
    /// @param _weiAmount (real currency amount to buy/sell in Wei)
    function trade(
        bool _buy,
        uint _weiAmount
    ) external isParticipant(msg.sender, currentCompetition) hasSufficientBalance(_buy, msg.sender, _weiAmount) {
        uint virtualCurrencyAmount = _getVirtualCurrencyAmount(_weiAmount);

        if (_buy) {
            competitionToTraderToCurrencyToBalance[currentCompetition][msg.sender][virtualCurrency] -= virtualCurrencyAmount;
            competitionToTraderToCurrencyToBalance[currentCompetition][msg.sender][realCurrency] += _weiAmount;
        } else {
            competitionToTraderToCurrencyToBalance[currentCompetition][msg.sender][virtualCurrency] += virtualCurrencyAmount;
            competitionToTraderToCurrencyToBalance[currentCompetition][msg.sender][realCurrency] -= _weiAmount;
        }
    }

    /// @notice Check if competition can be closed.
    /// @return bool
    function isCompetitionClosable() external view isClosable returns (bool) {
        return true;
    }

    /// @notice Allow trader to close current competition. Start the next competition straight after.
    function closeCompetition() external isClosable isParticipant(msg.sender, currentCompetition) {
        address[] memory traders = competitionToTraders[currentCompetition];
        uint[] memory balances = new uint[](traders.length);


        for (uint i = 0; i < traders.length; i++) {
            balances[i] = _getTotalBalance(currentCompetition, traders[i]);
        }

        address payable winner = _getWinner(traders, balances);

        winner.transfer(address(this).balance);

        emit CloseCompetition(winner, traders, balances);

        _restartCompetition();
    }

    /// @notice Get trader for given competition.
    /// @return address[]
    function getTraders(uint _competitionId) external view returns (address[] memory) {
        return competitionToTraders[_competitionId];
    }
}
