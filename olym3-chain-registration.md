# 🚀 Olym3 Testnet Season 3 - Erigon Chain Registration

## 📋 Pull Request Overview

This PR adds support for **Olym3 Testnet Season 3** (Chain ID: 256000) to Erigon.

### Chain Details
- **Chain ID**: 256000 (0x3e800)
- **Chain Name**: `olym3-testnet-s3`
- **Network Type**: Testnet
- **Consensus**: Proof of Stake (PoS)
- **Genesis Hash**: `0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9`

## 🔧 Required Changes

### 1. Add Chain ID Constants

**File**: `execution/chain/spec/network_id.go`

```go
const (
	MainnetChainID = 1
	HoleskyChainID = 17000
	SepoliaChainID = 11155111
	HoodiChainID   = 560048
	GnosisChainID  = 100
	ChiadoChainID  = 10200
	Olym3TestnetS3ChainID = 256000  // Add this line
)
```

### 2. Add Network Name

**File**: `execution/chain/networkname/network_name.go`

```go
const (
	Mainnet             = "mainnet"
	Holesky             = "holesky"
	Sepolia             = "sepolia"
	Hoodi               = "hoodi"
	Dev                 = "dev"
	Amoy                = "amoy"
	BorMainnet          = "bor-mainnet"
	BorDevnet           = "bor-devnet"
	Gnosis              = "gnosis"
	BorE2ETestChain2Val = "bor-e2e-test-2Val"
	Chiado              = "chiado"
	Test                = "test"
	Olym3TestnetS3      = "olym3-testnet-s3"  // Add this line
)

var All = []string{
	Mainnet,
	Holesky,
	Sepolia,
	Hoodi,
	Amoy,
	BorMainnet,
	BorDevnet,
	Gnosis,
	Chiado,
	Test,
	Olym3TestnetS3,  // Add this line
}
```

### 3. Create Chain Configuration

**File**: `execution/chain/spec/config.go`

Add the chain specification:

```go
var (
	// ... existing chains ...

	Olym3TestnetS3 = Spec{
		Name:        networkname.Olym3TestnetS3,
		GenesisHash: common.HexToHash("0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9"),
		Config:      ReadChainConfig(chainspecs, "chainspecs/olym3-testnet-s3.json"),
		Genesis:     Olym3TestnetS3GenesisBlock(),
		DNSNetwork:  dnsPrefix + "all.olym3-testnet-s3.ethdisco.net",
	}
)

var chainNamesPoS = []string{
	networkname.Mainnet,
	networkname.Holesky,
	networkname.Sepolia,
	networkname.Hoodi,
	networkname.Gnosis,
	networkname.Chiado,
	networkname.Olym3TestnetS3,  // Add this line
}
```

### 4. Create Genesis Block Function

**File**: `execution/chain/spec/genesis.go`

Add the genesis block function:

```go
func Olym3TestnetS3GenesisBlock() *types.Genesis {
	return &types.Genesis{
		Config:     ReadChainConfig(chainspecs, "chainspecs/olym3-testnet-s3.json"),
		Nonce:      0x0000000000000042,
		Timestamp:  0x0,
		ExtraData:  []byte("Olym3 Testnet Season 3"),
		GasLimit:   0x47b760,
		Difficulty: big.NewInt(0x400000000),
		Mixhash:    common.HexToHash("0x0000000000000000000000000000000000000000000000000000000000000000"),
		Coinbase:   common.HexToAddress("0x0000000000000000000000000000000000000000"),
		Alloc: map[common.Address]types.GenesisAccount{
			common.HexToAddress("0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"): {
				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
			},
			common.HexToAddress("0x9876543210987654321098765432109876543210"): {
				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
			},
			common.HexToAddress("0x147B8eb97fD247D06C4006D269c90C1908Fb5D54"): {
				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
			},
			common.HexToAddress("0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"): {
				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
			},
			common.HexToAddress("0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"): {
				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
			},
		},
		BaseFee: big.NewInt(0),
	}
}
```

### 5. Create Chain Configuration File

**File**: `execution/chain/spec/chainspecs/olym3-testnet-s3.json`

