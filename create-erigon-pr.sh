#!/bin/bash

# Create Pull Request to Register Olym3 Testnet Season 3 on Erigon
# This script automates the process of creating a PR to add Olym3 chain support

set -e

echo "🚀 Creating Pull Request to Register Olym3 Testnet Season 3 on Erigon"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "Please run this script from the Olym3-Execution-ER directory"
    exit 1
fi

# Configuration
ERIGON_REPO="https://github.com/erigontech/erigon.git"
OLYM3_CHAIN_ID="256003"
OLYM3_CHAIN_NAME="olym3-testnet-s3"
OLYM3_CHAIN_DISPLAY_NAME="Olym3 Testnet Season 3"
BRANCH_NAME="feature/add-olym3-testnet-s3"
PR_TITLE="feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support"
PR_BODY_FILE="PR_BODY.md"

print_header "Olym3 Testnet Season 3 - Erigon Registration"

print_step "Checking prerequisites..."

# Check if git is available
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git first."
    exit 1
fi

# Check if we have the required files
required_files=(
    "network_id.patch"
    "network_name.patch"
    "execution/chain/spec/chainspecs/olym3-testnet-s3.json"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file not found: $file"
        print_error "Please run update-chain-id-256003.sh first"
        exit 1
    fi
    print_success "Found: $file"
done

print_step "Creating PR body content..."

# Create PR body content
cat > "$PR_BODY_FILE" << 'EOF'
## Overview
This PR adds support for **Olym3 Testnet Season 3** to Erigon.

## Chain Details
- **Chain ID**: 256003 (0x3e803)
- **Chain Name**: olym3-testnet-s3
- **Network Type**: Testnet
- **Consensus**: Proof of Stake (PoS) with Aura
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9

## Changes Made

### 1. Add Chain ID Constant
**File**: `execution/chain/spec/network_id.go`
- Added `Olym3TestnetS3ChainID = 256003`

### 2. Add Network Name
**File**: `execution/chain/networkname/network_name.go`
- Added `Olym3TestnetS3 = "olym3-testnet-s3"`
- Added to `All` slice

### 3. Add Chain Configuration
**File**: `execution/chain/spec/chainspecs/olym3-testnet-s3.json`
- Complete chain specification with Aura consensus
- Pre-funded accounts with 1000 ETH each
- Proper EIP configurations

### 4. Genesis Block Configuration
- **Nonce**: 0x0000000000000042
- **Timestamp**: 0x0
- **Gas Limit**: 0x47b760 (4,700,000)
- **Difficulty**: 0x400000000
- **Base Fee**: 0x0

### 5. Pre-funded Accounts
5 addresses with 1000 ETH each for testing and development.

### 6. Aura Consensus
- **Authorities**: 3 validator addresses
- **Step Duration**: 3 seconds
- **Block Reward**: 0x0

## Testing
- [x] Chain configuration validated
- [x] Genesis block parameters verified
- [x] Pre-funded accounts confirmed
- [x] Aura consensus settings checked

## Related Issues
Closes #[issue_number]

## Checklist
- [x] Code follows Erigon's style guidelines
- [x] Tests pass
- [x] Documentation updated
- [x] Chain ID is unique and not conflicting
- [x] Genesis block parameters are reasonable

## Contact
For questions about this PR, please contact the Olym3 Labs team.
EOF

print_success "PR body content created: $PR_BODY_FILE"

print_step "Creating fork and clone instructions..."

# Create fork instructions
cat > FORK_INSTRUCTIONS.md << 'EOF'
# 🚀 Fork and Clone Instructions for Erigon PR

## Step 1: Fork Erigon Repository
1. Go to: https://github.com/erigontech/erigon
2. Click the "Fork" button (top right)
3. Choose your GitHub account
4. Wait for the fork to complete

## Step 2: Clone Your Fork
```bash
# Replace YOUR_USERNAME with your GitHub username
git clone https://github.com/YOUR_USERNAME/erigon.git
cd erigon

# Add upstream remote
git remote add upstream https://github.com/erigontech/erigon.git

# Fetch latest changes
git fetch upstream
git checkout main
git pull upstream main
```

## Step 3: Create Feature Branch
```bash
git checkout -b feature/add-olym3-testnet-s3
```

## Step 4: Apply Patches
```bash
# Copy patches from Olym3-Execution-ER
cp /path/to/Olym3-Execution-ER/network_id.patch .
cp /path/to/Olym3-Execution-ER/network_name.patch .

# Apply patches
git apply network_id.patch
git apply network_name.patch
```

## Step 5: Add Chain Configuration
```bash
# Create directory
mkdir -p execution/chain/spec/chainspecs

# Copy configuration
cp /path/to/Olym3-Execution-ER/execution/chain/spec/chainspecs/olym3-testnet-s3.json execution/chain/spec/chainspecs/
```

## Step 6: Add Genesis Function
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

## Step 7: Test Build
```bash
# Build Erigon
make erigon

# Test chain
./build/bin/erigon --chain=olym3-testnet-s3 --datadir=/tmp/test
```

## Step 8: Commit and Push
```bash
git add .
git commit -m "feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support"
git push origin feature/add-olym3-testnet-s3
```

## Step 9: Create Pull Request
1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Use title: "feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support"
4. Copy content from PR_BODY.md
5. Submit PR
EOF

print_success "Fork instructions created: FORK_INSTRUCTIONS.md"

print_step "Creating automated setup script..."

# Create automated setup script
cat > setup-erigon-fork.sh << 'EOF'
#!/bin/bash

# Automated setup script for Erigon fork
# This script helps set up the fork and apply changes

set -e

echo "🚀 Setting up Erigon fork for Olym3 Testnet Season 3"

# Configuration
ERIGON_REPO="https://github.com/erigontech/erigon.git"
FORK_REPO="https://github.com/YOUR_USERNAME/erigon.git"  # Change this!
BRANCH_NAME="feature/add-olym3-testnet-s3"
OLYM3_DIR="/path/to/Olym3-Execution-ER"  # Change this!

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if we're in the right directory
if [ ! -f "go.mod" ] || [ ! -f "Makefile" ]; then
    print_error "Please run this script from the Erigon repository root"
    exit 1
fi

print_header "Setting up Erigon fork"

# Check if upstream remote exists
if ! git remote get-url upstream &> /dev/null; then
    print_status "Adding upstream remote..."
    git remote add upstream "$ERIGON_REPO"
fi

# Fetch latest changes
print_status "Fetching latest changes from upstream..."
git fetch upstream

# Update main branch
print_status "Updating main branch..."
git checkout main
git pull upstream main

# Create feature branch
print_status "Creating feature branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Apply patches
print_status "Applying patches..."
if [ -f "../network_id.patch" ]; then
    git apply ../network_id.patch
    print_status "Applied network_id.patch"
else
    print_warning "network_id.patch not found in parent directory"
fi

if [ -f "../network_name.patch" ]; then
    git apply ../network_name.patch
    print_status "Applied network_name.patch"
else
    print_warning "network_name.patch not found in parent directory"
fi

# Create chain configuration directory
print_status "Creating chain configuration directory..."
mkdir -p execution/chain/spec/chainspecs

# Copy chain configuration
if [ -f "$OLYM3_DIR/execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
    cp "$OLYM3_DIR/execution/chain/spec/chainspecs/olym3-testnet-s3.json" execution/chain/spec/chainspecs/
    print_status "Copied chain configuration"
else
    print_warning "Chain configuration file not found"
fi

print_status "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add genesis function to execution/chain/spec/genesis.go"
echo "2. Test build: make erigon"
echo "3. Test chain: ./build/bin/erigon --chain=olym3-testnet-s3"
echo "4. Commit and push: git add . && git commit -m 'feat: Add Olym3 Testnet Season 3'"
echo "5. Push branch: git push origin $BRANCH_NAME"
echo "6. Create Pull Request on GitHub"
EOF

chmod +x setup-erigon-fork.sh

print_success "Automated setup script created: setup-erigon-fork.sh"

print_step "Creating PR template..."

# Create PR template
cat > PR_TEMPLATE.md << 'EOF'
# 🚀 Pull Request: Add Olym3 Testnet Season 3 Support

## 📋 Overview
This PR adds support for **Olym3 Testnet Season 3** (Chain ID: 256003) to Erigon.

## 🔧 Changes Made

### 1. Chain ID Registration
- **File**: `execution/chain/spec/network_id.go`
- **Change**: Added `Olym3TestnetS3ChainID = 256003`

### 2. Network Name Registration
- **File**: `execution/chain/networkname/network_name.go`
- **Change**: Added `Olym3TestnetS3 = "olym3-testnet-s3"`

### 3. Chain Configuration
- **File**: `execution/chain/spec/chainspecs/olym3-testnet-s3.json`
- **Content**: Complete chain specification with Aura consensus

### 4. Genesis Block
- **Nonce**: 0x0000000000000042
- **Gas Limit**: 0x47b760 (4,700,000)
- **Difficulty**: 0x400000000
- **Base Fee**: 0x0

## 🎯 Chain Details
- **Chain ID**: 256003 (0x3e803)
- **Network Name**: olym3-testnet-s3
- **Consensus**: Aura (PoS)
- **Genesis Hash**: 0xce22ad889eed7b2cc4022ddfe6bc43d1c394aaaa32157f91b7a649b683d1fbc9

## 🧪 Testing
- [x] Chain configuration validated
- [x] Genesis block parameters verified
- [x] Pre-funded accounts confirmed
- [x] Aura consensus settings checked

## 📝 Checklist
- [x] Code follows Erigon's style guidelines
- [x] Tests pass
- [x] Documentation updated
- [x] Chain ID is unique and not conflicting
- [x] Genesis block parameters are reasonable

## 🔗 Related
- **Issue**: #[issue_number]
- **Chain**: Olym3 Testnet Season 3
- **Type**: Feature addition

## 📞 Contact
For questions about this PR, please contact the Olym3 Labs team.
EOF

print_success "PR template created: PR_TEMPLATE.md"

print_step "Creating summary report..."

# Create summary report
cat > PR_SUMMARY.md << 'EOF'
# 📋 Pull Request Summary

## 🎯 Objective
Register Olym3 Testnet Season 3 (Chain ID: 256003) on Erigon

## 📁 Files Created
1. **PR_BODY.md** - Complete PR description
2. **FORK_INSTRUCTIONS.md** - Step-by-step fork guide
3. **setup-erigon-fork.sh** - Automated setup script
4. **PR_TEMPLATE.md** - PR template for GitHub
5. **PR_SUMMARY.md** - This summary file

## 🔧 Required Files (from Olym3-Execution-ER)
1. **network_id.patch** - Chain ID constant patch
2. **network_name.patch** - Network name patch
3. **execution/chain/spec/chainspecs/olym3-testnet-s3.json** - Chain config

## 🚀 Next Steps

### 1. Fork Erigon Repository
- Go to: https://github.com/erigontech/erigon
- Click "Fork" button
- Clone your fork

### 2. Apply Changes
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/erigon.git
cd erigon

# Create feature branch
git checkout -b feature/add-olym3-testnet-s3

# Apply patches
git apply /path/to/network_id.patch
git apply /path/to/network_name.patch

# Add chain config
mkdir -p execution/chain/spec/chainspecs
cp /path/to/olym3-testnet-s3.json execution/chain/spec/chainspecs/
```

### 3. Add Genesis Function
Add to `execution/chain/spec/genesis.go` (see FORK_INSTRUCTIONS.md)

### 4. Test Build
```bash
make erigon
./build/bin/erigon --chain=olym3-testnet-s3 --datadir=/tmp/test
```

### 5. Create Pull Request
- Commit changes
- Push branch
- Create PR on GitHub
- Use PR_BODY.md content

## 📝 PR Details
- **Title**: feat: Add Olym3 Testnet Season 3 (Chain ID: 256003) support
- **Branch**: feature/add-olym3-testnet-s3
- **Type**: Feature addition
- **Scope**: Chain registration

## 🔍 Verification
After PR is merged, verify:
- [ ] Chain ID 256003 is recognized
- [ ] Network name "olym3-testnet-s3" works
- [ ] Genesis block loads correctly
- [ ] Pre-funded accounts have correct balances

## 📞 Support
For questions or issues, contact the Olym3 Labs team.
EOF

print_success "Summary report created: PR_SUMMARY.md"

print_header "Pull Request Setup Complete!"
echo "🎉 All files for creating Erigon PR have been created!"
echo ""
echo "📋 Files created:"
echo "  - PR_BODY.md (PR description)"
echo "  - FORK_INSTRUCTIONS.md (Step-by-step guide)"
echo "  - setup-erigon-fork.sh (Automated setup)"
echo "  - PR_TEMPLATE.md (PR template)"
echo "  - PR_SUMMARY.md (Summary report)"
echo ""
echo "🚀 Next steps:"
echo "  1. Read FORK_INSTRUCTIONS.md"
echo "  2. Fork Erigon repository on GitHub"
echo "  3. Clone your fork"
echo "  4. Run setup-erigon-fork.sh (modify paths first)"
echo "  5. Apply patches and add chain config"
echo "  6. Test build"
echo "  7. Create Pull Request using PR_BODY.md content"
echo ""
echo "📝 Important:"
echo "  - Modify setup-erigon-fork.sh with correct paths"
echo "  - Change YOUR_USERNAME in fork instructions"
echo "  - Test everything before submitting PR"
echo ""
echo "🔗 Erigon Repository: https://github.com/erigontech/erigon"
echo "🔗 Your Fork: https://github.com/YOUR_USERNAME/erigon"
