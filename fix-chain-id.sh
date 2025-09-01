#!/bin/bash

# Fix Chain ID for Olym3 Testnet Season 3
# This script will properly set the Chain ID to 256003

set -e

echo "🔧 Fixing Chain ID for Olym3 Testnet Season 3..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

print_status "Stopping Erigon service..."
systemctl stop erigon || true

print_status "Checking current Chain ID..."
CURRENT_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 2>/dev/null | jq -r '.result' || echo "Service not running")

if [[ "$CURRENT_CHAIN_ID" != "Service not running" ]]; then
    CURRENT_DEC=$(printf "%d" "$CURRENT_CHAIN_ID")
    echo "Current Chain ID: $CURRENT_DEC (0x$CURRENT_CHAIN_ID)"
else
    echo "Service not running"
fi

print_status "Checking genesis file Chain ID..."
GENESIS_CHAIN_ID=$(jq -r '.config.chainId' /root/genesis.json)
echo "Genesis Chain ID: $GENESIS_CHAIN_ID"

if [[ "$GENESIS_CHAIN_ID" != "256003" ]]; then
    print_error "Genesis file has wrong Chain ID: $GENESIS_CHAIN_ID"
    exit 1
fi

print_warning "Removing old data directory..."
rm -rf /root/erigon_data

print_status "Creating new data directory..."
mkdir -p /root/erigon_data

print_status "Re-initializing chain with correct genesis..."
cd /root/erigon
./erigon init /root/genesis.json --datadir /root/erigon_data

print_status "Starting Erigon service..."
systemctl start erigon

print_status "Waiting for service to start..."
sleep 5

print_status "Verifying Chain ID..."
for i in {1..10}; do
    NEW_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
      http://localhost:8545 2>/dev/null | jq -r '.result' || echo "Failed")
    
    if [[ "$NEW_CHAIN_ID" != "Failed" ]]; then
        NEW_DEC=$(printf "%d" "$NEW_CHAIN_ID")
        echo "New Chain ID: $NEW_DEC (0x$NEW_CHAIN_ID)"
        
        if [[ "$NEW_DEC" == "256003" ]]; then
            print_status "✓ Chain ID is now correct: 256003"
            break
        else
            print_warning "Chain ID still wrong: $NEW_DEC (expected 256003)"
            if [[ $i -eq 10 ]]; then
                print_error "Failed to set correct Chain ID after 10 attempts"
                exit 1
            fi
            sleep 2
        fi
    else
        print_warning "Service not responding, waiting..."
        sleep 3
    fi
done

print_status "Testing other APIs..."

# Test block number
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$BLOCK_NUMBER" != "Failed" ]]; then
    BLOCK_DEC=$(printf "%d" "$BLOCK_NUMBER")
    echo "✓ Block Number: $BLOCK_DEC"
else
    echo "✗ Failed to get block number"
fi

# Test client version
CLIENT_VERSION=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CLIENT_VERSION" != "Failed" ]]; then
    echo "✓ Client Version: $CLIENT_VERSION"
else
    echo "✗ Failed to get client version"
fi

print_status "Checking service status..."
systemctl status erigon --no-pager -l

print_status "✅ Chain ID fix completed!"
echo ""
echo "🎉 Olym3 Testnet Season 3 is now running with:"
echo "   - Chain ID: 256003"
echo "   - Data Directory: /root/erigon_data"
echo "   - Genesis File: /root/genesis.json"
echo "   - Service: erigon (systemctl status erigon)"
echo ""
echo "Quick test:"
echo "  curl -X POST -H \"Content-Type: application/json\" \\"
echo "    --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' \\"
echo "    http://localhost:8545"
