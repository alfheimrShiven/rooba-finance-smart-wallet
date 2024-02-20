## Rooba Finance Smart Wallet 💳

**An ERC-4337 compatible smart wallet for Rooba Finance Users.**
<br/>

⚡️ The project provides a **non-bloated (no external SDK used) and extremely optimized** ERC-4337 smart account system customed made for Rooba Finance's specific requirements.

### Features

-   **Issue Smart Wallets**: All Rooba Finance users can have access to smart wallets which will provide an invisible wallet experience to our users.
-   **Wallet Deactivation**: Users can chose to deactivate their smart wallets whenever they chose to. Their ETH will be secured by our protocol and can be restored later.
-   **Wallet Reactivation**: Users can chose to reactivate their smart wallets whenever they chose to with all ETH restored back.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy Account Factory

```shell
$ forge script script/DeployAccountFactory.s.sol:DeployAccountFactory
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```