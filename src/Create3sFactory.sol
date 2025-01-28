// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// IMPORTS
import {Create3s} from "src/Create3s.sol";

/// ERRORS
error InitCallFailed(bytes _data);

contract Create3sFactory is Create3s {
    /// @notice Creates a contract using Create3s.
    /// @param _runtimeCode The runtime code of the contract to deploy.
    /// @param _salt The salt to use for the deployment.
    /// @return addr_ The address of the deployed contract.
    function create(bytes memory _runtimeCode, bytes32 _salt) external payable returns (address addr_) {
        // Deploy the contract.
        addr_ = _storeAndCreate(_runtimeCode, _salt);
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
        addr_ = _storeAndCreate(_runtimeCode, _salt);

        // Call the deployed contract with the initialization calldata.
        bool success;
        (success, data_) = addr_.call(_initCalldata);
        if (!success) revert InitCallFailed(data_);
    }

    /// @notice Returns the expected address of the deployment.
    /// @param _salt The salt to use for the deployment.
    /// @return addr_ The expected address of the deployment.
    function getAddressOf(bytes32 _salt) external view returns (address addr_) {
        addr_ = _getAddressOf(_salt);
    }
}