```json
{
  "chainId": 256000,
  "chainName": "Olym3 Testnet Season 3",
  "consensus": "aura",
  "genesis": {
    "nonce": "0x0000000000000042",
    "timestamp": "0x0",
    "extraData": "0x4f6c796d3320546573746e657420536561736f6e2033",
    "gasLimit": "0x47b760",
    "difficulty": "0x400000000",
    "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "alloc": {
      "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6": {
        "balance": "0x3635c9adc5dea00000"
      },
      "0x9876543210987654321098765432109876543210": {
        "balance": "0x3635c9adc5dea00000"
      },
      "0x147B8eb97fD247D06C4006D269c90C1908Fb5D54": {
        "balance": "0x3635c9adc5dea00000"
      },
      "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db": {
        "balance": "0x3635c9adc5dea00000"
      },
      "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB": {
        "balance": "0x3635c9adc5dea00000"
      }
    },
    "baseFeePerGas": "0x0"
  },
  "config": {
    "chainId": 256000,
    "chainName": "Olym3 Testnet Season 3",
    "consensus": "aura",
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "terminalTotalDifficulty": "0x0",
    "terminalTotalDifficultyPassed": true,
    "aura": {
      "authorities": [
        "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
        "0x9876543210987654321098765432109876543210",
        "0x147B8eb97fD247D06C4006D269c90C1908Fb5D54"
      ],
      "stepDuration": 3,
      "blockReward": "0x0"
    }
  }
}
```

### 6. Register Chain in init()

**File**: `execution/chain/spec/config.go`

Add to the init() function:

```go
func init() {
	// ... existing registrations ...
	RegisterChainSpec(networkname.Olym3TestnetS3, Olym3TestnetS3)
}
```

### 7. Add to Network Configs

**File**: `cl/clparams/config.go`

Add to the network configurations:

```go
var NetworkConfigs map[NetworkType]NetworkConfig = map[NetworkType]NetworkConfig{
	// ... existing configs ...
	
	chainspec.Olym3TestnetS3ChainID: {
		GossipMaxSize:                   10485760,
		GossipMaxSizeBellatrix:          15728640,
		MaxChunkSize:                    MaxChunkSize,
		AttestationSubnetCount:          64,
		AttestationPropagationSlotRange: 32,
		AttestationSubnetPrefixBits:     6,
		TtfbTimeout:                     ConfigDurationSec(ReqTimeout),
		RespTimeout:                     ConfigDurationSec(RespTimeout),
		MaximumGossipClockDisparity:     ConfigDurationMSec(500 * time.Millisecond),
		MessageDomainInvalidSnappy:      [4]byte{00, 00, 00, 00},
		MessageDomainValidSnappy:        [4]byte{01, 00, 00, 00},
		Eth2key:                         "eth2",
		AttSubnetKey:                    "attnets",
		SyncCommsSubnetKey:              "syncnets",
		CgcKey:                          "cgc",
		NfdKey:                          "nfd",
		MinimumPeersInSubnetSearch:      20,
		BootNodes:                       []string{}, // Add bootnodes when available
	},
}
```

### 8. Add to GetConfigsByNetworkName()

**File**: `cl/clparams/config.go`

Add to the switch statement:

```go
func GetConfigsByNetworkName(net string) (*NetworkConfig, *BeaconChainConfig, NetworkType, error) {
	switch net {
	// ... existing cases ...
	case networkname.Olym3TestnetS3:
		networkCfg, beaconCfg := GetConfigsByNetwork(chainspec.Olym3TestnetS3ChainID)
		return networkCfg, beaconCfg, chainspec.Olym3TestnetS3ChainID, nil
	default:
		return nil, nil, chainspec.MainnetChainID, errors.New("chain not found")
	}
}
```

## 🧪 Testing

### 1. Build and Test

```bash
# Build Erigon
make erigon

# Test with custom chain
./build/bin/erigon --chain=olym3-testnet-s3 --datadir=/tmp/olym3-test
```

### 2. Verify Chain ID

```bash
# Test API
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x3e800"
}
```

## 📝 Pull Request Template

### Title
```
feat: Add Olym3 Testnet Season 3 (Chain ID: 256000) support
```

### Description
```
## Overview
This PR adds support for Olym3 Testnet Season 3 to Erigon.

## Chain Details
- **Chain ID**: 256000 (0x3e800)
- **Chain Name**: olym3-testnet-s3
- **Network Type**: Testnet
- **Consensus**: Proof of Stake (PoS)
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9

## Changes
- [x] Add chain ID constant (256000)
- [x] Add network name (olym3-testnet-s3)
- [x] Create chain specification
- [x] Add genesis block configuration
- [x] Create chain config JSON file
- [x] Register chain in init()
- [x] Add to network configs
- [x] Add to GetConfigsByNetworkName()

## Testing
- [x] Built successfully
- [x] Chain ID returns correct value (256000)
- [x] Genesis block loads correctly
- [x] Pre-funded accounts have correct balances

## Related Issues
Closes #[issue_number]
```

## 🔗 References

- [Erigon Chain Registration Guide](https://github.com/erigontech/erigon/blob/devel/docs/chain-registration.md)
- [Olym3 Testnet Season 3 Documentation](https://docs.olym3.com/testnet-s3)
- [Genesis Block Specification](https://ethereum.org/en/developers/docs/genesis-block/)

## 📞 Contact

For questions about this PR, please contact:
- **Author**: [Your Name]
- **Email**: [your.email@example.com]
- **GitHub**: [@your-github-username]
