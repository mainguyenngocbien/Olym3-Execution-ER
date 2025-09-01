#!/bin/bash

# Olym3 Testnet Season 3 - Complete Setup Script
# Author: Olym3 Labs DevOps Team

set -e

echo "🚀 Olym3 Testnet Season 3 - Complete Setup & Verification"

# Colors for output
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

print_header "Checking Current Status"

# Check if Erigon is running
if systemctl is-active --quiet erigon; then
    print_status "✓ Erigon service is running"
else
    print_error "✗ Erigon service is not running"
    exit 1
fi

# Check ports
print_header "Port Status"
if netstat -tlnp 2>/dev/null | grep -q ":30303"; then
    echo "✓ P2P (30303): Listening"
else
    echo "✗ P2P (30303): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8545"; then
    echo "✓ HTTP RPC (8545): Listening"
else
    echo "✗ HTTP RPC (8545): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8546"; then
    echo "✓ WebSocket (8546): Listening"
else
    echo "✗ WebSocket (8546): Not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":8551"; then
    echo "✓ Engine API (8551): Listening"
else
    echo "✗ Engine API (8551): Not listening"
fi

# Test APIs
print_header "API Tests"

# Test web3_clientVersion
echo "Testing web3_clientVersion..."
CLIENT_VERSION=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CLIENT_VERSION" != "Failed" ]]; then
    echo "✓ Client Version: $CLIENT_VERSION"
else
    echo "✗ Failed to get client version"
fi

# Test chain ID
echo "Testing eth_chainId..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CHAIN_ID" != "Failed" ]]; then
    echo "✓ Chain ID: $CHAIN_ID"
    # Convert hex to decimal
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo "  Decimal: $CHAIN_ID_DEC"
    
    if [[ "$CHAIN_ID_DEC" == "256003" ]]; then
        echo "✓ Chain ID is correct (256003)"
    else
        echo "✗ Chain ID should be 256003, but got $CHAIN_ID_DEC"
    fi
else
    echo "✗ Failed to get chain ID"
fi

# Test block number
echo "Testing eth_blockNumber..."
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$BLOCK_NUMBER" != "Failed" ]]; then
    BLOCK_NUMBER_DEC=$(printf "%d" "$BLOCK_NUMBER")
    echo "✓ Block Number: $BLOCK_NUMBER_DEC"
else
    echo "✗ Failed to get block number"
fi

# Test accounts
echo "Testing eth_accounts..."
ACCOUNTS=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result[]' 2>/dev/null || echo "Failed")

if [[ "$ACCOUNTS" != "Failed" ]]; then
    echo "✓ Available accounts:"
    echo "$ACCOUNTS" | while read -r account; do
        if [[ -n "$account" ]]; then
            echo "  $account"
        fi
    done
else
    echo "✗ Failed to get accounts"
fi

# Check genesis file
print_header "Genesis File Check"
if [[ -f "/root/genesis.json" ]]; then
    echo "✓ Genesis file exists: /root/genesis.json"
    
    # Check chain ID in genesis
    GENESIS_CHAIN_ID=$(jq -r '.config.chainId' /root/genesis.json 2>/dev/null || echo "Failed")
    if [[ "$GENESIS_CHAIN_ID" != "Failed" ]]; then
        echo "✓ Genesis Chain ID: $GENESIS_CHAIN_ID"
    else
        echo "✗ Failed to read chain ID from genesis"
    fi
    
    # Check pre-funded addresses
    echo "✓ Pre-funded addresses:"
    jq -r '.alloc | keys[]' /root/genesis.json 2>/dev/null | while read -r addr; do
        if [[ -n "$addr" ]]; then
            balance=$(jq -r ".alloc[\"$addr\"].balance" /root/genesis.json 2>/dev/null)
            balance_eth=$(echo "scale=18; $balance / 10^18" | bc -l 2>/dev/null || echo "Unknown")
            echo "  $addr: $balance_eth ETH"
        fi
    done
else
    echo "✗ Genesis file not found"
fi

# Check data directory
print_header "Data Directory Check"
if [[ -d "/root/erigon_data" ]]; then
    echo "✓ Data directory exists: /root/erigon_data"
    echo "  Size: $(du -sh /root/erigon_data 2>/dev/null | cut -f1)"
    echo "  Contents:"
    ls -la /root/erigon_data/ | head -10
else
    echo "✗ Data directory not found"
fi

# Check JWT file
print_header "JWT Secret Check"
if [[ -f "/root/jwt.hex" ]]; then
    echo "✓ JWT secret exists: /root/jwt.hex"
    echo "  Permissions: $(ls -la /root/jwt.hex | awk '{print $1}')"
else
    echo "✗ JWT secret not found"
fi

# Service status
print_header "Service Status"
systemctl status erigon --no-pager -l

# Recent logs
print_header "Recent Logs (last 10 lines)"
journalctl -u erigon -n 10 --no-pager

# Create summary
print_header "Configuration Summary"
cat > /root/olym3-summary.txt << EOF
=== Olym3 Testnet Season 3 Configuration Summary ===

Chain Configuration:
- Chain ID: 256003 (Expected: 256003)
- Chain Name: olym3-testnet-s3
- Genesis File: /root/genesis.json
- Data Directory: /root/erigon_data
- JWT Secret: /root/jwt.hex

Network Ports:
- P2P: 30303
- HTTP RPC: 8545
- WebSocket: 8546
- Engine API: 8551
- Metrics: 6060

API Endpoints:
- HTTP RPC: http://$(hostname -I | awk '{print $1}'):8545
- WebSocket: ws://$(hostname -I | awk '{print $1}'):8546
- Engine API: http://$(hostname -I | awk '{print $1}'):8551

Service Management:
- Start: systemctl start erigon
- Stop: systemctl stop erigon
- Restart: systemctl restart erigon
- Status: systemctl status erigon
- Logs: journalctl -u erigon -f

Test Commands:
- Client Version: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' http://localhost:8545
- Chain ID: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545
- Block Number: curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545

Generated: $(date)
EOF

echo "✓ Configuration summary saved to: /root/olym3-summary.txt"

print_header "Setup Complete!"
echo "🎉 Olym3 Testnet Season 3 Erigon node is running!"
echo "📋 Check /root/olym3-summary.txt for complete configuration details"
echo ""
echo "Quick Commands:"
echo "  Status: systemctl status erigon"
echo "  Logs:   journalctl -u erigon -f"
echo "  Stop:   systemctl stop erigon"
echo "  Start:  systemctl start erigon"
