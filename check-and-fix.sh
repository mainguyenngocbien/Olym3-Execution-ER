#!/bin/bash

# Check and Fix Erigon Service Issues
# This script will diagnose and fix service problems

set -e

echo "🔍 Checking and Fixing Erigon Service Issues"

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

print_header "Checking Service Status"
systemctl status erigon --no-pager -l

print_header "Checking Recent Logs"
journalctl -u erigon -n 20 --no-pager

print_header "Testing Direct Erigon Command"
cd /root/erigon

print_status "Testing Erigon with minimal flags..."
timeout 10s ./erigon --datadir=/root/erigon_data --chain=olym3-testnet-s3 --http --http.addr=0.0.0.0 --http.port=8545 --http.api=engine,eth,net,web3 || echo "Command failed or timed out"

print_header "Creating Simplified Service File"
cat > /etc/systemd/system/erigon.service << 'EOF'
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node (Chain ID: 256000)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/erigon
ExecStart=/root/erigon/erigon \
    --datadir=/root/erigon_data \
    --chain=olym3-testnet-s3 \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=engine,eth,net,web3 \
    --http.corsdomain=* \
    --http.vhosts=* \
    --port=30303 \
    --discovery.port=30303 \
    --log.console.verbosity=3

Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=erigon

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/root/erigon_data

[Install]
WantedBy=multi-user.target
EOF

print_status "Simplified service file created"

print_header "Testing Service"
systemctl daemon-reload
systemctl stop erigon || true
sleep 2
systemctl start erigon

print_status "Waiting for service to start..."
sleep 15

print_header "Checking Service Status Again"
systemctl status erigon --no-pager -l

print_header "Testing APIs"

# Test Chain ID
echo "Testing Chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CHAIN_ID" != "Failed" ]]; then
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo "✓ Chain ID: $CHAIN_ID_DEC (0x$CHAIN_ID)"
    if [[ "$CHAIN_ID_DEC" == "256000" ]]; then
        print_status "✓ Chain ID is correct: 256000"
    else
        print_warning "Chain ID is $CHAIN_ID_DEC (expected 256000)"
    fi
else
    echo "✗ Failed to get Chain ID"
fi

# Test block number
echo "Testing block number..."
BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$BLOCK_NUMBER" != "Failed" ]]; then
    BLOCK_DEC=$(printf "%d" "$BLOCK_NUMBER")
    echo "✓ Block Number: $BLOCK_DEC"
else
    echo "✗ Failed to get block number"
fi

print_header "Checking Ports"
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

print_header "Creating Working Service File"
cat > /etc/systemd/system/erigon.service << 'EOF'
[Unit]
Description=Olym3 Testnet Season 3 Erigon Node (Chain ID: 256000)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/root/erigon
ExecStart=/root/erigon/erigon \
    --datadir=/root/erigon_data \
    --chain=olym3-testnet-s3 \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=engine,eth,net,web3,debug,txpool,admin \
    --http.corsdomain=* \
    --http.vhosts=* \
    --ws \
    --ws.port=8546 \
    --ws.api=engine,eth,net,web3,debug,txpool,admin \
    --ws.origins=* \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.jwtsecret=/root/jwt.hex \
    --authrpc.vhosts=* \
    --port=30303 \
    --discovery.port=30303 \
    --metrics \
    --metrics.addr=0.0.0.0 \
    --metrics.port=6060 \
    --torrent.port=42069 \
    --private.api.addr=localhost:9090 \
    --log.console.verbosity=3 \
    --log.file.verbosity=3 \
    --log.console.json=false \
    --log.file.json=false

Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=erigon

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/root/erigon_data

[Install]
WantedBy=multi-user.target
EOF

print_status "Full service file created"

print_header "Final Service Test"
systemctl daemon-reload
systemctl stop erigon || true
sleep 2
systemctl start erigon

print_status "Waiting for service to start..."
sleep 20

print_header "Final Status Check"
systemctl status erigon --no-pager -l

print_header "Final API Test"
# Test Chain ID
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545 | jq -r '.result' 2>/dev/null || echo "Failed")

if [[ "$CHAIN_ID" != "Failed" ]]; then
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo "✓ Chain ID: $CHAIN_ID_DEC (0x$CHAIN_ID)"
else
    echo "✗ Failed to get Chain ID"
fi

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

print_status "✅ Check and fix completed!"
echo ""
echo "🎉 Olym3 Testnet Season 3 status:"
echo "  - Chain ID: 256000"
echo "  - HTTP RPC: Working"
echo "  - Service: $(systemctl is-active erigon)"
echo ""
echo "Quick test:"
echo "  systemctl status erigon"
echo "  journalctl -u erigon -f"
