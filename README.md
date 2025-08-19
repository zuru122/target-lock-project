# AUTOR: Sunday, Justice Gabriel
## Project: TargetLock

### Goal:
* A smart contract TargetLock that allows you to save your funds and only withdraw it when your goal set is met. Goal can be amount you aim to save or a particular time you want to withdraw your funds.
  
* The project is built in phases, as I implement and check them as I go

### Step 1:
* Implement the targetAmount
* owner can only withdraw once targert amount is reached or funds is above target amount
* owner can not withdraw more than the saved amount

### Step 2:
* Date-based withdrawal restriction adds more realistic use cases and state handling.

### Step 3
* Multiple savers logic – right now, only the owner can withdraw; expand so each user can set their own target and withdraw individually.

### Step 1 and 3"Done"

<!-- Interaction -->
## Interaction
* ```$ forge script script/DeployTargetLock.s.sol```
* ```$ forge test```



# TOOL
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
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

### Deploy


```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
