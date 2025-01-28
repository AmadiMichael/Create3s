// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Create3sFactory} from "src/Create3sFactory.sol";
import {Create3, B} from "test/mock/Create3.sol";

contract Create3sTest is Test {
    Create3sFactory public create3s;

    // bytecode that returns everything after it.
    bytes private constant RETURNER = hex"600b80380380915f395ff3";

    function setUp() public {
        create3s = new Create3sFactory();
    }

    function test_bench_print_create3_and_create3s_create() external {
        uint256 salt = 0;

        console2.log("| Code Size (bytes) | `Create3s` Gas | Create3 Gas |");
        console2.log("| ----------------- | ------------ | ----------- |");
        for (uint256 i; i < 4_000; i += 50) {
            bytes memory code = vm.randomBytes(i);
            code = _filterCode(code);

            create3s.create(code, bytes32(salt));
            uint256 create3sGasUsed = vm.lastCallGas().gasTotalUsed;

            B b = new B();
            b.c(bytes.concat(RETURNER, code), bytes32(salt++));
            uint256 create3GasUsed = vm.lastCallGas().gasTotalUsed;

            console2.log("%s | %s | %s", i, create3sGasUsed, create3GasUsed);
        }
    }

    function test_bench_print_create3_and_create3s_getAddressOf(bytes32 _salt) external {
        create3s.getAddressOf(_salt);
        uint256 create3sGasUsed = vm.lastCallGas().gasTotalUsed;

        B b = new B();
        b.getAddressOf(_salt);
        uint256 create3GasUsed = vm.lastCallGas().gasTotalUsed;

        console2.log("%s | %s", create3sGasUsed, create3GasUsed);
    }

    /// @dev The last output is the smallest length of code to deploy whereby using create3s is cheaper than create3.
    /// @dev Currently at 3744 bytes or 3.65KB
    function test_bench_create3_and_create3s() external {
        uint256 salt;

        uint256 l = 1;
        uint256 r = 24 * 1024;

        while (true) {
            uint256 i = (l + r) / 2;
            bytes memory code = vm.randomBytes(i);
            code = _filterCode(code);

            create3s.create(code, bytes32(salt));
            uint256 create3sGasUsed = vm.lastCallGas().gasTotalUsed;

            B b = new B();
            b.c(bytes.concat(RETURNER, code), bytes32(salt++));
            uint256 create3GasUsed = vm.lastCallGas().gasTotalUsed;

            console2.log("length:", i);
            console2.log("gas used create3s:", create3sGasUsed);
            console2.log("gas used create3:", create3GasUsed);
            console2.log("\n");

            if (r - l <= 1) {
                break;
            }

            if (create3sGasUsed > create3GasUsed) {
                r = i;
            } else {
                l = i;
            }
        }
    }

    function test_create3(bytes memory _code, bytes32 _salt) external {
        _code = _filterCode(_code);

        address expected = create3s.getAddressOf(_salt);
        address actual = create3s.create(_code, _salt);

        assertEq(expected, actual, "expected and actual should be the same");
        assertEq(expected.code, _code, "not same code");
    }

    uint256 constant ITERATIONS = 100;

    /// @dev This tests that as long as a given address is not a contract yet, i.e nonce > 0 AND code size is 0,
    ///      the same salt that created it initially CAN be used to deploy ANY code to it again.
    function test_create_destruct_redeploy(bytes32 _salt, bytes[ITERATIONS + 1] memory _initCodes) external {
        console2.log("Creating contract");
        address c = create3s.create(_filterCode(_initCodes[ITERATIONS]), _salt);

        for (uint256 i; i < ITERATIONS; ++i) {
            console2.log("erasing contract");
            destroyAccount(c, address(0));

            console2.log("Creating contract again");
            address d = create3s.create(_filterCode(_initCodes[i]), _salt);

            assertEq(d, c, "d and c should be the same");
            c = d;

            console2.log("iteration %d", i);
        }
    }

    function test_create3s_initialize(bytes32 _salt, uint256 _v) external {
        (address x, bytes memory data) =
            create3s.createAndInit(type(A).runtimeCode, _salt, abi.encodeCall(A.initialize, _v));

        assertEq(A(x).v(), _v, "v should be set correctly");
        assertTrue(abi.decode(data, (bool)), "initialize call should return true");
    }

    function _filterCode(bytes memory _code) private pure returns (bytes memory) {
        if (_code.length > 0 && _code[0] == hex"ef") {
            _code[0] = hex"60";
        }
        return _code;
    }
}

contract A {
    error NotInitialized();

    bool public initialized;
    uint256 public v;

    modifier initializer() {
        initialized = true;
        _;
    }

    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    function initialize(uint256 _v) external initializer returns (bool) {
        v = _v;
        return true;
    }

    function setV(uint256 _v) external onlyInitialized {
        v = _v;
    }
}
