// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

interface IMentoRouter {
    /// @notice Structure defining a single step in the swap path
    /// @param exchangeProvider The address of the exchange provider
    /// @param exchangeId The unique identifier for the exchange
    /// @param assetIn The address of the input asset
    /// @param assetOut The address of the output asset
    struct Step {
        address exchangeProvider;
        bytes32 exchangeId;
        address assetIn;
        address assetOut;
    }

    /// @notice Swap an exact amount of input tokens for as many output tokens as possible
    /// @param amountIn The amount of input tokens to swap
    /// @param amountOutMin The minimum amount of output tokens that must be received
    /// @param path An array of Step structs defining the swap path
    /// @return amounts The amounts of tokens for each step in the path
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Step[] calldata path
    ) external returns (uint256[] memory amounts);

    /// @notice Swap as few input tokens as possible for an exact amount of output tokens
    /// @param amountOut The exact amount of output tokens needed
    /// @param amountInMax The maximum amount of input tokens that can be spent
    /// @param path An array of Step structs defining the swap path
    /// @return amounts The amounts of tokens for each step in the path
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        Step[] calldata path
    ) external returns (uint[] memory amounts);

    /// @notice Get the output amount for a given input amount and path
    /// @param amountIn The amount of input tokens to swap
    /// @param path An array of Step structs defining the swap path
    /// @return amountOut The calculated amount of output tokens
    function getAmountOut(
        uint256 amountIn,
        Step[] calldata path
    ) external view returns (uint256 amountOut);

    /// @notice Get the input amount for a given output amount and path
    /// @param amountOut The exact amount of output tokens needed
    /// @param path An array of Step structs defining the swap path
    /// @return amountIn The calculated amount of input tokens
    function getAmountIn(
        uint256 amountOut,
        Step[] calldata path
    ) external view returns (uint256 amountIn);

    /// @notice Drain all of the contract's balance of a given asset to the reserve multisig
    /// @param asset The address of the asset to drain
    function drain(address asset) external;
}