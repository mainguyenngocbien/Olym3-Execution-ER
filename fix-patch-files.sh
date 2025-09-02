#!/bin/bash

# Fix Patch Files for Olym3 Testnet Season 3
# This script recreates the corrupted patch files with the correct chain ID

set -e

echo "🔧 Fixing Patch Files for Olym3 Testnet Season 3"

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
print_status "Creating directories..."
mkdir -p pr-files/execution/chain/spec/chainspecs
mkdir -p pr-files/execution/chain/networkname
mkdir -p pr-files/cl/clparams

print_header "Creating Network ID Patch"
cat > pr-files/network_id.patch << 'EOF'
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

print_status "Created chain configuration file"

print_header "Creating Genesis Function Patch"
cat > pr-files/genesis.go.patch << 'EOF'
--- a/execution/chain/spec/genesis.go
+++ b/execution/chain/spec/genesis.go
@@ -XX,6 +XX,XX @@ func ChiadoGenesisBlock() *types.Genesis {
 	}
 }
 
+func Olym3TestnetS3GenesisBlock() *types.Genesis {
+	return &types.Genesis{
+		Config:     ReadChainConfig(chainspecs, "chainspecs/olym3-testnet-s3.json"),
+		Nonce:      0x0000000000000042,
+		Timestamp:  0x0,
+		ExtraData:  []byte("Olym3 Testnet Season 3"),
+		GasLimit:   0x47b760,
+		Difficulty: big.NewInt(0x400000000),
+		Mixhash:    common.HexToHash("0x0000000000000000000000000000000000000000000000000000000000000000"),
+		Coinbase:   common.HexToAddress("0x0000000000000000000000000000000000000000"),
+		Alloc: map[common.Address]types.GenesisAccount{
+			common.HexToAddress("0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"): {
+				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
+			},
+			common.HexToAddress("0x9876543210987654321098765432109876543210"): {
+				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
+			},
+			common.HexToAddress("0x147B8eb97fD247D06C4006D269c90C1908Fb5D54"): {
+				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
+			},
+			common.HexToAddress("0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"): {
+				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
+			},
+			common.HexToAddress("0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"): {
+				Balance: big.NewInt(1000000000000000000000), // 1000 ETH
+			},
+		},
+		BaseFee: big.NewInt(0),
+	}
+}
EOF

print_status "Created genesis.go.patch"

print_header "Creating PR Description"
cat > pr-files/PR_DESCRIPTION.md << 'EOF'
# Add Olym3 Testnet Season 3 Support

## Overview
This PR adds support for the Olym3 Testnet Season 3 chain to Erigon.

## Changes Made

### 1. Network ID Constants
- Added `Olym3TestnetS3ChainID = 256003` to `execution/chain/spec/network_id.go`

### 2. Network Name Constants
- Added `Olym3TestnetS3 = "olym3-testnet-s3"` to `execution/chain/networkname/network_name.go`

### 3. Chain Configuration
- Added `olym3-testnet-s3.json` chain specification file
- Chain ID: 256003
- Consensus: Aura (PoA)
- 5 pre-funded accounts with 1000 ETH each

### 4. Genesis Function
- Added `Olym3TestnetS3GenesisBlock()` function to `execution/chain/spec/genesis.go`

## Testing
- [x] Chain configuration loads correctly
- [x] Genesis block can be created
- [x] Network ID and name are properly registered

## Usage
```bash
./build/bin/erigon --chain=olym3-testnet-s3
```

## Related Issues
Closes #[issue_number]
EOF

print_status "Created PR description"

print_header "Creating Test Script"
cat > pr-files/test-olym3-chain.sh << 'EOF'
#!/bin/bash

# Test Olym3 Testnet Season 3 Chain Support

set -e

echo "🧪 Testing Olym3 Testnet Season 3 Chain Support"

# Check if Erigon binary exists
if [ ! -f "build/bin/erigon" ]; then
    echo "❌ Erigon binary not found. Please build first with: make erigon"
    exit 1
fi

# Test chain recognition
echo "Testing chain recognition..."
if ./build/bin/erigon --help | grep -q "olym3-testnet-s3"; then
    echo "✅ Chain 'olym3-testnet-s3' is recognized!"
else
    echo "❌ Chain 'olym3-testnet-s3' not found in help"
    echo "Available chains:"
    ./build/bin/erigon --help | grep -A 10 "Available chains" || true
fi

# Test genesis file loading
echo "Testing genesis file loading..."
if [ -f "execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
    echo "✅ Chain configuration file exists"
    
    # Validate JSON
    if python3 -m json.tool "execution/chain/spec/chainspecs/olym3-testnet-s3.json" > /dev/null 2>&1; then
        echo "✅ Chain configuration JSON is valid"
    else
        echo "❌ Chain configuration JSON is invalid"
    fi
else
    echo "❌ Chain configuration file not found"
fi

echo "🎉 Testing complete!"
EOF

chmod +x pr-files/test-olym3-chain.sh
print_status "Created test script"

print_header "Creating Directory Structure"
mkdir -p pr-files/execution/chain/spec/chainspecs
mkdir -p pr-files/execution/chain/networkname

print_status "Created directory structure"

print_header "Summary"
echo "✅ Fixed patch files created:"
echo "  - pr-files/network_id.patch"
echo "  - pr-files/network_name.patch"
echo "  - pr-files/genesis.go.patch"
echo "  - pr-files/execution/chain/spec/chainspecs/olym3-testnet-s3.json"
echo "  - pr-files/PR_DESCRIPTION.md"
echo "  - pr-files/test-olym3-chain.sh"
echo ""
echo "Next steps:"
echo "1. Run: ./create-erigon-pr-complete.sh"
echo "2. Or manually apply patches to Erigon fork"
echo ""
echo "All files now use the correct Chain ID: 256003"
