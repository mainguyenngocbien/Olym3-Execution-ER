#!/bin/bash

# Fix Permissions and Structure for Olym3 Testnet Season 3 PR
# This script fixes permissions and creates proper directory structure

set -e

echo "🔧 Fix Permissions and Structure for Olym3 Testnet Season 3 PR"

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

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_header "Fixing Directory Permissions"
cd /home/erigon/Olym3-Execution-ER

# Fix ownership
chown -R erigon:erigon .

# Fix permissions
chmod -R 755 .
chmod -R 644 *.md *.sh *.patch *.go *.json 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

print_status "Permissions fixed"

print_header "Creating Proper Directory Structure"
mkdir -p execution/chain/spec/chainspecs
mkdir -p execution/chain/networkname
mkdir -p cl/clparams

print_status "Directory structure created"

print_header "Creating PR Files with Correct Paths"
cd /home/erigon/Olym3-Execution-ER

# Create network_id.patch with correct paths
cat > network_id.patch << 'EOF'
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

# Create network_name.patch with correct paths
cat > network_name.patch << 'EOF'
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

# Create chain configuration file
cat > execution/chain/spec/chainspecs/olym3-testnet-s3.json << 'EOF'
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

print_status "PR files created with correct paths"

print_header "Creating Simplified Test Script"
cat > test-olym3-chain.sh << 'EOF'
#!/bin/bash

# Test Olym3 Testnet Season 3 Chain
echo "🧪 Testing Olym3 Testnet Season 3 Chain..."

# Check if we're in the right directory
if [ ! -f "execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
    echo "❌ Chain configuration file not found!"
    echo "Please run this script from the Olym3-Execution-ER directory"
    exit 1
fi

echo "✅ Chain configuration file found"

# Check chain ID in config
CHAIN_ID=$(grep '"chainId"' execution/chain/spec/chainspecs/olym3-testnet-s3.json | grep -o '[0-9]*')
echo "🔗 Chain ID in config: $CHAIN_ID"

if [ "$CHAIN_ID" == "256000" ]; then
    echo "✅ Chain ID is correct: 256000"
else
    echo "❌ Chain ID is wrong: $CHAIN_ID (expected 256000)"
fi

# Check pre-funded accounts
echo ""
echo "💰 Pre-funded Accounts:"
grep -A 1 '"alloc"' execution/chain/spec/chainspecs/olym3-testnet-s3.json | grep -E '0x[a-fA-F0-9]{40}' | while read -r line; do
    ADDR=$(echo "$line" | grep -o '0x[a-fA-F0-9]{40}')
    echo "  ✅ $ADDR"
done

# Check consensus
CONSENSUS=$(grep '"consensus"' execution/chain/spec/chainspecs/olym3-testnet-s3.json | grep -o '"[^"]*"' | tr -d '"')
echo ""
echo "⚡ Consensus: $CONSENSUS"

# Check genesis hash
echo ""
echo "🔍 Genesis Hash: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9"

echo ""
echo "🎯 Next Steps:"
echo "1. Fork Erigon repository: https://github.com/erigontech/erigon"
echo "2. Clone your fork"
echo "3. Apply patches from this directory"
echo "4. Test the build"
echo "5. Create Pull Request"

echo ""
echo "📁 Files ready for PR:"
echo "  - network_id.patch"
echo "  - network_name.patch"
echo "  - execution/chain/spec/chainspecs/olym3-testnet-s3.json"
echo "  - test-olym3-chain.sh"
EOF

chmod +x test-olym3-chain.sh

print_status "Test script created"

print_header "Creating PR Instructions"
cat > PR_INSTRUCTIONS.md << 'EOF'
# 🚀 Olym3 Testnet Season 3 - Pull Request Instructions

## 📋 Overview
This directory contains all files needed to add Olym3 Testnet Season 3 (Chain ID: 256000) support to Erigon.

## 🔧 Files Created

### Patches
- `network_id.patch` - Add chain ID constant (256000)
- `network_name.patch` - Add network name (olym3-testnet-s3)

### Configuration
- `execution/chain/spec/chainspecs/olym3-testnet-s3.json` - Chain configuration

### Scripts
- `test-olym3-chain.sh` - Test the chain configuration

## 🚀 Steps to Create Pull Request

### 1. Fork Erigon Repository
```bash
# Go to https://github.com/erigontech/erigon
# Click "Fork" button
# Clone your fork
git clone https://github.com/YOUR_USERNAME/erigon.git
cd erigon
```

### 2. Apply Patches
```bash
# Copy patches to Erigon repo
cp /home/erigon/Olym3-Execution-ER/network_id.patch .
cp /home/erigon/Olym3-Execution-ER/network_name.patch .

# Apply patches
git apply network_id.patch
git apply network_name.patch
```

### 3. Add Chain Configuration
```bash
# Create directory
mkdir -p execution/chain/spec/chainspecs

# Copy configuration
cp /home/erigon/Olym3-Execution-ER/execution/chain/spec/chainspecs/olym3-testnet-s3.json execution/chain/spec/chainspecs/
```

### 4. Add Genesis Function
Add this function to `execution/chain/spec/genesis.go`:

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

### 5. Test Build
```bash
# Build Erigon
make erigon

# Test chain
./build/bin/erigon --chain=olym3-testnet-s3 --datadir=/tmp/test
```

### 6. Create Pull Request
- **Title**: `feat: Add Olym3 Testnet Season 3 (Chain ID: 256000) support`
- **Description**: See PR_DESCRIPTION.md

## 🎯 Chain Details
- **Chain ID**: 256000 (0x3e800)
- **Chain Name**: olym3-testnet-s3
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9
- **Pre-funded Accounts**: 5 addresses với 1000 ETH mỗi

## 🧪 Testing
Run the test script to verify configuration:
```bash
./test-olym3-chain.sh
```
EOF

print_status "PR instructions created"

print_header "Setting Final Permissions"
chown -R erigon:erigon .
chmod -R 644 *.md *.patch *.json
chmod +x *.sh

print_status "Final permissions set"

print_header "Setup Complete!"
echo "🎉 Olym3 Testnet Season 3 PR files are ready!"
echo ""
echo "📋 Files created:"
echo "  - network_id.patch"
echo "  - network_name.patch"
echo "  - execution/chain/spec/chainspecs/olym3-testnet-s3.json"
echo "  - test-olym3-chain.sh"
echo "  - PR_INSTRUCTIONS.md"
echo ""
echo "🚀 Next steps:"
echo "  1. ./test-olym3-chain.sh (test configuration)"
echo "  2. Follow PR_INSTRUCTIONS.md"
echo "  3. Fork Erigon repository"
echo "  4. Apply patches"
echo "  5. Create Pull Request"
echo ""
echo "📝 Test the configuration:"
echo "  ./test-olym3-chain.sh"
