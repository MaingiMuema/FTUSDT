// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanReceiver {
    /**
     * @dev Executes custom logic after receiving a flash loan
     * @param amount The amount of tokens received
     * @param fee The fee that must be repaid on top of the amount
     * @param params Additional parameters for custom logic
     * @return success Whether the operation was successful
     */
    function executeOperation(
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external returns (bool);
}
