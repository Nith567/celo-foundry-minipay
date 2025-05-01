// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";

contract BrokerDemoDeploy is Script {    
    // Contract instance
    BrokerDemo public brokerDemo;
    
    function setUp() public {}
    
    function run() public {
        // Get the private key from the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the BrokerDemo contract
        brokerDemo = new BrokerDemo();
        console.log("BrokerDemo deployed at:", address(brokerDemo));
        
        vm.stopBroadcast();
    }
} 