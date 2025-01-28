// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Create3s
 * @author Michael Amadi <amadimichaeld@gmail.com>
 * @notice Cheaper Create3 deployments for small sized contracts.
 */

/**
 *  DEPLOYMENT_CODE
 *
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

/// ERRORS
error Create3xDeploymentFailed();
error ExpectedAddressNotSameAsActualAddress();
error CodeDeploymentFailed();
error InitCallFailed(bytes _data);

abstract contract Create3s {
    /// @dev bytes32(uint256(keccak256("create3s.storagestart")) + 1);
    /// @dev We use +1 instead of the conventional -1 because we want to store the runtime code starting from the next slot which would mean the direct hash of the slot will hold a value.
    bytes32 private constant CREATE3_RUNTIMECODE_LENGTH_SLOT =
        0x876fda392913547f01bbb8ccfe576f8f23aa1f117d767d634afdcd1dde0340f8;

    /// @dev CREATE3_RUNTIMECODE_LENGTH_SLOT + 1;
    bytes32 private constant CREATE3_RUNTIMECODE_START =
        0x876fda392913547f01bbb8ccfe576f8f23aa1f117d767d634afdcd1dde0340f9;

    /// @dev The init code deployed by Create3s which returns the runtime code from Create3's transient storage.
    bytes private constant DEPLOYMENT_CODE = hex"5f5f5f5f5f335af1600e575f5ffd5b3d5f5f3e3d5ff3";

    /// @dev The hash of the deployment code.
    bytes32 private constant CODE_HASH = 0xf9baecd271d3e1d395e8a99ffbeb132ec600282ce4e7600ef789bca0e46b3e31;

    /// @dev Stores the runtime code to return in transient storage and then creates the contract.
    function _storeAndCreate(bytes memory _runtimeCode, bytes32 _salt) internal returns (address addr_) {
        // Store the runtime code to return in transient storage.
        _storeCode(_runtimeCode);

        // Deploy the contract.
        addr_ = _create(_runtimeCode.length, _salt);
    }

    /// @dev Creates a contract using Create3s.
    /// @dev Note that the call to create2 here is reentrant safe as long as this contract's fallback function does not have additional logic in inheriting contracts,
    ///      since the deployer bytecode only calls back into this contract and returns the returned bytecode.
    function _create(uint256 _runtimeCodeLength, bytes32 _salt) internal returns (address addr_) {
        // Get the expected address of the deployment.
        address expected = _getAddressOf(_salt);

        // Get the deployment code for use in assembly.
        bytes memory deploymentCode = DEPLOYMENT_CODE;
        assembly ("memory-safe") {
            // Deploy the contract.
            addr_ := create2(callvalue(), add(deploymentCode, 0x20), mload(deploymentCode), _salt)

            // If the deployment failed, revert.
            if iszero(addr_) {
                mstore(0x00, 0x85f83ed6) // Create3xDeploymentFailed()
                revert(0x1c, 0x04)
            }

            // If the expected address is not the same as the actual address, revert.
            if sub(addr_, expected) {
                mstore(0x00, 0x187987c5) // ExpectedAddressNotSameAsActualAddress()
                revert(0x1c, 0x04)
            }

            // If the code size of the deployed contract is not the same as the runtime code inputted, revert.
            if sub(extcodesize(addr_), _runtimeCodeLength) {
                mstore(0x00, 0xfef82207) // CodeDeploymentFailed()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the expected address of the deployment.
    function _getAddressOf(bytes32 _salt) internal view returns (address addr_) {
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, hex"ff")
            mstore(add(fmp, 0x01), shl(0x60, address()))
            mstore(add(fmp, 0x15), _salt)
            mstore(add(fmp, 0x35), CODE_HASH)
            let hash := keccak256(fmp, 0x55)
            addr_ := and(hash, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    /// @dev Stores previously stored bytes from transient storage slot 1. Not abi encoded.
    /// @dev Length of the input is stored in transient storage slot 0.
    ///      Rest of the bytes are stored in subsequent transient storage slots.
    function _storeCode(bytes memory _runtimeCode) internal {
        assembly ("memory-safe") {
            function divUp(a, b) -> c {
                // No need to check that b != 0 since in all usages of `divUp` we never input b as 0.
                c := div(sub(add(a, b), 0x01), b)
            }

            // Get the length of the input.
            let len := mload(_runtimeCode)

            // Store the length in transient storage slot 0.
            tstore(CREATE3_RUNTIMECODE_LENGTH_SLOT, len)

            // Get the number of iterations needed to store the input.
            let iter := add(CREATE3_RUNTIMECODE_START, divUp(len, 0x20))

            // Starting transient storage slot to store the input.
            let i := CREATE3_RUNTIMECODE_START

            // Offset of the input in memory.
            let dataOffset := add(_runtimeCode, 0x20)

            // Store the input in transient storage.
            for {} 0x01 {} {
                tstore(i, mload(dataOffset))

                dataOffset := add(dataOffset, 0x20)
                i := add(i, 0x01)
                if gt(i, iter) { break }
            }
        }
    }

    /// @dev Returns previously stored bytes from transient storage slot 1. Not abi encoded.
    /// @dev Length of the value is stored in transient storage slot 0.
    ///      Rest of the bytes are stored in subsequent transient storage slots.
    ///      The return value is not abi encoded since it is intended to be returned as runtime code.
    function _clearAndReturnCode() internal {
        assembly {
            function divUp(a, b) -> c {
                // No need to check that b != 0 since in all usages of `divUp` we never input b as 0.
                c := div(sub(add(a, b), 0x01), b)
            }

            // Get the length of the value.
            let len := tload(CREATE3_RUNTIMECODE_LENGTH_SLOT)

            // Clear the length in transient storage slot 0.
            tstore(CREATE3_RUNTIMECODE_LENGTH_SLOT, 0x00)

            // Starting transient storage slot to get the value.
            let i := CREATE3_RUNTIMECODE_START

            // Starting offset to store the value in memory.
            let o := 0x00

            // Get the number of iterations needed to get the value.
            let l := add(CREATE3_RUNTIMECODE_START, divUp(len, 0x20))

            // Get the value from transient storage.
            for {} 0x01 {} {
                mstore(o, tload(i))

                o := add(o, 0x20)
                i := add(i, 0x01)
                if gt(i, l) { break }
            }

            // Return the value from memory.
            return(0x00, len)
        }
    }

    /// @dev Fallback function, can be overridden to support more features.
    /// @dev If overriding, ENSURE TO CALL `_clearAndReturnCode()`.
    ///      In this scenario a recommended solution is to store the precalculated contract address to be deployed
    ///      in transient storage, then only call _clearAndReturnCode() if msg.sender is that address and optionally
    ///      if calldatasize is 0 for instances where your new fallback use case might be called by the deployed contract after deployment.
    fallback() external {
        // Runs the beforeFallback function.
        _beforeClearAndReturnCode();

        // Clear and return the code.
        _clearAndReturnCode();
    }

    /// @dev This function runs before the `_clearAndReturnCode()` function is run in the fallback function.
    /// @dev This is useful for instances where you might want to run some logic before the code is returned to the contract being deployed.
    ///      Or, to have additional logic in the fallback function. This can be conveniently achieved by only calling `_clearAndReturnCode()` if msg.sender is the address of the deployed contract (ideally stored in transient storage).
    ///      and otherwise, running your logic and ending execution successfully that way `_clearAndReturnCode()` is not called.
    function _beforeClearAndReturnCode() internal virtual {}

    // forgefmt: disable-next-item
    /// @dev This function ends execution successfully.
    ///      Can be called after running your logic in the `_beforeClearAndReturnCode()` function if you need to return a value.
    function _endExecutionSuccessfully() internal pure { assembly("memory-safe") { stop() } }

    // forgefmt: disable-next-item
    /// @dev This function returns the value given to it, ending execution successfully also.
    ///      Can be called after running your logic in the `_beforeClearAndReturnCode()` function if you need to return a value.
    /// @dev All values that are expected to be abi decoded by the caller of this function should be abi encoded before using as input here.
    function _return(bytes memory _value) internal pure { assembly("memory-safe") { return(add(_value, 0x20), mload(_value)) } }
}
