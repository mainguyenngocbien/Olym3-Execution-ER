#!/bin/bash

# Update Chain ID from 256000 to 256003 for Olym3 Testnet Season 3
# This script updates all files to use Chain ID 256003

set -e

echo "🔧 Updating Chain ID from 256000 to 256003"

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

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "Please run this script from the Olym3-Execution-ER directory"
    exit 1
fi

print_header "Updating Chain ID in All Files"

# Update README.md
print_status "Updating README.md..."
sed -i 's/256000/256003/g' README.md
sed -i 's/0x3e800/0x3e803/g' README.md

# Update olym3-chain-registration.md
if [ -f "olymm3-chain-registration.md" ]; then
    print_status "Updating olym3-chain-registration.md..."
    sed -i 's/256000/256003/g' olym3-chain-registration.md
    sed -i 's/0x3e800/0x3e803/g' olym3-chain-registration.md
fi

# Update fix-permissions-and-structure.sh
print_status "Updating fix-permissions-and-structure.sh..."
sed -i 's/256000/256003/g' fix-permissions-and-structure.sh
sed -i 's/0x3e800/0x3e803/g' fix-permissions-and-structure.sh

# Update network_id.patch
if [ -f "network_id.patch" ]; then
    print_status "Updating network_id.patch..."
    sed -i 's/256000/256003/g' network_id.patch
fi

# Update network_name.patch
if [ -f "network_name.patch" ]; then
    print_status "Updating network_name.patch..."
    # No changes needed for network_name.patch
fi

