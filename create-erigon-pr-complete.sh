#!/bin/bash

# Complete Olym3 Testnet Season 3 PR Creation Script
# This script handles the entire process from Git setup to PR preparation

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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if we're in the right directory
    if [ ! -f "execution/chain/spec/chainspecs/olym3-testnet-s3.json" ]; then
        print_error "This script must be run from the Olym3-Execution-ER directory"
        print_error "Please run: cd /path/to/Olym3-Execution-ER && ./create-erigon-pr-complete.sh"
        exit 1
    fi
    
    # Check if we have the required files
    if [ ! -f "pr-files/network_id.patch" ] || [ ! -f "pr-files/network_name.patch" ]; then
        print_error "Required patch files not found in pr-files/ directory"
        print_error "Please run: ./fix-permissions-and-structure.sh first"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Setup Erigon fork
setup_erigon_fork() {
    print_header "Setting up Erigon Fork"
    
    # Create temporary directory for Erigon
    TEMP_DIR="/tmp/erigon-fork-$$"
    print_status "Creating temporary directory: $TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Clone Erigon
    print_status "Cloning Erigon repository..."
    git clone "$ERIGON_REPO" erigon
    cd erigon
    
    # Add upstream remote if not exists
    if ! git remote get-url upstream &> /dev/null; then
        print_status "Adding upstream remote..."
        git remote add upstream "$ERIGON_REPO"
    fi
    
    # Fetch latest changes
    print_status "Fetching latest changes from upstream..."
    git fetch upstream
    
    # Create feature branch
    print_status "Creating feature branch: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"
    
    # Apply patches
    print_status "Applying patches..."
    if git apply "$OLYM3_DIR/pr-files/network_id.patch"; then
        print_status "Applied network_id.patch"
    else
        print_error "Failed to apply network_id.patch"
        exit 1
    fi
    
    if git apply "$OLYM3_DIR/pr-files/network_name.patch"; then
        print_status "Applied network_name.patch"
    else
        print_error "Failed to apply network_name.patch"
        exit 1
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
    
    # Add genesis function to genesis.go
    print_status "Adding genesis function to genesis.go..."
    if [ -f "$OLYM3_DIR/pr-files/genesis.go.patch" ]; then
        if git apply "$OLYM3_DIR/pr-files/genesis.go.patch"; then
            print_status "Applied genesis.go.patch"
        else
            print_warning "Failed to apply genesis.go.patch - you may need to add this manually"
        fi
    else
        print_warning "genesis.go.patch not found - you may need to add the genesis function manually"
    fi
    
    print_status "Erigon fork setup complete!"
    
    # Return to original directory
    cd "$OLYM3_DIR"
}

# Test the build
test_build() {
    print_header "Testing Build"
    
    cd "$TEMP_DIR/erigon"
    
    print_status "Testing build with: make erigon"
    if make erigon; then
        print_status "Build successful!"
        
        # Test the binary
        print_status "Testing binary..."
        if [ -f "build/bin/erigon" ]; then
            print_status "Binary created successfully!"
            
            # Test chain recognition
            print_status "Testing chain recognition..."
            if ./build/bin/erigon --help | grep -q "olym3-testnet-s3"; then
                print_status "Chain 'olym3-testnet-s3' is recognized!"
            else
                print_warning "Chain 'olym3-testnet-s3' not found in help - check implementation"
            fi
        else
            print_error "Binary not found after build"
            exit 1
        fi
    else
        print_error "Build failed!"
        print_status "You may need to fix compilation issues before proceeding"
        exit 1
    fi
    
    cd "$OLYM3_DIR"
}

# Prepare commit and push
prepare_commit() {
    print_header "Preparing Commit and Push"
    
    cd "$TEMP_DIR/erigon"
    
    # Add all changes
    print_status "Adding changes..."
    git add .
    
    # Commit
    print_status "Creating commit..."
    git commit -m "feat: Add Olym3 Testnet Season 3

- Add network ID 256003
- Add network name 'olym3-testnet-s3'
- Add chain configuration
- Add genesis function
- Support for Olym3 Testnet Season 3 chain"
    
    print_status "Commit created successfully!"
    
    # Instructions for pushing
    echo ""
    print_status "Next steps to complete the PR:"
    echo "1. Add your GitHub remote:"
    echo "   cd $TEMP_DIR/erigon"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/erigon.git"
    echo ""
    echo "2. Push the branch:"
    echo "   git push origin $BRANCH_NAME"
    echo ""
    echo "3. Create Pull Request on GitHub:"
    echo "   - Go to: https://github.com/ledgerwatch/erigon"
    echo "   - Click 'Compare & pull request' for your branch"
    echo "   - Use the PR description from: $OLYM3_DIR/pr-files/PR_DESCRIPTION.md"
    echo ""
    echo "4. Clean up temporary files:"
    echo "   rm -rf $TEMP_DIR"
    
    cd "$OLYM3_DIR"
}

# Main execution
main() {
    print_header "Olym3 Testnet Season 3 - Complete PR Creation"
    
    check_prerequisites
    setup_erigon_fork
    test_build
    prepare_commit
    
    print_status "PR creation process complete!"
    print_status "Your Erigon fork is ready at: $TEMP_DIR/erigon"
}

# Run main function
main "$@"
