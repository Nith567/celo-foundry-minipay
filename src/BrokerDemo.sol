// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IMentoRouter} from "./interfaces/IMentoRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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

// solhint-disable var-name-mixedcase
contract BrokerDemo {
    address public constant MENTO_ROUTER =
        0xBE729350F8CdFC19DB6866e8579841188eE57f67;
    address public constant BI_POOL_MANAGER =
        0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901;
    address public constant CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address public constant USDC = 0xcebA9300f2b948710d2653dD7B07f33A8B32118C;
    address public constant CEUR = 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73;
    address public constant CREAL = 0xe8537a3d056DA446677B9E9d6c5dB704EaAb4787;
    address public constant XOF=0x73F93dcc49cB8A239e2032663e9475dd5ef29A08;
    address public constant KES=0x456a3D042C0DbD3db53D5489e98dFb038553B0d0;
    address public constant BROKER = 0x777A8255cA72412f0d706dc03C9D1987306B4CaD;

    struct Property {
        address owner;
        string ownerName;
        address stablecoinAddress;
        uint256 dailyRent;
        string ipfsImageUrl;
        bool isActive;
    }

    struct OwnerDetails {
        uint256 propertyId;
        address owner;
        string ownerName;
        address stablecoinAddress; 
        uint256 dailyRent;
        string ipfsImageUrl;
        bool isActive;
    }

    uint256 public propertyCounter;
    mapping(uint256 => Property) public properties;

    event PropertyListed(uint256 indexed propertyId, address owner, string ownerName, address stablecoinAddress, uint256 dailyRent);
    event RentPaid(uint256 indexed propertyId, address tenant, uint256 amount, address paymentToken);

    constructor() {
        propertyCounter = 1;
    }

    function listProperty(
        string memory _ownerName,
        address _stablecoinAddress,
        uint256 _dailyRent,
        string memory _ipfsImageUrl
    ) external {
        uint256 propertyId = propertyCounter;
        properties[propertyId] = Property({
            owner: msg.sender,
            ownerName: _ownerName,
            stablecoinAddress: _stablecoinAddress,
            dailyRent: _dailyRent,
            ipfsImageUrl: _ipfsImageUrl,
            isActive: true
        });

        emit PropertyListed(propertyId, msg.sender, _ownerName, _stablecoinAddress, _dailyRent);
        propertyCounter++;
    }

    function getPropertyDetails(uint256 _propertyId) external view returns (
        address owner,
        string memory ownerName,
        address stablecoinAddress,
        uint256 dailyRent,
        string memory ipfsImageUrl,
        bool isActive
    ) {
        Property memory property = properties[_propertyId];
        return (
            property.owner,
            property.ownerName,
            property.stablecoinAddress,
            property.dailyRent,
            property.ipfsImageUrl,
            property.isActive
        );
    }

    function payRent(uint256 _propertyId, uint256 _days, address _paymentToken) external {
        Property memory property = properties[_propertyId];
        require(property.isActive, "Property not active");
        require(_days > 0, "Days must be greater than 0");

        uint256 totalRent = property.dailyRent * _days;

        if (_paymentToken == property.stablecoinAddress) {
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, property.owner, totalRent);
        } else if ( property.stablecoinAddress == USDC) {
            // Approve the Broker to spend cUSD
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, address(this), totalRent);
            IERC20Metadata(_paymentToken).approve(BROKER, totalRent);
            bytes32 firstExchangeId = keccak256(
                abi.encodePacked(
                    IERC20Metadata(_paymentToken).symbol(),
                    IERC20Metadata(USDC).symbol(),
                    "ConstantSum"
                )
            );
            uint256 usdcOut = IBroker(BROKER).swapIn(
                BI_POOL_MANAGER,
                firstExchangeId,//pool between cusd and usdc
                _paymentToken,
                USDC,
                totalRent,
                0 // amountOutMin
            );

            IERC20Metadata(USDC).transfer(property.owner, usdcOut);
        } else {
            // Two-step swap for other token combinations
            bytes32 firstExchangeId = keccak256(
                abi.encodePacked(
                    IERC20Metadata(_paymentToken).symbol(),
                    IERC20Metadata(USDC).symbol(),
                    "ConstantSum"
                )
            );
            bytes32 secondExchangeId = keccak256(
                abi.encodePacked(
                    IERC20Metadata(property.stablecoinAddress).symbol(),
                    IERC20Metadata(USDC).symbol(),
                    "ConstantSum"
                )
            );

            IMentoRouter.Step[] memory path = new IMentoRouter.Step[](2);
            path[0] = IMentoRouter.Step({
                exchangeProvider: BI_POOL_MANAGER,
                exchangeId: firstExchangeId,
                assetIn: _paymentToken,
                assetOut: USDC
            });
            path[1] = IMentoRouter.Step({
                exchangeProvider: BI_POOL_MANAGER,
                exchangeId: secondExchangeId,
                assetIn: USDC,
                assetOut: property.stablecoinAddress
            });

            IERC20Metadata(_paymentToken).transferFrom(msg.sender, address(this), totalRent);
            IERC20Metadata(_paymentToken).approve(MENTO_ROUTER, totalRent);

            IMentoRouter(MENTO_ROUTER).swapExactTokensForTokens(
                totalRent,
                0, // minimum amount out
                path
            );

            IERC20Metadata(property.stablecoinAddress).transfer(
                property.owner,
                IERC20Metadata(property.stablecoinAddress).balanceOf(address(this))
            );
        }

        emit RentPaid(_propertyId, msg.sender, totalRent, _paymentToken);
    }

    function deactivateProperty(uint256 _propertyId) external {
        require(properties[_propertyId].owner == msg.sender, "Not property owner");
        properties[_propertyId].isActive = false;
    }

    function getAllOwnersDetails() external view returns (OwnerDetails[] memory) {
        uint256 totalProperties = propertyCounter - 1; // propertyCounter starts at 1
        OwnerDetails[] memory allDetails = new OwnerDetails[](totalProperties);
        
        for (uint256 i = 1; i <= totalProperties; i++) {
            Property memory property = properties[i];
            allDetails[i-1] = OwnerDetails({
                propertyId: i,
                owner: property.owner,
                ownerName: property.ownerName,
                stablecoinAddress: property.stablecoinAddress,
                dailyRent: property.dailyRent,
                ipfsImageUrl: property.ipfsImageUrl,
                isActive: property.isActive
            });
        }
        
        return allDetails;
    }
}
