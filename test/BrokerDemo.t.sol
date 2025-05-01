// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BrokerDemo} from "../src/BrokerDemo.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMentoRouter} from "../src/interfaces/IMentoRouter.sol";

contract BrokerDemoTest is Test {
    BrokerDemo public brokerDemo;
    address public constant MENTO_ROUTER =
        0xBE729350F8CdFC19DB6866e8579841188eE57f67;
    address public constant BI_POOL_MANAGER =
        0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901;
    address public constant CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address public constant USDC = 0xcebA9300f2b948710d2653dD7B07f33A8B32118C;
    address public constant CEUR = 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73;

    // Test addresses
    address public OWNER = makeAddr("OWNER");
    address public TENANT = makeAddr("TENANT");

    function setUp() public {
        // Create a fork of Celo mainnet
        vm.createSelectFork(vm.envString("CELO_MAINNET_RPC_URL"));

        // Deploy the broker contract
        brokerDemo = new BrokerDemo();

        // Mint CUSD to the tenant
        deal(CUSD, TENANT, 1000 * 10 ** 18);
    }

    function testConstants() public view {
        assertEq(
            brokerDemo.MENTO_ROUTER(),
            MENTO_ROUTER,
            "MentoRouter address should match"
        );
        assertEq(
            brokerDemo.BI_POOL_MANAGER(),
            BI_POOL_MANAGER,
            "BiPoolManager address should match"
        );
        assertEq(brokerDemo.CUSD(), CUSD, "CUSD address should match");
        assertEq(brokerDemo.USDC(), USDC, "USDC address should match");
        assertEq(brokerDemo.CEUR(), CEUR, "CEUR address should match");
    }

    function testRentPaymentCUSDToCEUR() public {
        // Get initial balances
        uint256 initialTenantCUSDBalance = IERC20Metadata(CUSD).balanceOf(TENANT);
        uint256 initialOwnerCEURBalance = IERC20Metadata(CEUR).balanceOf(OWNER);

        // Property details
        string memory ownerName = "John Doe";
        uint256 dailyRent = 10 * 10 ** 18; // 10 CUSD per day
        string memory ipfsUrl = "ipfs://QmExample";

        // List the property
        vm.startPrank(OWNER);
        brokerDemo.listProperty(ownerName, CEUR, dailyRent, ipfsUrl);
        vm.stopPrank();

        // Get property details
        (
            address owner,
            string memory storedOwnerName,
            address stablecoinAddress,
            uint256 storedDailyRent,
            string memory storedIpfsUrl,
            bool isActive
        ) = brokerDemo.getPropertyDetails(1);

        // Verify property details
        assertEq(owner, OWNER, "Owner address should match");
        assertEq(storedOwnerName, ownerName, "Owner name should match");
        assertEq(stablecoinAddress, CEUR, "Stablecoin address should be CEUR");
        assertEq(storedDailyRent, dailyRent, "Daily rent should match");
        assertEq(storedIpfsUrl, ipfsUrl, "IPFS URL should match");
        assertTrue(isActive, "Property should be active");

        // Prepare for rent payment
        vm.startPrank(TENANT);
        IERC20Metadata(CUSD).approve(address(brokerDemo), type(uint256).max);

        // Calculate expected CEUR amount
        uint256 daysToPay = 7;
        uint256 totalRentCUSD = dailyRent * daysToPay;

        // Get expected CEUR amount through the swap path
        IMentoRouter.Step[] memory path = new IMentoRouter.Step[](2);
        bytes32 CUSD_USDC_ExchangeId = keccak256(
            abi.encodePacked(
                IERC20Metadata(CUSD).symbol(),
                IERC20Metadata(USDC).symbol(),
                "ConstantSum"
            )
        );
        bytes32 USDC_CEUR_ExchangeId = keccak256(
            abi.encodePacked(
                IERC20Metadata(USDC).symbol(),
                IERC20Metadata(CEUR).symbol(),
                "ConstantSum"
            )
        );

        path[0] = IMentoRouter.Step({
            exchangeProvider: BI_POOL_MANAGER,
            exchangeId: CUSD_USDC_ExchangeId,
            assetIn: CUSD,
            assetOut: USDC
        });
        path[1] = IMentoRouter.Step({
            exchangeProvider: BI_POOL_MANAGER,
            exchangeId: USDC_CEUR_ExchangeId,
            assetIn: USDC,
            assetOut: CEUR
        });

        uint256 expectedCEUR = IMentoRouter(MENTO_ROUTER).getAmountOut(totalRentCUSD, path);

        // Pay rent for 7 days
        brokerDemo.payRent(1, daysToPay, CUSD);

        // Check final balances
        uint256 finalTenantCUSDBalance = IERC20Metadata(CUSD).balanceOf(TENANT);
        uint256 finalOwnerCEURBalance = IERC20Metadata(CEUR).balanceOf(OWNER);

        // Verify balances changed as expected
        assertEq(
            finalTenantCUSDBalance,
            initialTenantCUSDBalance - totalRentCUSD,
            "Tenant's CUSD balance should decrease by total rent"
        );
        assertApproxEqRel(
            finalOwnerCEURBalance - initialOwnerCEURBalance,
            expectedCEUR,
            1e16, // 1% tolerance
            "Owner's CEUR balance should increase by expected amount"
        );
    }
}
