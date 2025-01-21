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
error InitCallFailed();

contract Create3s {
    bytes private constant DEPLOYMENT_CODE = hex"5f5f5f5f5f335af1600e575f5ffd5b3d5f5f3e3d5ff3";
    bytes32 private constant CODE_HASH = keccak256(DEPLOYMENT_CODE);

    /// @notice Creates a contract using Create3s.
    /// @param _runtimeCode The runtime code of the contract to deploy.
    /// @param _salt The salt to use for the deployment.
    /// @return addr_ The address of the deployed contract.
    function create(bytes memory _runtimeCode, bytes32 _salt) external payable returns (address addr_) {
        // Deploy the contract.
        addr_ = _create(_runtimeCode, _salt);
    }

    /// @notice Creates a contract using Create3s and calls it with the given initialization calldata.
    /// @param _runtimeCode The runtime code of the contract to deploy.
    /// @param _salt The salt to use for the deployment.
    /// @param _initCalldata The initialization calldata to call the deployed contract with after deployment.
    /// @return addr_ The address of the deployed contract.
    function createAndInit(bytes memory _runtimeCode, bytes32 _salt, bytes memory _initCalldata)
        external
        payable
        returns (address addr_, bytes memory data_)
    {
        // Deploy the contract.
        addr_ = _create(_runtimeCode, _salt);

        // Call the deployed contract with the initialization calldata.
        bool success;
        (success, data_) = addr_.call(_initCalldata);
        require(success, InitCallFailed());
    }

    /// @notice Returns the expected address of the deployment.
    /// @param _salt The salt to use for the deployment.
    /// @return addr_ The expected address of the deployment.
    function getAddressOf(bytes32 _salt) external view returns (address addr_) {
        return _getAddressOf(_salt);
    }

    /// @dev Creates a contract using Create3s.
    function _create(bytes memory _runtimeCode, bytes32 _salt) internal returns (address addr_) {
        // Store the runtime code to return in transient storage.
        _storeCode(_runtimeCode);

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
            if sub(extcodesize(addr_), mload(_runtimeCode)) {
                mstore(0x00, 0xfef82207) // CodeDeploymentFailed()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the expected address of the deployment.
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

    /// @dev Stores previously stored bytes from transient storage slot 1. Not abi encoded.
    /// @dev Length of the input is stored in transient storage slot 0.
    ///      Rest of the bytes are stored in subsequent transient storage slots.
    function _storeCode(bytes memory _runtimeCode) internal {
        assembly ("memory-safe") {
            function divUp(a, b) -> c {
                c := div(sub(add(a, b), 0x01), b)
            }

            // Get the length of the input.
            let len := mload(_runtimeCode)

            // Store the length in transient storage slot 0.
            tstore(0x00, len)

            // Get the number of iterations needed to store the input.
            let iter := divUp(len, 0x20)

            // Starting transient storage slot to store the input.
            let i := 0x01

            // Offset of the input in memory.
            let dataOffset := add(_runtimeCode, 0x20)

            // Store the input in transient storage.
            for {} 1 {} {
                tstore(i, mload(dataOffset))

                dataOffset := add(dataOffset, 0x20)
                i := add(i, 1)
                if gt(i, iter) { break }
            }
        }
    }

    /// @dev Returns previously stored bytes from transient storage slot 1. Not abi encoded.
    /// @dev Length of the value is stored in transient storage slot 0.
    ///      Rest of the bytes are stored in subsequent transient storage slots.
    ///      The return value is not abi encoded since it is intended to be returned as runtime code.
    fallback() external {
        assembly {
            function divUp(a, b) -> c {
                c := div(sub(add(a, b), 0x01), b)
            }

            // Get the length of the value.
            let len := tload(0x00)

            // Clear the length in transient storage slot 0.
            tstore(0x00, 0x00)

            // Starting transient storage slot to get the value.
            let i := 0x01

            // Starting offset to store the value in memory.
            let o := 0x00

            // Get the number of iterations needed to get the value.
            let l := divUp(len, 0x20)

            // Get the value from transient storage.
            for {} 1 {} {
                mstore(o, tload(i))

                o := add(o, 0x20)
                i := add(i, 0x01)
                if gt(i, l) { break }
            }

            // Return the value from memory.
            return(0x00, len)
        }
    }
}
