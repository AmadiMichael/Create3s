## Create3s

Cheaper Create3 deployments for small sized contracts (<=3.65KB).

Create3 involves 2 contract deployments and 1 external call while `Create3s` involves only 1 contract deployment and 1 external call but with a couple of transient stores and loads. For small contracts, this is cheaper.

### Flow

- User calls `Create3s.create(code, salt)`
- `Create3s` stores `code` in transient storage
- `Create3s` deploys these set of bytes (`5f5f5f5f5f335af1600e575f5ffd5b3d5f5f3e3d5ff3`) via create2 and the `salt` input.
- The deployed bytes calls back into `Create3s` which returns `code` from transient storage.
- The deployed bytes returns `code` as the runtime code of the address.

This way, the salt is the only non-constant determinant of the resultant contract's address.