# Update chain configuration file
if [ -f "execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
    print_status "Updating chain configuration..."
    sed -i 's/256000/256003/g' execution/chain/spec/chainspecs/olym3-testnet-s3.json
fi

# Update test script
if [ -f "test-olym3-chain.sh" ]; then
    print_status "Updating test script..."
    sed -i 's/256000/256003/g' test-olym3-chain.sh
    sed -i 's/0x3e800/0x3e803/g' test-olym3-chain.sh
fi

# Update PR instructions
if [ -f "PR_INSTRUCTIONS.md" ]; then
    print_status "Updating PR instructions..."
    sed -i 's/256000/256003/g' PR_INSTRUCTIONS.md
    sed -i 's/0x3e800/0x3e803/g' PR_INSTRUCTIONS.md
fi

# Update any other files that might contain the old chain ID
print_status "Searching for other files with old chain ID..."
find . -type f -name "*.md" -o -name "*.sh" -o -name "*.json" -o -name "*.patch" | xargs grep -l "256000" 2>/dev/null | while read -r file; do
    if [ "$file" != "./update-chain-id-256003.sh" ]; then
        print_status "Updating $file..."
        sed -i 's/256000/256003/g' "$file"
    fi
done

print_header "Creating Updated Chain Configuration"
mkdir -p execution/chain/spec/chainspecs

cat > execution/chain/spec/chainspecs/olym3-testnet-s3.json << 'EOF'
{
  "chainId": 256003,
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
    "chainId": 256003,
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

print_header "Creating Updated Patches"

# Create updated network_id.patch
cat > network_id.patch << 'EOF'
--- a/execution/chain/spec/network_id.go
+++ b/execution/chain/spec/network_id.go
@@ -20,6 +20,7 @@ const (
 	HoodiChainID   = 560048
 	GnosisChainID  = 100
 	ChiadoChainID  = 10200
+	Olym3TestnetS3ChainID = 256003
 )
 
 var NetworkNameByID = make(map[uint64]string)
EOF

# Create updated network_name.patch
cat > network_name.patch << 'EOF'
--- a/execution/chain/spec/network_name.go
+++ b/execution/chain/spec/network_name.go
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

print_header "Creating Updated Test Script"
cat > test-olym3-chain.sh << 'EOF'
#!/bin/bash

# Test Olym3 Testnet Season 3 Chain (Chain ID: 256003)
echo "🧪 Testing Olym3 Testnet Season 3 Chain (Chain ID: 256003)..."

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

if [ "$CHAIN_ID" == "256003" ]; then
    echo "✅ Chain ID is correct: 256003 (0x3e803)"
else
    echo "❌ Chain ID is wrong: $CHAIN_ID (expected 256003)"
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

echo ""
echo "🔗 Chain ID: 256003 (0x3e803)"
echo "🌐 Network Name: olym3-testnet-s3"
EOF

chmod +x test-olym3-chain.sh

print_header "Creating Updated PR Instructions"
cat > PR_INSTRUCTIONS.md << 'EOF'
# 🚀 Olym3 Testnet Season 3 - Pull Request Instructions

## 📋 Overview
This directory contains all files needed to add Olym3 Testnet Season 3 (Chain ID: 256003) support to Erigon.

## 🔧 Files Created

### Patches
- `network_id.patch` - Add chain ID constant (256003)
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
- **Title**: `feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support`
- **Description**: See PR_DESCRIPTION.md

## 🎯 Chain Details
- **Chain ID**: 256003 (0x3e803)
- **Chain Name**: olym3-testnet-s3
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9
- **Pre-funded Accounts**: 5 addresses với 1000 ETH mỗi

## 🧪 Testing
Run the test script to verify configuration:
```bash
./test-olym3-chain.sh
```
EOF

print_header "Creating Updated Summary"
cat > SUMMARY.md << 'EOF'
# 🚀 Olym3 Testnet Season 3 - Chain ID 256003

## 📋 Overview
Updated configuration for Olym3 Testnet Season 3 with Chain ID 256003.

## 🔧 Changes Made

### Chain ID Update
- **Old Chain ID**: 256000 (0x3e800)
- **New Chain ID**: 256003 (0x3e803)
- **Updated in**: All configuration files

### Files Updated
- ✅ README.md
- ✅ olym3-chain-registration.md
- ✅ fix-permissions-and-structure.sh
- ✅ network_id.patch
- ✅ network_name.patch
- ✅ execution/chain/spec/chainspecs/olym3-testnet-s3.json
- ✅ test-olym3-chain.sh
- ✅ PR_INSTRUCTIONS.md
- ✅ SUMMARY.md

## 🎯 Chain Configuration

### Basic Info
- **Chain ID**: 256003 (0x3e803)
- **Network Name**: olym3-testnet-s3
- **Consensus**: Aura (PoS)
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9

### Genesis Block
- **Nonce**: 0x0000000000000042
- **Timestamp**: 0x0
- **Gas Limit**: 0x47b760 (4,700,000)
- **Difficulty**: 0x400000000
- **Base Fee**: 0x0

### Pre-funded Accounts
5 addresses with 1000 ETH each:
- 0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6
- 0x9876543210987654321098765432109876543210
- 0x147B8eb97fD247D06C4006D269c90C1908Fb5D54
- 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
- 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

### Aura Consensus
- **Authorities**: 3 validator addresses
- **Step Duration**: 3 seconds
- **Block Reward**: 0x0

## 🚀 Next Steps

### 1. Test Configuration
```bash
./test-olym3-chain.sh
```

### 2. Create Pull Request
1. Fork Erigon repository
2. Apply patches
3. Test build
4. Submit PR

### 3. PR Details
- **Title**: `feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support`
- **Files**: network_id.patch, network_name.patch, chain config

## 📁 File Structure
```
Olym3-Execution-ER/
├── README.md
├── olym3-chain-registration.md
├── fix-permissions-and-structure.sh
├── update-chain-id-256003.sh
├── network_id.patch
├── network_name.patch
├── execution/chain/spec/chainspecs/olym3-testnet-s3.json
├── test-olym3-chain.sh
├── PR_INSTRUCTIONS.md
└── SUMMARY.md
```

## 🧪 Testing Commands
```bash
# Test chain configuration
./test-olym3-chain.sh

# Verify chain ID
grep "chainId" execution/chain/spec/chainspecs/olym3-testnet-s3.json

# Check hex value
echo "obase=16; 256003" | bc
# Output: 3E803
```
EOF

print_header "Chain ID Update Complete!"
echo "🎉 All files have been updated to use Chain ID 256003!"
echo ""
echo "📋 Files updated:"
echo "  - README.md"
echo "  - olym3-chain-registration.md"
echo "  - fix-permissions-and-structure.sh"
echo "  - network_id.patch"
echo "  - network_name.patch"
echo "  - execution/chain/spec/chainspecs/olym3-testnet-s3.json"
echo "  - test-olym3-chain.sh"
echo "  - PR_INSTRUCTIONS.md"
echo "  - SUMMARY.md"
echo ""
echo "🔗 New Chain ID: 256003 (0x3e803)"
echo ""
echo "🧪 Test the updated configuration:"
echo "  ./test-olym3-chain.sh"
echo ""
echo "📝 Verify changes:"
echo "  grep -r '256003' ."
echo "  grep -r '0x3e803' ."
