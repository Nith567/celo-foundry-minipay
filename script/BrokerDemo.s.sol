// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract BrokerDemoScript is Script {
    // Address of the already deployed BrokerDemo contract
    address public constant BROKER_DEMO = 0xa97d01cD202979e489bbA7569ACaAA84d4Cf5c82;

    function setUp() public {}

    function run() public {
        // Get the private key from the environment
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);
        // Get the broker contract instance
        BrokerDemo demo = BrokerDemo(BROKER_DEMO);
        console.log("Using BrokerDemo at:", BROKER_DEMO);

        // Get token addresses
        address cREAL = demo.CREAL();
        address cEUR = demo.CEUR();
        console.log("cREAL address:", cREAL);
        console.log("cEUR address:", cEUR);

        // Get the user's address
        address user = vm.addr(userPrivateKey);
        console.log("User address:", user);

        // Get initial balances
        uint256 initialCREALBalance = IERC20Metadata(cREAL).balanceOf(user);
        uint256 initialCEURBalance = IERC20Metadata(cEUR).balanceOf(user);
        console.log("Initial cREAL balance:", initialCREALBalance);
        console.log("Initial cEUR balance:", initialCEURBalance);

        // User 1 (event creator) lists an event with price 5e15
        string memory eventName = "Brazilamazontreckhotel";
        address stablecoin = cREAL;
        string memory eventDetails="ipfs://bafkreihv536dl4wjsrekyo3baclqyls75kozgc3jposl5x5yr3zyem5guq";
        uint256 pricePerPerson = 5e15;
        string memory ipfsImageUrl = "ipfs://bafkreiaijjzijufrqbsxbgtrssvtacjzkclrzsmbysd5zxd6qqdb4rzcye";
        demo.createEvent(eventName,eventDetails, stablecoin, pricePerPerson, ipfsImageUrl);
        console.log("Created event:", eventName);

        // Get the eventId (should be demo.eventCounter() - 1)
        uint256 eventId = demo.eventCounter() - 1;
        console.log("Event ID:", eventId);

        vm.stopBroadcast();

        // User 2 (tourist) pays for tickets using cUSD
        uint256 user2PrivateKey = vm.envUint("PRIVATE_KEY_U2");
        address user2 = vm.addr(user2PrivateKey);
        vm.startBroadcast(user2PrivateKey);
        address cUSD = demo.CUSD();
        uint256 initialCusdBalance = IERC20Metadata(cUSD).balanceOf(user2);
        console.log("User2 address:", user2);
        console.log("Initial cUSD balance (User2):", initialCusdBalance);

        uint256 quantity = 1;
        address paymentToken = cUSD;
        IERC20Metadata(paymentToken).approve(BROKER_DEMO, type(uint256).max);
        demo.buyTicket(eventId, quantity, paymentToken);
        console.log("User2 bought tickets for event using cUSD");

        // Fetch the NFT contract address from BrokerDemo
        address nftAddress = address(demo.nftMinter());
        console.log("NFT contract address:", nftAddress);

        // Query the user's NFT balance
        uint256 nftBalance = IERC721(nftAddress).balanceOf(user2);
        console.log("User2 NFT balance after mint:", nftBalance);

        // If at least one NFT, print the tokenURI for the latest minted token
        if (nftBalance > 0) {
            uint256 tokenId = nftBalance; // This assumes sequential minting and no burns
            string memory uri = IERC721Metadata(nftAddress).tokenURI(tokenId);
            console.log("TokenURI for latest ticket (User2):", uri);
        }

        // Get final balances for user2
        uint256 finalCusdBalance = IERC20Metadata(cUSD).balanceOf(user2);
        console.log("Final cUSD balance (User2):", finalCusdBalance);
        console.log("cUSD net change (User2):", int256(finalCusdBalance) - int256(initialCusdBalance));
        vm.stopBroadcast();

        // Get final balances
        uint256 finalCREALBalance = IERC20Metadata(cREAL).balanceOf(user);
        uint256 finalCEURBalance = IERC20Metadata(cEUR).balanceOf(user);
        console.log("Final cREAL balance:", finalCREALBalance);
        console.log("Final cEUR balance:", finalCEURBalance);
        console.log("cREAL net change:", int256(finalCREALBalance) - int256(initialCREALBalance));
        console.log("cEUR net change:", int256(finalCEURBalance) - int256(initialCEURBalance));
    }
}


//0.56 ani pettadu ankooo brazilil amazon pay