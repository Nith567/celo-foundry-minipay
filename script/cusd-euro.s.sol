// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BrokerDemoScript is Script {
    // Address of the already deployed BrokerDemo contract
    address public constant BROKER_DEMO =
        0x96CFA0E76Bd15d99A1230CA3955be5E677B746a6; // TODO: Replace with actual deployed address

    function setUp() public {}

    function run() public {
        // Get the private key from the environment
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);

        // Get the broker contract instance
        BrokerDemo demo = BrokerDemo(BROKER_DEMO);
        console.log("Using BrokerDemo at:", BROKER_DEMO);

        // Get token addresses
        address cUSD = demo.CUSD();
        address cEUR = 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73;
        console.log("cUSD address:", cUSD);
        console.log("cEUR address:", cEUR);

        // Get the user's address (will act as both owner and tenant)
        address user = vm.addr(userPrivateKey);
        console.log("User address:", user);

        // Get initial balances
        uint256 initialCUSDBalance = ERC20(cUSD).balanceOf(user);
        uint256 initialCEURBalance = ERC20(cEUR).balanceOf(user);
        console.log("Initial cUSD balance:", initialCUSDBalance);
        console.log("Initial cEUR balance:", initialCEURBalance);

        // List a property (owner wants cEUR)
        string memory hotelName = "Taj Mahal Hotel";
        string memory ipfsUrl = "ipfs://QmTajMahalHotelImage123";
        uint256 dailyRent = 3e16; // 0.01 cEUR (18 decimals)
        console.log("Listing property:", hotelName);
        demo.listProperty(hotelName, cEUR, dailyRent, ipfsUrl);

        // Get property details
        uint256 propertyId = demo.propertyCounter() - 1;
        (address owner, string memory name, address stablecoin, uint256 rent, string memory url, bool isActive) = 
            demo.getPropertyDetails(propertyId);
        console.log("Property Details:");
        console.log("Owner:", owner);
        console.log("property:", propertyId);
        console.log("Name:", name);
        console.log("Stablecoin:", stablecoin);
        console.log("Daily Rent:", rent);
        console.log("IPFS URL:", url);
        console.log("Is Active:", isActive);

        // // Approve the broker to spend cUSD
        // ERC20(cUSD).approve(BROKER_DEMO, type(uint256).max);
        // console.log("Approved broker to spend cUSD");

        // Pay rent for 1 day using cUSD
        uint256 daysToRent = 1;
        console.log("Paying rent for", daysToRent, "days...");
        console.log("Payment token (cUSD):", cUSD);
        console.log("Target token (cEUR):", cEUR);
        console.log("Amount to pay:", dailyRent);
        
        demo.payRent(propertyId, daysToRent, cUSD);

        // Get final balances
        uint256 finalCUSDBalance = ERC20(cUSD).balanceOf(user);
        uint256 finalCEURBalance = ERC20(cEUR).balanceOf(user);
        console.log("Final cUSD balance:", finalCUSDBalance);
        console.log("Final cEUR balance:", finalCEURBalance);
        console.log("cUSD spent:", initialCUSDBalance - finalCUSDBalance);
        console.log("cEUR received:", finalCEURBalance - initialCEURBalance);

        vm.stopBroadcast();
    }
}
