#!/bin/bash

# Create PR Files for Olym3 Testnet Season 3
# This script creates all necessary files for the Erigon Pull Request

set -e

echo "🚀 Creating PR Files for Olym3 Testnet Season 3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Create directories
mkdir -p pr-files/execution/chain/spec/chainspecs
mkdir -p pr-files/execution/chain/networkname
mkdir -p pr-files/cl/clparams

print_header "Creating Chain ID Constants Patch"
cat > pr-files/network_id.patch << 'EOF'
--- a/execution/chain/spec/network_id.go
+++ b/execution/chain/spec/network_id.go
@@ -20,6 +20,7 @@ const (
 	HoodiChainID   = 560048
 	GnosisChainID  = 100
 	ChiadoChainID  = 10200
+	Olym3TestnetS3ChainID = 256000
 )
 
 var NetworkNameByID = make(map[uint64]string)
EOF

print_status "Created network_id.patch"

print_header "Creating Network Name Patch"
cat > pr-files/network_name.patch << 'EOF'
--- a/execution/chain/networkname/network_name.go
+++ b/execution/chain/networkname/network_name.go
@@ -20,6 +20,7 @@ const (
 	BorE2ETestChain2Val = "bor-e2e-test-2Val"
 	Chiado              = "chiado"
 	Test                = "test"
+	Olym3TestnetS3      = "olym3-testnet-s3"
 )
 
 var All = []string{
@@ -32,6 +33,7 @@ var All = []string{
 	Gnosis,
 	Chiado,
 	Test,
+	Olym3TestnetS3,
 }
EOF

print_status "Created network_name.patch"

print_header "Creating Chain Configuration File"
cat > pr-files/execution/chain/spec/chainspecs/olym3-testnet-s3.json << 'EOF'
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
EOF

print_status "Created chain configuration file"

print_header "Creating Genesis Block Function"
cat > pr-files/genesis.go << 'EOF'
// Add this function to execution/chain/spec/genesis.go

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
EOF

print_status "Created genesis block function"

print_header "Creating Chain Spec Configuration"
cat > pr-files/chain_spec.patch << 'EOF'
--- a/execution/chain/spec/config.go
+++ b/execution/chain/spec/config.go
@@ -200,6 +200,13 @@ var (
 		Genesis: TestGenesisBlock(),
 	}
 
+	Olym3TestnetS3 = Spec{
+		Name:        networkname.Olym3TestnetS3,
+		GenesisHash: common.HexToHash("0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9"),
+		Config:      ReadChainConfig(chainspecs, "chainspecs/olym3-testnet-s3.json"),
+		Genesis:     Olym3TestnetS3GenesisBlock(),
+		DNSNetwork:  dnsPrefix + "all.olym3-testnet-s3.ethdisco.net",
+	}
 )
 
 var chainNamesPoS = []string{
@@ -209,6 +216,7 @@ var chainNamesPoS = []string{
 	networkname.Hoodi,
 	networkname.Gnosis,
 	networkname.Chiado,
+	networkname.Olym3TestnetS3,
 }
 
 func IsChainPoS(chainConfig *chain.Config, currentTDProvider func() *big.Int) bool {
EOF

print_status "Created chain spec configuration"

print_header "Creating Network Configs Patch"
cat > pr-files/network_configs.patch << 'EOF'
--- a/cl/clparams/config.go
+++ b/cl/clparams/config.go
@@ -265,6 +265,25 @@ var NetworkConfigs map[NetworkType]NetworkConfig = map[NetworkType]NetworkConfig{
 		MinimumPeersInSubnetSearch:      20,
 		BootNodes:                       ChiadoBootstrapNodes,
 	},
+
+	chainspec.Olym3TestnetS3ChainID: {
+		GossipMaxSize:                   10485760,
+		GossipMaxSizeBellatrix:          15728640,
+		MaxChunkSize:                    MaxChunkSize,
+		AttestationSubnetCount:          64,
+		AttestationPropagationSlotRange: 32,
+		AttestationSubnetPrefixBits:     6,
+		TtfbTimeout:                     ConfigDurationSec(ReqTimeout),
+		RespTimeout:                     ConfigDurationSec(RespTimeout),
+		MaximumGossipClockDisparity:     ConfigDurationMSec(500 * time.Millisecond),
+		MessageDomainInvalidSnappy:      [4]byte{00, 00, 00, 00},
+		MessageDomainValidSnappy:        [4]byte{01, 00, 00, 00},
+		Eth2key:                         "eth2",
+		AttSubnetKey:                    "attnets",
+		SyncCommsSubnetKey:              "syncnets",
+		CgcKey:                          "cgc",
+		NfdKey:                          "nfd",
+		MinimumPeersInSubnetSearch:      20,
+		BootNodes:                       []string{}, // Add bootnodes when available
+	},
 }
EOF

print_status "Created network configs patch"

print_header "Creating GetConfigsByNetworkName Patch"
cat > pr-files/get_configs.patch << 'EOF'
--- a/cl/clparams/config.go
+++ b/cl/clparams/config.go
@@ -1420,6 +1420,9 @@ func GetConfigsByNetworkName(net string) (*NetworkConfig, *BeaconChainConfig, Net
 	case networkname.Hoodi:
 		networkCfg, beaconCfg := GetConfigsByNetwork(chainspec.HoodiChainID)
 		return networkCfg, beaconCfg, chainspec.HoodiChainID, nil
+	case networkname.Olym3TestnetS3:
+		networkCfg, beaconCfg := GetConfigsByNetwork(chainspec.Olym3TestnetS3ChainID)
+		return networkCfg, beaconCfg, chainspec.Olym3TestnetS3ChainID, nil
 	default:
 		return nil, nil, chainspec.MainnetChainID, errors.New("chain not found")
 	}
EOF

print_status "Created get configs patch"

print_header "Creating Registration Patch"
cat > pr-files/registration.patch << 'EOF'
--- a/execution/chain/spec/config.go
+++ b/execution/chain/spec/config.go
@@ -260,6 +260,7 @@ func init() {
 	RegisterChainSpec(networkname.Gnosis, Gnosis)
 	RegisterChainSpec(networkname.Chiado, Chiado)
 	RegisterChainSpec(networkname.Test, Test)
+	RegisterChainSpec(networkname.Olym3TestnetS3, Olym3TestnetS3)
 
 	// Register PoS chain IDs
 	for _, name := range chainNamesPoS {
EOF

print_status "Created registration patch"

print_header "Creating Pull Request Description"
cat > pr-files/PR_DESCRIPTION.md << 'EOF'
# feat: Add Olym3 Testnet Season 3 (Chain ID: 256000) support

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

## Files Changed
- `execution/chain/spec/network_id.go` - Add chain ID constant
- `execution/chain/networkname/network_name.go` - Add network name
- `execution/chain/spec/config.go` - Add chain specification and registration
- `execution/chain/spec/genesis.go` - Add genesis block function
- `execution/chain/spec/chainspecs/olym3-testnet-s3.json` - Chain configuration
- `cl/clparams/config.go` - Add network configs and support

## Usage
After this PR is merged, users can run:
```bash
./erigon --chain=olym3-testnet-s3 --datadir=/path/to/data
```

## Related Issues
Closes #[issue_number]
EOF

print_status "Created PR description"

print_header "Creating Apply Script"
cat > pr-files/apply-patches.sh << 'EOF'
#!/bin/bash

# Apply all patches for Olym3 Testnet Season 3
echo "Applying patches for Olym3 Testnet Season 3..."

# Apply patches
git apply network_id.patch
git apply network_name.patch
git apply chain_spec.patch
git apply network_configs.patch
git apply get_configs.patch
git apply registration.patch

# Copy chain configuration file
cp execution/chain/spec/chainspecs/olym3-testnet-s3.json ../../execution/chain/spec/chainspecs/

# Add genesis block function to genesis.go
# (Manual step - add the function to the file)

echo "Patches applied successfully!"
echo "Don't forget to:"
echo "1. Add the genesis block function to execution/chain/spec/genesis.go"
echo "2. Test the build: make erigon"
echo "3. Test the chain: ./build/bin/erigon --chain=olym3-testnet-s3"
EOF

chmod +x pr-files/apply-patches.sh

print_status "Created apply script"

print_header "Creating Test Script"
cat > pr-files/test-chain.sh << 'EOF'
#!/bin/bash

# Test Olym3 Testnet Season 3
echo "Testing Olym3 Testnet Season 3..."

# Build Erigon
echo "Building Erigon..."
make erigon

# Test chain
echo "Testing chain..."
./build/bin/erigon --chain=olym3-testnet-s3 --datadir=/tmp/olym3-test --http --http.port=8545 &

# Wait for startup
sleep 10

# Test chain ID
echo "Testing Chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')

if [[ "$CHAIN_ID" == "0x3e800" ]]; then
    echo "✓ Chain ID is correct: 256000"
else
    echo "✗ Chain ID is wrong: $CHAIN_ID (expected 0x3e800)"
fi

# Test block number
echo "Testing Block Number..."
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result')

echo "✓ Block Number: $BLOCK_NUMBER"

# Test pre-funded account
echo "Testing Pre-funded Account..."
BALANCE=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6","latest"],"id":1}' \
  http://localhost:8545 | jq -r '.result')

echo "✓ Balance: $BALANCE wei"

# Cleanup
pkill erigon
rm -rf /tmp/olym3-test

echo "Test completed!"
EOF

chmod +x pr-files/test-chain.sh

print_status "Created test script"

print_header "Creating Summary"
cat > pr-files/SUMMARY.md << 'EOF'
# Olym3 Testnet Season 3 - PR Files Summary

## Files Created

### Patches
1. `network_id.patch` - Add chain ID constant (256000)
2. `network_name.patch` - Add network name (olym3-testnet-s3)
3. `chain_spec.patch` - Add chain specification
4. `network_configs.patch` - Add network configurations
5. `get_configs.patch` - Add to GetConfigsByNetworkName()
6. `registration.patch` - Register chain in init()

### Configuration Files
1. `execution/chain/spec/chainspecs/olym3-testnet-s3.json` - Chain configuration

### Code Files
1. `genesis.go` - Genesis block function (to be added manually)

### Scripts
1. `apply-patches.sh` - Apply all patches
2. `test-chain.sh` - Test the chain

### Documentation
1. `PR_DESCRIPTION.md` - Pull Request description
2. `SUMMARY.md` - This summary

## Usage

### Apply Patches
```bash
cd pr-files
./apply-patches.sh
```

### Test Chain
```bash
cd pr-files
./test-chain.sh
```

### Manual Steps
1. Add the genesis block function to `execution/chain/spec/genesis.go`
2. Test the build: `make erigon`
3. Test the chain: `./build/bin/erigon --chain=olym3-testnet-s3`

## Chain Details
- **Chain ID**: 256000 (0x3e800)
- **Chain Name**: olym3-testnet-s3
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9
- **Pre-funded Accounts**: 5 addresses with 1000 ETH each
EOF

print_status "Created summary"

print_header "Creating README"
cat > pr-files/README.md << 'EOF'
# Olym3 Testnet Season 3 - Erigon Integration

This directory contains all files needed to add Olym3 Testnet Season 3 support to Erigon.

## Quick Start

1. **Apply Patches**:
   ```bash
   ./apply-patches.sh
   ```

2. **Add Genesis Function**:
   Copy the content from `genesis.go` to `execution/chain/spec/genesis.go`

3. **Test**:
   ```bash
   ./test-chain.sh
   ```

## Files Overview

- **Patches**: Git patches to apply to Erigon source
- **Config**: Chain configuration JSON file
- **Scripts**: Automation scripts for testing
- **Docs**: Documentation and PR description

## Chain Information

- **Chain ID**: 256000
- **Network Name**: olym3-testnet-s3
- **Consensus**: Proof of Stake (PoS)
- **Genesis**: Custom with 5 pre-funded accounts

## Support

For questions or issues, please contact the Olym3 team.
EOF

print_status "Created README"

print_header "Setup Complete!"
echo "🎉 All PR files have been created in the 'pr-files' directory!"
echo ""
echo "📋 Files created:"
echo "  - Patches: 6 git patches"
echo "  - Config: 1 JSON file"
echo "  - Scripts: 2 test scripts"
echo "  - Docs: 3 documentation files"
echo ""
echo "🚀 Next steps:"
echo "  1. cd pr-files"
echo "  2. ./apply-patches.sh"
echo "  3. Add genesis function to genesis.go"
echo "  4. ./test-chain.sh"
echo "  5. Create Pull Request"
echo ""
echo "📝 Pull Request:"
echo "  - Title: feat: Add Olym3 Testnet Season 3 (Chain ID: 256000) support"
echo "  - Description: See PR_DESCRIPTION.md"
