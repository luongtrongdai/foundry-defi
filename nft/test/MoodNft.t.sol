// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {Test, console} from "forge-std/Test.sol";
import {MoodNftScript} from "script/MoodNft.s.sol";
import {MoodNft} from "src/MoodNft.sol";

contract MoodNftTest is Test {
    address private USER = makeAddr("user");
    MoodNft private moodNft;

    modifier mint() {
        vm.prank(USER);
        moodNft.mintNft();
        _;
    }
    function setUp() external {
        MoodNftScript script = new MoodNftScript();

        script.run();
        moodNft = script.moodNft();
    }

    function test_Mint() external mint {
        string memory tokenUri = moodNft.tokenURI(0);
        assertEq(tokenUri, 
            "data:application/json;base64,eyJuYW1lIjogIk1vb2QgTkZUIiwgImRlc2NyaXB0aW9uIjogIk15IGRlbW8gTkZUIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTWpBd0lESXdNQ0lnZDJsa2RHZzlJalF3TUNJZ0lHaGxhV2RvZEQwaU5EQXdJaUI0Yld4dWN6MGlhSFIwY0RvdkwzZDNkeTUzTXk1dmNtY3ZNakF3TUM5emRtY2lQZzBLSUNBOFkybHlZMnhsSUdONFBTSXhNREFpSUdONVBTSXhNREFpSUdacGJHdzlJbmxsYkd4dmR5SWdjajBpTnpnaUlITjBjbTlyWlQwaVlteGhZMnNpSUhOMGNtOXJaUzEzYVdSMGFEMGlNeUl2UGcwS0lDQThaeUJqYkdGemN6MGlaWGxsY3lJK0RRb2dJQ0FnUEdOcGNtTnNaU0JqZUQwaU56QWlJR041UFNJNE1pSWdjajBpTVRJaUx6NE5DaUFnSUNBOFkybHlZMnhsSUdONFBTSXhNamNpSUdONVBTSTRNaUlnY2owaU1USWlMejROQ2lBZ1BDOW5QZzBLSUNBOGNHRjBhQ0JrUFNKdE1UTTJMamd4SURFeE5pNDFNMk11TmprZ01qWXVNVGN0TmpRdU1URWdOREl0T0RFdU5USXRMamN6SWlCemRIbHNaVDBpWm1sc2JEcHViMjVsT3lCemRISnZhMlU2SUdKc1lXTnJPeUJ6ZEhKdmEyVXRkMmxrZEdnNklETTdJaTgrRFFvOEwzTjJaejQ9IiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIm1vb2RpbmVzcyIsInZhbHVlIjogMTAwfV19");
    }

    function test_FlipMood() external mint {
        vm.prank(USER);
        moodNft.flipMood(0);

        console.log(moodNft.tokenURI(0));
    }
}
