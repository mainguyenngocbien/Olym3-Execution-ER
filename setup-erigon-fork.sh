#!/bin/bash

# Olym3 Testnet Season 3 - Erigon Fork Setup Script
# This script sets up an Erigon fork with Olym3 Testnet Season 3 support

set -e

# Configuration
ERIGON_REPO="https://github.com/ledgerwatch/erigon.git"
BRANCH_NAME="olym3-testnet-s3"
OLYM3_DIR="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
    print_error "This script must be run from the Olym3-Execution-ER directory"
    print_error "Please run: cd /path/to/Olym3-Execution-ER && ./setup-erigon-fork.sh"
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

# Update main branch - handle divergence with rebase
print_status "Updating main branch..."
git checkout main

# Check if there are local changes that would conflict
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Local changes detected. Stashing changes..."
    git stash
    STASHED=true
fi

# Try to pull with rebase first, fallback to merge if needed
if ! git pull --rebase upstream main; then
    print_warning "Rebase failed, trying merge strategy..."
    if ! git pull upstream main --no-edit; then
        print_error "Failed to update main branch. Manual intervention required."
        print_error "Please resolve conflicts manually and run: git pull upstream main"
        exit 1
    fi
fi

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    print_status "Restoring stashed changes..."
    git stash pop || print_warning "Some stashed changes could not be restored"
fi

# Create feature branch
print_status "Creating feature branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Apply patches
print_status "Applying patches..."
if [ -f "../network_id.patch" ]; then
    if git apply ../network_id.patch; then
        print_status "Applied network_id.patch"
    else
        print_error "Failed to apply network_id.patch"
        exit 1
    fi
else
    print_warning "network_id.patch not found in parent directory"
fi

if [ -f "../network_name.patch" ]; then
    if git apply ../network_name.patch; then
        print_status "Applied network_name.patch"
    else
        print_error "Failed to apply network_name.patch"
        exit 1
    fi
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
