// SPDX-License-Identifier: GPL-3.0-or-later
//
// DssKilnUNIV2 - Burn Module for Uniswap V2
//
// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./DssKiln.sol";

interface UniswapRouterV3Like {
      function exactInputSingle(
        ExactInputSingleParams calldata params
        ) external returns (uint256 amountOut);
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

contract DssKilnUNIV3Saver is DssKiln {

    address public immutable uniV3Router;
    address public immutable receiver;

    constructor(address _uniV3Router, address _receiver) public DssKiln() {
        uniV3Router = _uniV3Router;
        receiver = _receiver;
    }

    function _swap(uint256 _amount) internal override returns (uint256 _swapped) {
        require(GemLike(DAI).approve(uniV3Router, _amount));

        ExactInputSingleParams memory params = ExactInputSingleParams(
            DAI,             // tokenIn
            MKR,             // tokenOut
            3000,            // fee
            address(this),   // recipient
            block.timestamp, // deadline
            _amount,         // amountIn
            1,               // amountOutMinimum
            0                // sqrtPriceLimitX96
        );

        _swapped = UniswapRouterV3Like(uniV3Router).exactInputSingle(params);
        require(GemLike(MKR).balanceOf(address(this)) >= _swapped, "DssKilnUNIV3/swapped-balance-not-available");
    }

    /**
        @dev Transfer the purchased token to the receiver
     */
    function _drop(uint256 _amount) internal override {
        GemLike(MKR).transfer(receiver, _amount);
    }
}
