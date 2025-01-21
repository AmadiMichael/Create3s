// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Create3s
 * @author Michael Amadi <amadimichaeld@gmail.com>
 * @notice Cheaper Create3 deployments for small sized contracts.
 */

/**
 *  // Call the factory to get the init code (Top of the stack is at the left)
 *  PUSH0           // [0x00]
 *  PUSH0           // [0x00, 0x00]
 *  PUSH0           // [0x00, 0x00, 0x00]
 *  PUSH0           // [0x00, 0x00, 0x00, 0x00]
 *  PUSH0           // [0x00, 0x00, 0x00, 0x00, 0x00]
 *  CALLER          // [caller, 0x00, 0x00, 0x00, 0x00, 0x00]
 *  GAS             // [gas, caller, 0x00, 0x00, 0x00, 0x00, 0x00]
 *  CALL            // [success]
 *
 *  // If call failed revert
 *  PUSH1 0x0e      // [0x0e, success]
 *  JUMPI           // []
 *  PUSH0           // [0x00]
 *  PUSH0           // [0x00, 0x00]
 *  REVERT          // []
 *
 *  // Else jump here and continue execution
 *  JUMPDEST        // []
 *
 *  // Copy the init code returned from returndata location to memory
 *  RETURNDATASIZE  // [returndatasize]
 *  PUSH0           // [0x00, returndatasize]
 *  PUSH0           // [0x00, 0x00, returndatasize]
 *  RETURNDATACOPY  // []
 *
 *  // Return it from memory
 *  RETURNDATASIZE  // [returndatasize]
 *  PUSH0           // [0x00, returndatasize]
 *  RETURN          // []
 */
error Create3xDeploymentFailed();
error ExpectedAddressNotSameAsActualAddress();

contract Create3s {
    bytes private constant DEPLOYMENT_CODE = hex"5f5f5f5f5f335af1600e575f5ffd5b3d5f5f3e3d5ff3";
    bytes32 private constant CODE_HASH = keccak256(DEPLOYMENT_CODE);

    function create(bytes memory _initCode, bytes32 _salt) external payable returns (address x) {
        _storeCode(_initCode);

        address expected = _getAddressOf(_salt);
        bytes memory deploymentCode = DEPLOYMENT_CODE;
        assembly ("memory-safe") {
            x := create2(callvalue(), add(deploymentCode, 0x20), mload(deploymentCode), _salt)
            if iszero(x) {
                mstore(0x00, 0x85f83ed6) // Create3xDeploymentFailed()
                revert(0x1c, 0x04)
            }
            if sub(x, expected) {
                mstore(0x00, 0x187987c5) // ExpectedAddressNotSameAsActualAddress()
                revert(0x1c, 0x04)
            }
        }
    }

    function getAddressOf(bytes32 _salt) external view returns (address addr_) {
        return _getAddressOf(_salt);
    }

    function _getAddressOf(bytes32 _salt) internal view returns (address addr_) {
        bytes32 codeHash = CODE_HASH;
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, hex"ff")
            mstore(add(fmp, 0x01), shl(0x60, address()))
            mstore(add(fmp, 0x15), _salt)
            mstore(add(fmp, 0x35), codeHash)
            let hash := keccak256(fmp, 0x55)
            addr_ := and(hash, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function _storeCode(bytes memory _initCode) internal {
        assembly ("memory-safe") {
            function divUp(a, b) -> c {
                c := div(sub(add(a, b), 0x01), b)
            }

            let len := mload(_initCode)
            sstore(0x00, len)
            let iter := divUp(len, 0x20)
            let i := 0x01
            let dataOffset := add(_initCode, 0x20)
            for {} 1 {} {
                sstore(i, mload(dataOffset))

                dataOffset := add(dataOffset, 0x20)
                i := add(i, 1)
                if gt(i, iter) { break }
            }
        }
    }

    /// @dev Returns previously stored bytes from storage slot 0. Not abi.encoded.
    function _getCode() internal returns (bytes memory) {
        assembly {
            function divUp(a, b) -> c {
                c := div(sub(add(a, b), 0x01), b)
            }

            let len := sload(0x00)
            sstore(0x00, 0x00)

            let i := 0x01
            let o := 0x00
            let l := divUp(len, 0x20)
            for {} 1 {} {
                mstore(o, sload(i))

                o := add(o, 0x20)
                i := add(i, 0x01)
                if gt(i, l) { break }
            }

            return(0x00, len)
        }
    }

    fallback() external {
        _getCode();
    }
}
