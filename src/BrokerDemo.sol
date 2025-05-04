// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IMentoRouter} from "./interfaces/IMentoRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./EventTicketNFT.sol";

interface IBroker {
    function swapIn(
        address exchangeProvider,
        bytes32 exchangeId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut);
}

interface IMentoOracle {
    function medianRate(address rateFeedId) external view returns (uint256, uint256);
}

contract BrokerDemo {
    address public constant MENTO_ROUTER = 0xBE729350F8CdFC19DB6866e8579841188eE57f67;
    address public constant BI_POOL_MANAGER = 0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901;
    address public constant USDC = 0xcebA9300f2b948710d2653dD7B07f33A8B32118C;
    address public constant BROKER = 0x777A8255cA72412f0d706dc03C9D1987306B4CaD;
    address public constant CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address public constant CEUR = 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73;
    address public constant CREAL = 0xe8537a3d056DA446677B9E9d6c5dB704EaAb4787;
    address public constant XOF = 0x73F93dcc49cB8A239e2032663e9475dd5ef29A08;
    address public constant KES = 0x456a3D042C0DbD3db53D5489e98dFb038553B0d0;
    
    // Mento Oracle for rate calculations on celo mainnet
    IMentoOracle public constant ORACLE = IMentoOracle(0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33);
    
    EventTicketNFT public nftMinter;

    constructor() {
        nftMinter = new EventTicketNFT();
        eventCounter = 1;
    }

    struct EventSpot {
        address creator;
        string eventName;
        string eventDetails;
        address stablecoinAddress;
        uint256 pricePerPerson;
        string ipfsImageUrl;
        bool isActive;
    }

    uint256 public eventCounter;
    mapping(uint256 => EventSpot) public eventSpots;

    event EventCreated(uint256 indexed eventId, string eventName, address creator, uint256 pricePerPerson);
    event TicketBought(uint256 indexed eventId, address buyer, uint256 quantity, address tokenUsed, uint256 amountPaid);

    function createEvent(
        string memory _eventName,
        string memory _eventDetails,
        address _stablecoinAddress,
        uint256 _pricePerPerson,
        string memory _ipfsImageUrl
    ) external {
        uint256 eventId = eventCounter;
        eventSpots[eventId] = EventSpot({
            creator: msg.sender,
            eventName: _eventName,
            eventDetails: _eventDetails,
            stablecoinAddress: _stablecoinAddress,
            pricePerPerson: _pricePerPerson,
            ipfsImageUrl: _ipfsImageUrl,
            isActive: true
        });

        emit EventCreated(eventId, _eventName, msg.sender, _pricePerPerson);
        eventCounter++;
    }
    
    // Calculate cross rate between two stablecoins using CELO as the bridge
    function getCrossRate(address tokenA, address tokenB) public view returns (uint256) {
        // Get rates for both tokens against CELO
        (uint256 rateA, ) = ORACLE.medianRate(tokenA);
        (uint256 rateB, ) = ORACLE.medianRate(tokenB);
        
        // Calculate cross rate with high precision
        uint256 precision = 1e18;
        
        // To get tokenA/tokenB rate, we divide rateA by rateB
        return (rateA * precision) / rateB;
    }
    
    // Convert an amount from one token to another using the cross rate
    function convertAmount(address fromToken, address toToken, uint256 amount) public view returns (uint256) {
        if (fromToken == toToken) {
            return amount;
        }
        
        uint256 crossRate = getCrossRate(fromToken, toToken);
        uint256 precision = 1e18;
        
        // Convert the amount using the cross rate
        return (amount * crossRate) / precision;
    }

    function buyTicket(uint256 _eventId, uint256 _quantity, address _paymentToken) external {
        EventSpot memory spot = eventSpots[_eventId];
        require(spot.isActive, "Event not active");
        require(_quantity > 0, "Invalid quantity");

        // Calculate base price in the event's stablecoin
        uint256 basePrice = spot.pricePerPerson * _quantity;
        
        // Calculate how much the user needs to pay in their chosen payment token
        uint256 amountToPayInPaymentToken;
        
        if (_paymentToken == spot.stablecoinAddress) {
            // Same token, no conversion needed
            amountToPayInPaymentToken = basePrice;
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, spot.creator, amountToPayInPaymentToken);
        } else {
            // Different token, convert the amount
            amountToPayInPaymentToken = convertAmount(spot.stablecoinAddress, _paymentToken, basePrice);
            
            // Transfer the payment token from user to this contract
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, address(this), amountToPayInPaymentToken);
            
            if (spot.stablecoinAddress == USDC) {
                // Direct swap to USDC
                IERC20Metadata(_paymentToken).approve(BROKER, amountToPayInPaymentToken);
                bytes32 exId = keccak256(abi.encodePacked(IERC20Metadata(_paymentToken).symbol(), "USDC", "ConstantSum"));

                uint256 usdcOut = IBroker(BROKER).swapIn(
                    BI_POOL_MANAGER,
                    exId,
                    _paymentToken,
                    USDC,
                    amountToPayInPaymentToken,
                    0
                );

                IERC20Metadata(USDC).transfer(spot.creator, usdcOut);
            } else {
                // Path swap via USDC as intermediary
                bytes32 ex1 = keccak256(abi.encodePacked(IERC20Metadata(_paymentToken).symbol(), "USDC", "ConstantSum"));
                bytes32 ex2 = keccak256(abi.encodePacked(IERC20Metadata(spot.stablecoinAddress).symbol(), "USDC", "ConstantSum"));

                IMentoRouter.Step[] memory path = new IMentoRouter.Step[](2);
                path[0] = IMentoRouter.Step({exchangeProvider: BI_POOL_MANAGER, exchangeId: ex1, assetIn: _paymentToken, assetOut: USDC});
                path[1] = IMentoRouter.Step({exchangeProvider: BI_POOL_MANAGER, exchangeId: ex2, assetIn: USDC, assetOut: spot.stablecoinAddress});

                IERC20Metadata(_paymentToken).approve(MENTO_ROUTER, amountToPayInPaymentToken);

                IMentoRouter(MENTO_ROUTER).swapExactTokensForTokens(amountToPayInPaymentToken, 0, path);

                IERC20Metadata(spot.stablecoinAddress).transfer(
                    spot.creator,
                    IERC20Metadata(spot.stablecoinAddress).balanceOf(address(this))
                );
            }
        }
        nftMinter.mintTicket(msg.sender, spot.ipfsImageUrl, spot.eventName, _eventId, _quantity);

        emit TicketBought(_eventId, msg.sender, _quantity, _paymentToken, amountToPayInPaymentToken);
    }

    function deactivateEvent(uint256 _eventId) external {
        require(eventSpots[_eventId].creator == msg.sender, "Not event owner");
        eventSpots[_eventId].isActive = false;
    }

    function getAllEvents() external view returns (EventSpot[] memory) {
        uint256 total = eventCounter - 1;
        EventSpot[] memory all = new EventSpot[](total);
        for (uint256 i = 1; i <= total; i++) {
            all[i - 1] = eventSpots[i];
        }
        return all;
    }
}